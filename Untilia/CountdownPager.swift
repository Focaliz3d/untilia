import SwiftUI
import UIKit

/// Native horizontal paging with full-screen page bounds and no automatic insets.
struct CountdownPager<Page: View>: UIViewControllerRepresentable {
    @Binding var selectedIndex: Int
    let pageCount: Int
    var onVisibleIndexChanged: (Int?) -> Void = { _ in }
    let page: (Int, Bool) -> Page

    func makeUIViewController(context: Context) -> CountdownPagingController<Page> {
        CountdownPagingController()
    }

    func updateUIViewController(_ controller: CountdownPagingController<Page>, context: Context) {
        controller.onSelectionChanged = { selectedIndex = $0 }
        controller.onVisibleIndexChanged = onVisibleIndexChanged
        controller.update(pageCount: pageCount, selection: selectedIndex, page: page)
    }
}

final class CountdownPagingController<Page: View>: UIViewController, UIScrollViewDelegate {
    var onSelectionChanged: ((Int) -> Void)?
    var onVisibleIndexChanged: ((Int?) -> Void)?
    private let scrollView = UIScrollView()
    private var hosts: [UIHostingController<Page>] = []
    private var selectedIndex = 0
    private var pageCount = 0
    private var layoutSize = CGSize.zero
    private var isPagingGesture = false
    private var visibleIndex = 0

    private var selectedSlot: Int { selectedIndex + (pageCount > 1 ? 1 : 0) }

    override func loadView() {
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        scrollView.isDirectionalLockEnabled = true
        scrollView.delaysContentTouches = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delegate = self
        scrollView.backgroundColor = UIColor(Color.untiliaInk)
        view = scrollView
    }

    func update(pageCount: Int, selection: Int, page: (Int, Bool) -> Page) {
        loadViewIfNeeded()
        let count = max(pageCount, 0)
        let nextIndex = min(max(selection, 0), max(count - 1, 0))
        let selectionChanged = selectedIndex != nextIndex
        if selectionChanged { isPagingGesture = false }
        self.pageCount = count
        selectedIndex = nextIndex
        // Static boundary copies make the seam continuous without extra ticking timelines.
        let indices = count > 1 ? [count - 1] + Array(0..<count) + [0] : Array(0..<count)
        let pages = indices.enumerated().map { slot, index in
            page(index, slot == selectedSlot)
        }
        if hosts.count != pages.count {
            for host in hosts {
                host.willMove(toParent: nil)
                host.view.removeFromSuperview()
                host.removeFromParent()
            }
            hosts = pages.map { page in
                let host = UIHostingController(rootView: page)
                host.safeAreaRegions = []
                host.view.backgroundColor = .clear
                host.view.clipsToBounds = true
                addChild(host)
                scrollView.addSubview(host.view)
                host.didMove(toParent: self)
                return host
            }
            layoutSize = .zero
        } else {
            for (host, page) in zip(hosts, pages) {
                host.rootView = page
            }
        }

        updateAccessibility()
        layoutPages()
        if selectionChanged {
            // A card tap is a direct jump; swipes are animated by UIScrollView.
            scrollView.setContentOffset(CGPoint(x: CGFloat(selectedSlot) * layoutSize.width, y: 0), animated: false)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutPages()
    }

    private func layoutPages() {
        let size = view.bounds.size
        guard size.width > 0, size.height > 0 else { return }
        let sizeChanged = layoutSize != size
        layoutSize = size
        for (index, host) in hosts.enumerated() {
            host.view.frame = CGRect(x: CGFloat(index) * size.width, y: 0, width: size.width, height: size.height)
        }
        scrollView.contentSize = CGSize(width: size.width * CGFloat(hosts.count), height: size.height)
        if sizeChanged {
            scrollView.setContentOffset(CGPoint(x: CGFloat(selectedSlot) * size.width, y: 0), animated: false)
        }
    }

    private func updateAccessibility() {
        for (index, host) in hosts.enumerated() {
            host.view.accessibilityElementsHidden = index != selectedSlot
            host.view.isUserInteractionEnabled = index == selectedSlot
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        finishPaging()
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isPagingGesture = true
        visibleIndex = selectedIndex
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard isPagingGesture, let index = indexAtCurrentOffset(), index != visibleIndex else { return }
        visibleIndex = index
        // Publish only a crossed page boundary, never per-frame offsets or a saved selection.
        onVisibleIndexChanged?(index)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { finishPaging() }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        finishPaging()
    }

    private func indexAtCurrentOffset() -> Int? {
        guard layoutSize.width > 0, !hosts.isEmpty else { return nil }
        let slot = min(max(Int((scrollView.contentOffset.x / layoutSize.width).rounded()), 0), hosts.count - 1)
        return pageCount > 1 ? (slot + pageCount - 1) % pageCount : 0
    }

    private func finishPaging() {
        guard let index = indexAtCurrentOffset() else { return }
        let changed = index != selectedIndex
        let wasPaging = isPagingGesture
        isPagingGesture = false
        selectedIndex = index
        // Recenter on the identical real page before publishing selection; no animation.
        scrollView.setContentOffset(CGPoint(x: CGFloat(selectedSlot) * layoutSize.width, y: 0), animated: false)
        updateAccessibility()
        if changed { onSelectionChanged?(index) }
        if wasPaging { onVisibleIndexChanged?(nil) }
    }
}
