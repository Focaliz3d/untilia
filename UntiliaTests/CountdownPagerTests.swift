import SwiftUI
import Testing
import UIKit
@testable import Untilia

@MainActor
struct CountdownPagerTests {
    private let pages: [Color] = [.purple, .green, .orange]

    private func makeController(selection: Int) -> CountdownPagingController<Color> {
        let controller = CountdownPagingController<Color>()
        controller.loadViewIfNeeded()
        controller.view.frame = CGRect(x: 0, y: 0, width: 430, height: 932)
        controller.update(pageCount: pages.count, selection: selection) { index, _ in pages[index] }
        controller.viewDidLayoutSubviews()
        return controller
    }

    @Test func pagesCoverTheWholeScreenWithoutSafeAreaInsetsOrVerticalScrolling() throws {
        let controller = makeController(selection: 1)
        let scrollView = try #require(controller.view as? UIScrollView)
        #expect(scrollView.contentInsetAdjustmentBehavior == .never)
        #expect(scrollView.contentInset == .zero)
        #expect(scrollView.contentSize == CGSize(width: 2_150, height: 932))
        #expect(scrollView.contentOffset == CGPoint(x: 860, y: 0))
        #expect(!scrollView.alwaysBounceVertical)
        for (index, child) in controller.children.enumerated() {
            #expect(child.view.frame == CGRect(x: CGFloat(index) * 430, y: 0, width: 430, height: 932))
            let host = try #require(child as? UIHostingController<Color>)
            #expect(host.safeAreaRegions.isEmpty)
            #expect(host.view.accessibilityElementsHidden == (index != 2))
        }
    }

    @Test func rotationKeepsFullScreenBoundsAndCardTapsJumpDirectly() throws {
        let controller = makeController(selection: 1)
        let scrollView = try #require(controller.view as? UIScrollView)
        controller.update(pageCount: pages.count, selection: 2) { index, _ in pages[index] }
        #expect(scrollView.contentOffset == CGPoint(x: 1_290, y: 0))

        controller.view.frame = CGRect(x: 0, y: 0, width: 932, height: 430)
        controller.viewDidLayoutSubviews()
        #expect(scrollView.contentOffset == CGPoint(x: 2_796, y: 0))
        #expect(scrollView.contentSize == CGSize(width: 4_660, height: 430))
        for (index, child) in controller.children.enumerated() {
            #expect(child.view.frame == CGRect(x: CGFloat(index) * 932, y: 0, width: 932, height: 430))
        }
    }

    @Test func completedSwipesAndAccessibilityScrollingUpdateTheSelectedPage() throws {
        let controller = makeController(selection: 0)
        let scrollView = try #require(controller.view as? UIScrollView)
        var selections: [Int] = []
        controller.onSelectionChanged = { selections.append($0) }

        scrollView.contentOffset = CGPoint(x: 860, y: 0)
        controller.scrollViewDidEndDragging(scrollView, willDecelerate: false)
        scrollView.contentOffset = CGPoint(x: 1_290, y: 0)
        controller.scrollViewDidEndDecelerating(scrollView)
        scrollView.contentOffset = CGPoint(x: 1_720, y: 0)
        controller.scrollViewDidEndScrollingAnimation(scrollView)

        #expect(selections == [1, 2, 0])
        #expect(!controller.children[0].view.isUserInteractionEnabled)
        #expect(controller.children[1].view.isUserInteractionEnabled)
        #expect(!controller.children[2].view.isUserInteractionEnabled)
    }

    @Test func bothSeamsRecenterWithoutExposingDuplicateAccessibilityElements() throws {
        let controller = makeController(selection: 0)
        let scroll = try #require(controller.view as? UIScrollView)
        var selections: [Int] = []
        controller.onSelectionChanged = { selections.append($0) }
        for _ in 0..<4 {
            scroll.contentOffset = .zero
            controller.scrollViewDidEndDecelerating(scroll)
            #expect(scroll.contentOffset.x == 1_290)
            scroll.contentOffset.x = 1_720
            controller.scrollViewDidEndDecelerating(scroll)
            #expect(scroll.contentOffset.x == 430)
        }
        #expect(selections == [2, 0, 2, 0, 2, 0, 2, 0])
        #expect(controller.children.filter { !$0.view.accessibilityElementsHidden }.count == 1)
    }

    @Test func onlyCanonicalSelectionIsLiveAndSmallPageCountsRemainValid() throws {
        let controller = makeController(selection: 0)
        var liveIndices: [Int] = []
        controller.update(pageCount: 3, selection: 2) { index, isLive in
            if isLive { liveIndices.append(index) }
            return pages[index]
        }
        #expect(liveIndices == [2])
        let scroll = try #require(controller.view as? UIScrollView)
        controller.update(pageCount: 1, selection: 4) { _, _ in .purple }
        #expect(controller.children.count == 1)
        #expect(scroll.contentOffset == .zero)
        controller.update(pageCount: 0, selection: 0) { _, _ in .clear }
        #expect(controller.children.isEmpty)
        #expect(scroll.contentSize.width == 0)
        controller.scrollViewDidEndDecelerating(scroll)
        controller.update(pageCount: 2, selection: 0) { index, _ in pages[index] }
        scroll.contentOffset = .zero
        controller.scrollViewDidEndDecelerating(scroll)
        #expect(scroll.contentOffset.x == 860)
    }

    @Test func highlightChangesAtHalfPageWithoutCommittingOrSnappingAndCanReverse() throws {
        let controller = makeController(selection: 0)
        let scroll = try #require(controller.view as? UIScrollView)
        var previews: [Int?] = []
        var selections: [Int] = []
        controller.onVisibleIndexChanged = { previews.append($0) }
        controller.onSelectionChanged = { selections.append($0) }
        controller.scrollViewWillBeginDragging(scroll)
        for fraction in [0.2, 0.49, 0.51, 0.7, 0.8, 0.49] {
            let offset = 430 * (1 + fraction)
            scroll.contentOffset.x = offset
            controller.scrollViewDidScroll(scroll)
            let offsetBeforeRefresh = scroll.contentOffset.x
            // A SwiftUI refresh of the contour must not move or commit the pager.
            controller.update(pageCount: 3, selection: 0) { index, _ in pages[index] }
            #expect(abs(scroll.contentOffset.x - offsetBeforeRefresh) < 0.001)
        }
        #expect(previews == [1, 0])
        #expect(selections.isEmpty)
        scroll.contentOffset.x = 430
        controller.scrollViewDidEndDragging(scroll, willDecelerate: false)
        #expect(previews == [1, 0, nil])
        #expect(selections.isEmpty)
    }

    @Test func earlyHighlightWrapsBothWaysAndFinalSelectionIsSavedOnlyAtRest() throws {
        for (selection, offset, expected) in [(2, 3.6 * 430, 0), (0, 0.4 * 430, 2)] {
            let controller = makeController(selection: selection)
            let scroll = try #require(controller.view as? UIScrollView)
            var previews: [Int?] = []
            var selections: [Int] = []
            controller.onVisibleIndexChanged = { previews.append($0) }
            controller.onSelectionChanged = { selections.append($0) }
            controller.scrollViewWillBeginDragging(scroll)
            scroll.contentOffset.x = offset
            controller.scrollViewDidScroll(scroll)
            #expect(previews == [expected])
            #expect(selections.isEmpty)
            controller.scrollViewDidEndDragging(scroll, willDecelerate: true)
            #expect(selections.isEmpty)
            scroll.contentOffset.x = expected == 0 ? 1_720 : 0
            controller.scrollViewDidEndDecelerating(scroll)
            #expect(selections == [expected])
            #expect(previews == [expected, nil])
        }
    }

    @Test func programmaticJumpsDoNotPublishTransientHighlights() throws {
        let controller = makeController(selection: 0)
        let scroll = try #require(controller.view as? UIScrollView)
        var previews: [Int?] = []
        controller.onVisibleIndexChanged = { previews.append($0) }
        controller.update(pageCount: 3, selection: 2) { index, _ in pages[index] }
        controller.scrollViewDidScroll(scroll)
        #expect(previews.isEmpty)
        #expect(scroll.contentOffset.x == 1_290)
    }
}
