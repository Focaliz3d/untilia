import Foundation
import Testing
@testable import Untilia

struct CountdownDisplayModeTests {
    @Test func everySavedModeIsResolvedImmediatelyWithoutAnAppearanceCallback() {
        for mode in CountdownDisplayMode.allCases {
            #expect(resolvedCountdownDisplayMode(rawValue: mode.rawValue, availableModes: CountdownDisplayMode.allCases) == mode)
        }
    }

    @Test func refreshedCanonicalAndBoundaryPagesAlwaysUseTheLatestMode() {
        var saved = [CountdownDisplayMode.minutes, .hours, .days]
        let slots = [2, 0, 1, 2, 0]
        for mode in CountdownDisplayMode.allCases {
            saved[0] = mode
            let rendered = slots.map { resolvedCountdownDisplayMode(rawValue: saved[$0].rawValue, availableModes: CountdownDisplayMode.allCases) }
            #expect(rendered[1] == mode)
            #expect(rendered[4] == mode)
            #expect(rendered[0] == .days)
            #expect(rendered[2] == .hours)
        }
    }

    @Test func shrinkingDurationsStillFallBackToTheNextSmallerAvailableUnit() {
        #expect(resolvedCountdownDisplayMode(rawValue: CountdownDisplayMode.hours.rawValue, availableModes: [.minutes, .seconds]) == .minutes)
        #expect(resolvedCountdownDisplayMode(rawValue: CountdownDisplayMode.minutes.rawValue, availableModes: [.seconds]) == .seconds)
        #expect(resolvedCountdownDisplayMode(rawValue: CountdownDisplayMode.seconds.rawValue, availableModes: [.minutes, .seconds]) == .seconds)
        #expect(resolvedCountdownDisplayMode(rawValue: -1, availableModes: [.days, .hours, .minutes, .seconds]) == .days)
        #expect(resolvedCountdownDisplayMode(rawValue: 6, availableModes: []) == nil)
    }

    @MainActor @Test func modesRemainIndependentAcrossCardsAndRelaunches() {
        let suite = "UntiliaTests.modePaging.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = UntiliaStore(defaults: defaults)
        let modes: [CountdownDisplayMode] = [.seconds, .minutes, .hours]
        for (index, mode) in modes.enumerated() {
            store.updateCountdownDisplayMode(rawValue: mode.rawValue, for: index)
        }
        for index in [0, 1, 0, 2, 0, 2, 1, 0] {
            store.selectTarget(at: index)
            #expect(resolvedCountdownDisplayMode(rawValue: store.countdownDisplayModeRawValues[index], availableModes: CountdownDisplayMode.allCases) == modes[index])
        }
        let restored = UntiliaStore(defaults: defaults)
        #expect(restored.countdownDisplayModeRawValues == modes.map(\.rawValue))
    }
}
