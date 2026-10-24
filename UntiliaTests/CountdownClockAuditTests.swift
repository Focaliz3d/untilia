import Foundation
import SwiftUI
import Testing
@testable import Untilia

@MainActor
struct CountdownClockAuditTests {
    @Test func everyTickUsesTheSameInstantForClockAndExactRemainingDuration() {
        let minute = Date(timeIntervalSince1970: 1_800_000_060)
        let target = minute.addingTimeInterval(3_600)
        for identifier in ["Europe/Paris", "America/New_York", "Asia/Kathmandu", "Pacific/Chatham"] {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(identifier: identifier)!
            for fraction in [0.001, 0.2, 0.8, 0.999] {
                let ticks = CountdownTimelineSchedule(isPaused: false)
                    .entries(from: minute.addingTimeInterval(-1 + fraction), mode: .normal)
                for (index, tick) in ticks.prefix(122).enumerated() {
                    let snapshot = CountdownEngine.snapshot(now: tick, target: target,
                        startDate: minute.addingTimeInterval(-3_600), calendar: calendar)
                    #expect(remainingSecondsTotal(for: snapshot) == Int(target.timeIntervalSince(tick).rounded(.up)))
                    #expect((0..<60).contains(snapshot.remainingMinutes))
                    #expect((0..<60).contains(snapshot.remainingSeconds))
                    if index > 0 {
                        #expect(tick.timeIntervalSince1970 == tick.timeIntervalSince1970.rounded(.down))
                        #expect(calendar.component(.second, from: tick) == (index - 1) % 60)
                    }
                }
            }
        }
    }

    @Test func exactRemainingMinuteBorrowsAtTheFirstSecondAfterTheWallClockMinute() {
        let minute = Date(timeIntervalSince1970: 1_800_000_060)
        let target = minute.addingTimeInterval(60)
        let snapshots = [-1.0, 0, 1].map { offset in
            CountdownEngine.snapshot(now: minute.addingTimeInterval(offset), target: target,
                                     startDate: minute.addingTimeInterval(-60))
        }
        // These are exact durations: 61 s, 60 s, 59 s. Moving the borrow to
        // second 00 would change the meaning or introduce a one-second error.
        #expect(snapshots.map(\.remainingMinutes) == [1, 1, 0])
        #expect(snapshots.map(\.remainingSeconds) == [1, 0, 59])
    }

    @Test func secondMinuteHourDayAndDeadlineTransitionsHaveNoMissingOrRepeatedSecond() {
        let target = Date(timeIntervalSince1970: 1_800_000_060)
        for boundary in [0, 60, 3_600, 86_400] {
            for offset in -2...2 {
                let difference = boundary + offset
                let tick = target.addingTimeInterval(TimeInterval(-difference))
                let snapshot = CountdownEngine.snapshot(now: tick, target: target,
                    startDate: target.addingTimeInterval(-172_800))
                #expect(remainingSecondsTotal(for: snapshot) == abs(difference))
                #expect(snapshot.isElapsed == (difference <= 0))
                #expect((0..<60).contains(snapshot.remainingMinutes))
                #expect((0..<60).contains(snapshot.remainingSeconds))
            }
        }
    }

    @Test func savedAndMigratedDeadlinesDiscardHiddenSecondsButPreserveExactStarts() {
        for identifier in ["Europe/Paris", "America/New_York", "Asia/Kathmandu"] {
            let suite = "UntiliaTests.clockAudit.\(UUID().uuidString)"
            let defaults = UserDefaults(suiteName: suite)!
            defer { defaults.removePersistentDomain(forName: suite) }
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(identifier: identifier)!
            let minute = Date(timeIntervalSince1970: 1_800_000_060)
            let dirtyTarget = minute.addingTimeInterval(3_659.8)
            let exactStart = minute.addingTimeInterval(-12.75)
            defaults.set(Array(repeating: dirtyTarget, count: 3), forKey: "daysLeft.targetDates")
            let store = UntiliaStore(defaults: defaults, calendar: calendar, now: { exactStart })
            #expect(store.targetDates.allSatisfy { $0 == minute.addingTimeInterval(3_600) })
            for index in 0..<3 {
                store.updateTarget(dirtyTarget, timeZoneIdentifier: identifier,
                                   startDate: exactStart, for: index)
            }
            let reloaded = UntiliaStore(defaults: defaults, calendar: calendar, now: { exactStart })
            #expect(reloaded.targetDates.allSatisfy { $0 == minute.addingTimeInterval(3_600) })
            #expect(reloaded.countdownStartDates.allSatisfy { $0 == exactStart })
        }
    }
}
