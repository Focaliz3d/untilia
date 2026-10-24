import Foundation
import Testing
@testable import Untilia

@MainActor
struct HomeClockTests {
    private let paris = TimeZone(identifier: "Europe/Paris")!
    private let newYork = TimeZone(identifier: "America/New_York")!
    private let tokyo = TimeZone(identifier: "Asia/Tokyo")!

    private func instant(in month: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar.date(from: DateComponents(year: 2026, month: month, day: 15, hour: 12))!
    }

    @Test func parisAndAmsterdamGiveOneClockReadingInSummerAndWinter() {
        let amsterdam = TimeZone(identifier: "Europe/Amsterdam")!
        for month in [1, 7] {
            let cycle = HomeClockCycle(localTimeZone: paris, deadlineTimeZone: amsterdam,
                                       startTimeZone: paris, referenceDate: instant(in: month))
            #expect(cycle.modes == [.local, .hidden])
            #expect(cycle.resolvedMode(.deadline) == .local)
            #expect(cycle.next(after: .deadline) == .hidden)
            #expect(cycle.next(after: .hidden) == .local)
        }
    }

    @Test func equivalentForeignCitiesResolveTheSavedStartPreferenceToDeadline() {
        let seoul = TimeZone(identifier: "Asia/Seoul")!
        let cycle = HomeClockCycle(localTimeZone: paris, deadlineTimeZone: tokyo,
                                   startTimeZone: seoul, referenceDate: instant(in: 7))
        #expect(cycle.modes == [.local, .deadline, .hidden])
        #expect(cycle.resolvedMode(.start) == .deadline)
        #expect(cycle.next(after: .start) == .hidden)
        #expect(cycle.timeZone(for: .start)?.identifier == tokyo.identifier)
    }

    @Test func equivalentOffsetsAreReevaluatedAtTheCurrentSeasonRatherThanTheDeadline() {
        let lima = TimeZone(identifier: "America/Lima")!
        let winter = HomeClockCycle(localTimeZone: paris, deadlineTimeZone: newYork,
                                    startTimeZone: lima, referenceDate: instant(in: 1))
        let summer = HomeClockCycle(localTimeZone: paris, deadlineTimeZone: newYork,
                                    startTimeZone: lima, referenceDate: instant(in: 7))
        #expect(winter.modes == [.local, .deadline, .hidden])
        #expect(winter.resolvedMode(.start) == .deadline)
        #expect(summer.modes == [.local, .deadline, .start, .hidden])
        #expect(summer.resolvedMode(.start) == .start)
    }

    @Test func halfHourOffsetsRemainDistinctWithoutRoundingToHours() {
        let adelaide = TimeZone(identifier: "Australia/Adelaide")!
        let darwin = TimeZone(identifier: "Australia/Darwin")!
        let cycle = HomeClockCycle(localTimeZone: tokyo, deadlineTimeZone: adelaide,
                                   startTimeZone: darwin, referenceDate: instant(in: 7))
        #expect(cycle.modes == [.local, .deadline, .hidden])
        #expect(cycle.timeZone(for: .deadline)?.secondsFromGMT(for: instant(in: 7)) == 34_200)
    }

    @Test func threeDistinctZonesCycleThenHideAndReturnToLocal() {
        let cycle = HomeClockCycle(localTimeZone: paris, deadlineTimeZone: tokyo, startTimeZone: newYork)
        #expect(cycle.modes == [.local, .deadline, .start, .hidden])
        #expect(cycle.next(after: .local) == .deadline)
        #expect(cycle.next(after: .deadline) == .start)
        #expect(cycle.next(after: .start) == .hidden)
        #expect(cycle.next(after: .hidden) == .local)
        #expect(cycle.timeZone(for: .deadline)?.identifier == tokyo.identifier)
        #expect(cycle.timeZone(for: .start)?.identifier == newYork.identifier)
        #expect(cycle.timeZone(for: .hidden) == nil)
    }

    @Test func foreignStartIsAvailableEvenWhenDeadlineIsLocal() {
        let cycle = HomeClockCycle(localTimeZone: paris, deadlineTimeZone: paris, startTimeZone: newYork)
        #expect(cycle.modes == [.local, .start, .hidden])
        #expect(cycle.next(after: .local) == .start)
        #expect(cycle.next(after: .start) == .hidden)
    }

    @Test func duplicateForeignZoneAppearsOnlyOnce() {
        let cycle = HomeClockCycle(localTimeZone: paris, deadlineTimeZone: tokyo, startTimeZone: tokyo)
        #expect(cycle.modes == [.local, .deadline, .hidden])
        #expect(cycle.resolvedMode(.start) == .deadline)
        #expect(cycle.timeZone(for: .start)?.identifier == tokyo.identifier)
        #expect(cycle.next(after: .start) == .hidden)
    }

    @Test func automaticLocalZoneDoesNotProduceDuplicateEntries() {
        let local = TimeZone.autoupdatingCurrent
        let fixedLocal = TimeZone(identifier: local.identifier)!
        let cycle = HomeClockCycle(localTimeZone: local, deadlineTimeZone: fixedLocal, startTimeZone: fixedLocal)
        #expect(cycle.modes == [.local, .hidden])
        #expect(cycle.next(after: .local) == .hidden)
    }

    @Test func everyZoneCombinationIsUniqueAndHiddenPreferenceSurvivesCardChanges() {
        for deadline in [paris, newYork, tokyo] {
            for start in [paris, newYork, tokyo] {
                let cycle = HomeClockCycle(localTimeZone: paris, deadlineTimeZone: deadline, startTimeZone: start)
                let identifiers = cycle.modes.compactMap { cycle.timeZone(for: $0)?.identifier }
                #expect(identifiers.count == Set(identifiers).count)
                #expect(identifiers.count == Set([paris.identifier, deadline.identifier, start.identifier]).count)
                #expect(cycle.modes.last == .hidden)
                #expect(cycle.resolvedMode(.hidden) == .hidden)
                #expect(cycle.next(after: .hidden) == .local)
            }
        }
    }

    @Test func unavailablePreferenceFallsBackWithoutLosingThePreferredMode() {
        let cycle = HomeClockCycle(localTimeZone: paris, deadlineTimeZone: paris, startTimeZone: paris)
        #expect(cycle.resolvedMode(.deadline) == .local)
        #expect(cycle.resolvedMode(.start) == .local)
        #expect(cycle.next(after: .deadline) == .hidden)
        let nextCard = HomeClockCycle(localTimeZone: paris, deadlineTimeZone: tokyo, startTimeZone: newYork)
        #expect(nextCard.resolvedMode(.deadline) == .deadline)
        #expect(nextCard.resolvedMode(.start) == .start)
    }

    @Test func allClocksShowTheSameCurrentInstantIncludingSecondsAndLocalDate() {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = .gmt
        let now = utc.date(from: DateComponents(year: 2026, month: 6, day: 30, hour: 0, minute: 30, second: 59))!
        let cycle = HomeClockCycle(localTimeZone: paris, deadlineTimeZone: tokyo, startTimeZone: newYork)
        for language in AppLanguage.allCases {
            for (mode, expected) in [(HomeClockMode.local, "02:30:59"), (.deadline, "09:30:59"), (.start, "20:30:59")] {
                let zone = cycle.timeZone(for: mode)!
                #expect(UntiliaDateFormatting.timeString(now, timeZone: zone, language: language, includingSeconds: true) == expected)
            }
        }
        var calendar = utc
        calendar.timeZone = newYork
        #expect(calendar.component(.day, from: now) == 29)
        calendar.timeZone = tokyo
        #expect(calendar.component(.day, from: now) == 30)
    }
}
