import Foundation
import SwiftUI
import Testing
@testable import Untilia

@MainActor
struct CountdownTimelineScheduleTests {
    @Test func activeScheduleKeepsOneSecondCadence() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let entries = Array(CountdownTimelineSchedule(isPaused: false)
            .entries(from: now, mode: .normal).prefix(3))
        #expect(entries == [now, now.addingTimeInterval(1), now.addingTimeInterval(2)])
    }

    @Test func pausedScheduleDoesNotRequestSubsequentUpdates() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let entries = Array(CountdownTimelineSchedule(isPaused: true)
            .entries(from: now, mode: .normal).prefix(3))
        #expect(entries == [now])
    }

    @Test func resumedScheduleStartsAtCurrentTimeRatherThanReplayingMissedTicks() {
        let resumedAt = Date(timeIntervalSince1970: 1_800_000_125)
        let entries = Array(CountdownTimelineSchedule(isPaused: false)
            .entries(from: resumedAt, mode: .normal).prefix(2))
        #expect(entries == [resumedAt, resumedAt.addingTimeInterval(1)])
    }

    @Test func fractionalLaunchRefreshesAtTheNextExactSystemSecond() {
        let second = Date(timeIntervalSince1970: 1_800_000_000)
        for fraction in [0.001, 0.2, 0.8, 0.999] {
            let openedAt = second.addingTimeInterval(fraction)
            let entries = Array(CountdownTimelineSchedule(isPaused: false)
                .entries(from: openedAt, mode: .normal).prefix(4))
            #expect(entries == [openedAt, second.addingTimeInterval(1),
                                second.addingTimeInterval(2), second.addingTimeInterval(3)])
        }
    }

    @Test func minuteRolloverUpdatesClockAndCountdownOnTheSameBoundary() {
        let minute = Date(timeIntervalSince1970: 1_800_000_060)
        let entries = Array(CountdownTimelineSchedule(isPaused: false)
            .entries(from: minute.addingTimeInterval(-0.2), mode: .normal).prefix(3))
        let zone = TimeZone(secondsFromGMT: 0)!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        #expect(entries[1] == minute)
        #expect(entries.map { calendar.component(.second, from: $0) } == [59, 0, 1])
        let target = minute.addingTimeInterval(60)
        let snapshots = entries.map {
            CountdownEngine.snapshot(now: $0, target: target,
                                     startDate: minute.addingTimeInterval(-60), calendar: calendar)
        }
        #expect(snapshots.map(\.remainingMinutes) == [1, 1, 0])
        #expect(snapshots.map(\.remainingSeconds) == [1, 0, 59])
        #expect(UntiliaDateFormatting.timeString(entries[1], timeZone: zone,
                    language: .english, includingSeconds: true).hasSuffix(":00"))
    }

    @Test func fractionalResumeRealignsAndPausedPagesStayIdle() {
        let resumedAt = Date(timeIntervalSince1970: 1_800_003_599.75)
        let schedule = CountdownTimelineSchedule(isPaused: false)
        let entries = Array(schedule.entries(from: resumedAt, mode: .normal).prefix(3))
        #expect(entries == [resumedAt, Date(timeIntervalSince1970: 1_800_003_600),
                            Date(timeIntervalSince1970: 1_800_003_601)])
        #expect(Array(CountdownTimelineSchedule(isPaused: true)
            .entries(from: resumedAt, mode: .normal).prefix(3)) == [resumedAt])
        // A fresh iterator starts at the supplied current time, not an old tick.
        #expect(Array(schedule.entries(from: resumedAt, mode: .normal).prefix(3)) == entries)
    }
}
