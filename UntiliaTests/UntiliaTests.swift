//
//  UntiliaTests.swift
//  UntiliaTests
//
//  Created by Olivier on 20/10/2026.
//

import Foundation
import Combine
import Testing
@testable import Untilia

struct UntiliaTests {

    private var parisCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        parisCalendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, _ second: Int = 0) -> Date {
        parisCalendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second))!
    }

    @Test func countsCalendarDaysWithoutUsingElapsedSeconds() {
        let now = date(2026, 3, 28)
        let target = date(2026, 3, 30)

        #expect(CountdownEngine.daysRemaining(from: now, to: target, calendar: parisCalendar) == 2)
    }

    @Test @MainActor func displaysTheSeasonalTimeZoneAbbreviationWithUTCFallback() {
        let paris = TimeZone(identifier: "Europe/Paris")!
        let winter = date(2026, 1, 15)
        let summer = date(2026, 7, 15)
        let fixedOffset = TimeZone(secondsFromGMT: 2 * 60 * 60)!

        #expect(UntiliaDateFormatting.timeZoneAbbreviationOrUTCOffset(for: paris, at: winter) == "CET")
        #expect(UntiliaDateFormatting.timeZoneAbbreviationOrUTCOffset(for: paris, at: summer) == "CEST")
        #expect(UntiliaDateFormatting.timeZoneAbbreviationOrUTCOffset(for: fixedOffset, at: winter) == "UTC+02:00")
    }

    @Test func reachesZeroOnTheTargetDay() {
        let target = date(2026, 12, 31)

        #expect(CountdownEngine.daysRemaining(from: date(2026, 12, 31), to: target, calendar: parisCalendar) == 0)
        let snapshot = CountdownEngine.snapshot(
            now: date(2026, 12, 31),
            target: target,
            startDate: date(2026, 10, 20),
            calendar: parisCalendar
        )
        #expect(snapshot.isReached)
        #expect(snapshot.progress == 1)
    }

    @Test func elapsedProgressReachesFullOnTheSelectedTargetDate() {
        let snapshot = CountdownEngine.snapshot(
            now: date(2026, 12, 1),
            target: date(2026, 12, 1),
            startDate: date(2026, 10, 20),
            calendar: parisCalendar
        )

        #expect(snapshot.progress == 1)
    }

    @Test func elapsedProgressUsesEqualCalendarDivisionsFromStartDate() {
        let snapshot = CountdownEngine.snapshot(
            now: date(2026, 10, 25),
            target: date(2026, 10, 30),
            startDate: date(2026, 10, 20),
            calendar: parisCalendar
        )

        #expect(snapshot.daysRemaining == 5)
        #expect(snapshot.progress > 0.49)
        #expect(snapshot.progress < 0.51)
    }

    @Test func keepsProgressOpenOneDayBeforeTarget() {
        let snapshot = CountdownEngine.snapshot(
            now: date(2026, 10, 20),
            target: date(2026, 10, 21),
            startDate: date(2026, 10, 1),
            calendar: parisCalendar
        )

        #expect(snapshot.daysRemaining == 1)
        #expect(snapshot.progress > 0.94)
        #expect(snapshot.progress < 0.96)
    }

    @Test func exposesRealTimeRemainingAndUpdatesInSeconds() {
        let start = date(2026, 10, 20, 12, 0)
        let target = date(2026, 10, 21, 0, 0)
        let snapshot = CountdownEngine.snapshot(
            now: date(2026, 10, 20, 23, 59, 58),
            target: target,
            startDate: start,
            calendar: parisCalendar
        )

        #expect(snapshot.remainingHours == 0)
        #expect(snapshot.remainingMinutes == 0)
        #expect(snapshot.remainingSeconds == 2)
    }

    @Test func keepsOneSecondVisibleUntilTheExactTargetInstant() {
        let target = date(2026, 10, 21, 0, 0)
        let justBeforeTarget = CountdownEngine.snapshot(
            now: target.addingTimeInterval(-0.25),
            target: target,
            startDate: date(2026, 10, 20, 12, 0),
            calendar: parisCalendar
        )
        let atTarget = CountdownEngine.snapshot(
            now: target,
            target: target,
            startDate: date(2026, 10, 20, 12, 0),
            calendar: parisCalendar
        )

        #expect(justBeforeTarget.remainingSeconds == 1)
        #expect(!justBeforeTarget.isReached)
        #expect(atTarget.remainingSeconds == 0)
        #expect(atTarget.isReached)
        #expect(atTarget.isElapsed)
        #expect(atTarget.progress == 1)
    }

    @Test @MainActor func persistsTheLastDisplayModeForEachCountdown() {
        let suiteName = "UntiliaTests.displayModes.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = UntiliaStore(defaults: defaults, calendar: parisCalendar, now: { self.date(2026, 10, 20) })
        store.updateCountdownDisplayMode(rawValue: 6, for: 0)
        store.updateCountdownDisplayMode(rawValue: 4, for: 1)

        let reloadedStore = UntiliaStore(defaults: defaults, calendar: parisCalendar, now: { self.date(2026, 10, 20) })
        #expect(reloadedStore.countdownDisplayModeRawValues == [6, 4, 0])
    }

    @Test @MainActor func repeatedDisplayModeUpdatesDoNotInvalidateThePagerAgain() {
        let suiteName = "UntiliaTests.displayModeInvalidation.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UntiliaStore(defaults: defaults, calendar: parisCalendar, now: { self.date(2026, 10, 20) })
        var updates = 0
        let observation = store.objectWillChange.sink { updates += 1 }
        defer { observation.cancel() }

        store.updateCountdownDisplayMode(rawValue: 6, for: 0)
        #expect(updates == 1)
        for _ in 0..<5 {
            store.updateCountdownDisplayMode(rawValue: 6, for: 0)
        }
        store.updateCountdownDisplayMode(rawValue: 4, for: -1)
        store.updateCountdownDisplayMode(rawValue: 4, for: 3)
        #expect(updates == 1)
        #expect(store.countdownDisplayModeRawValues == [6, 0, 0])
        #expect(defaults.array(forKey: "daysLeft.countdownDisplayModes") as? [Int] == [6, 0, 0])
    }

    @Test func decomposesTheMinuteBoundaryWithoutDisplayingSixtySeconds() {
        let start = date(2026, 10, 20, 12, 0)
        let now = date(2026, 10, 20, 23, 58, 0)
        let atOneMinute = CountdownEngine.snapshot(
            now: now,
            target: now.addingTimeInterval(60),
            startDate: start,
            calendar: parisCalendar
        )
        let atFiftyNineSeconds = CountdownEngine.snapshot(
            now: now,
            target: now.addingTimeInterval(59),
            startDate: start,
            calendar: parisCalendar
        )

        #expect(atOneMinute.remainingMinutes == 1)
        #expect(atOneMinute.remainingSeconds == 0)
        #expect(atFiftyNineSeconds.remainingMinutes == 0)
        #expect(atFiftyNineSeconds.remainingSeconds == 59)
    }

    @Test func futureCountdownTicksThroughMinuteBoundaryAcrossTimeZones() {
        let paris = TimeZone(identifier: "Europe/Paris")!
        let newYork = TimeZone(identifier: "America/New_York")!
        let parisCalendar = calendar(for: paris)
        let newYorkCalendar = calendar(for: newYork)
        let start = parisCalendar.date(from: DateComponents(year: 2027, month: 6, day: 14, hour: 8))!
        let target = newYorkCalendar.date(from: DateComponents(year: 2027, month: 6, day: 14, hour: 9, minute: 1))!

        let oneSecondBeforeBoundary = CountdownEngine.snapshot(
            now: target.addingTimeInterval(-61),
            target: target,
            startDate: start,
            calendar: newYorkCalendar
        )
        let atBoundary = CountdownEngine.snapshot(
            now: target.addingTimeInterval(-60),
            target: target,
            startDate: start,
            calendar: newYorkCalendar
        )
        let oneSecondAfterBoundary = CountdownEngine.snapshot(
            now: target.addingTimeInterval(-59),
            target: target,
            startDate: start,
            calendar: newYorkCalendar
        )

        #expect(!oneSecondBeforeBoundary.isElapsed)
        #expect(oneSecondBeforeBoundary.remainingMinutes == 1)
        #expect(oneSecondBeforeBoundary.remainingSeconds == 1)
        #expect(atBoundary.remainingMinutes == 1)
        #expect(atBoundary.remainingSeconds == 0)
        #expect(oneSecondAfterBoundary.remainingMinutes == 0)
        #expect(oneSecondAfterBoundary.remainingSeconds == 59)
    }

    @Test func elapsedCountdownTicksThroughMinuteBoundaryAcrossTimeZones() {
        let paris = TimeZone(identifier: "Europe/Paris")!
        let newYork = TimeZone(identifier: "America/New_York")!
        let parisCalendar = calendar(for: paris)
        let newYorkCalendar = calendar(for: newYork)
        let start = parisCalendar.date(from: DateComponents(year: 2027, month: 6, day: 14, hour: 8))!
        let target = newYorkCalendar.date(from: DateComponents(year: 2027, month: 6, day: 14, hour: 9))!

        let atFiftyNineSeconds = CountdownEngine.snapshot(
            now: target.addingTimeInterval(59),
            target: target,
            startDate: start,
            calendar: newYorkCalendar
        )
        let atOneMinute = CountdownEngine.snapshot(
            now: target.addingTimeInterval(60),
            target: target,
            startDate: start,
            calendar: newYorkCalendar
        )
        let oneSecondAfterOneMinute = CountdownEngine.snapshot(
            now: target.addingTimeInterval(61),
            target: target,
            startDate: start,
            calendar: newYorkCalendar
        )

        #expect(atFiftyNineSeconds.isElapsed)
        #expect(atFiftyNineSeconds.remainingMinutes == 0)
        #expect(atFiftyNineSeconds.remainingSeconds == 59)
        #expect(atOneMinute.remainingMinutes == 1)
        #expect(atOneMinute.remainingSeconds == 0)
        #expect(oneSecondAfterOneMinute.remainingMinutes == 1)
        #expect(oneSecondAfterOneMinute.remainingSeconds == 1)
    }

    @Test func displayModesExposeTheCompleteHoursMinutesSecondsRange() {
        let target = date(2026, 10, 21, 15, 0)
        let snapshot = CountdownEngine.snapshot(
            now: date(2026, 10, 20, 12, 58, 59),
            target: target,
            startDate: date(2026, 10, 20, 12, 0),
            calendar: parisCalendar
        )

        #expect(remainingSecondsTotal(for: snapshot) == 93_661)
        #expect(snapshot.remainingHours == 26)
        #expect(snapshot.remainingMinutes == 1)
        #expect(snapshot.remainingSeconds == 1)
        #expect(availableCountdownDisplayModes(for: snapshot).contains(.hours))
        #expect(availableCountdownDisplayModes(for: snapshot).contains(.minutes))
        #expect(availableCountdownDisplayModes(for: snapshot).contains(.seconds))
    }

    @Test func countdownUsesTheSelectedTimeZoneAcrossDaylightSavingTime() {
        let now = date(2027, 3, 27, 12, 0)
        let target = date(2027, 3, 28, 12, 0)
        let snapshot = CountdownEngine.snapshot(
            now: now,
            target: target,
            startDate: now,
            calendar: parisCalendar
        )

        // Le passage à l’heure d’été retire une heure réelle, sans changer
        // le fait que l’échéance est le lendemain à midi, heure de Paris.
        #expect(snapshot.daysRemaining == 1)
        #expect(snapshot.remainingHours == 23)
        #expect(snapshot.yearsRemaining == 0)
        #expect(snapshot.daysAfterWeeksRemaining == 0)
        #expect(snapshot.hoursAfterCalendarUnitsRemaining == 23)
    }

    @Test func progressIsHalfwayThroughTheExactSecondInterval() {
        let start = date(2026, 10, 20, 12, 0)
        let target = date(2026, 10, 21, 12, 0)
        let snapshot = CountdownEngine.snapshot(
            now: date(2026, 10, 21, 0, 0),
            target: target,
            startDate: start,
            calendar: parisCalendar
        )

        #expect(snapshot.progress > 0.49)
        #expect(snapshot.progress < 0.51)
    }

    @Test func exposesAdaptiveCalendarUnitsWithoutUglyTotalHourValues() {
        let snapshot = CountdownEngine.snapshot(
            now: date(2026, 10, 20, 12, 0),
            target: date(2027, 10, 21, 18, 30, 15),
            startDate: date(2026, 10, 20, 12, 0),
            calendar: parisCalendar
        )

        #expect(snapshot.yearsRemaining == 1)
        #expect(snapshot.monthsAfterYearsRemaining == 0)
        #expect(snapshot.weeksAfterMonthsRemaining == 0)
        #expect(snapshot.daysAfterWeeksRemaining == 1)
        #expect(snapshot.hoursAfterCalendarUnitsRemaining == 6)
        #expect(snapshot.remainingMinutes == 30)
        #expect(snapshot.remainingSeconds == 15)
    }

    @Test func decomposesCalendarRemainderIntoMonthsWeeksDaysAndClockUnits() {
        let snapshot = CountdownEngine.snapshot(
            now: date(2026, 10, 20, 12, 0),
            target: date(2027, 12, 29, 15, 4, 5),
            startDate: date(2026, 10, 20, 12, 0),
            calendar: parisCalendar
        )

        #expect(snapshot.yearsRemaining == 1)
        #expect(snapshot.monthsAfterYearsRemaining == 2)
        #expect(snapshot.weeksAfterMonthsRemaining == 1)
        #expect(snapshot.daysAfterWeeksRemaining == 2)
        #expect(snapshot.hoursAfterCalendarUnitsRemaining == 3)
        #expect(snapshot.remainingMinutes == 4)
        #expect(snapshot.remainingSeconds == 5)
    }

    @Test func keepsAVisibleSameMinuteAnniversaryAsOneYear() {
        let snapshot = CountdownEngine.snapshot(
            now: date(2026, 10, 20, 23, 6, 50),
            target: date(2027, 10, 20, 23, 6),
            startDate: date(2026, 10, 20, 12, 0),
            calendar: parisCalendar
        )

        #expect(snapshot.yearsRemaining == 1)
        #expect(snapshot.monthsAfterYearsRemaining == 0)
        #expect(snapshot.weeksAfterMonthsRemaining == 0)
        #expect(snapshot.daysAfterWeeksRemaining == 0)
        #expect(snapshot.hoursAfterCalendarUnitsRemaining == 0)
    }

    @Test func displaysElapsedTimeForPastDatesRelativeToNow() {
        let snapshot = CountdownEngine.snapshot(
            now: date(2027, 1, 2),
            target: date(2026, 12, 31),
            startDate: date(2027, 2, 1),
            calendar: parisCalendar
        )

        #expect(snapshot.daysRemaining == 2)
        #expect(snapshot.isReached)
        #expect(snapshot.isElapsed)
        #expect(snapshot.progress == 1)
        #expect(snapshot.daysAfterWeeksRemaining == 2)
    }

    @Test func defaultDatesAreRelativeToTheLaunchMoment() {
        let launchDate = date(2026, 10, 20, 12, 0)

        #expect(UntiliaDefaults.targetDates(from: launchDate, calendar: parisCalendar) == [
            date(2027, 10, 20, 12, 0),
            date(2027, 4, 20, 12, 0),
            date(2025, 4, 20, 12, 0)
        ])

        #expect(UntiliaDefaults.countdownStartDates(from: launchDate, calendar: parisCalendar) == [
            launchDate,
            date(2026, 4, 20, 12, 0),
            launchDate
        ])
    }

    @MainActor
    @Test func persistsTheSelectedDateLocally() {
        let suiteName = "UntiliaTests.persistence"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let selectedDate = date(2027, 4, 18, 18, 30)
        let selectionDate = date(2026, 10, 20)
        let store = UntiliaStore(defaults: defaults, calendar: parisCalendar, now: { selectionDate })
        store.updateTargetDate(selectedDate)

        let reloadedStore = UntiliaStore(defaults: defaults, calendar: parisCalendar, now: { selectionDate })
        #expect(reloadedStore.targetDate == selectedDate)
        #expect(reloadedStore.countdownStartDate == selectionDate)
    }

    @Test func countdownUsesTheExactTargetHour() {
        let now = date(2026, 10, 20, 20, 0)
        let target = date(2026, 10, 20, 22, 30)
        let snapshot = CountdownEngine.snapshot(
            now: now,
            target: target,
            startDate: now,
            calendar: parisCalendar
        )

        #expect(snapshot.daysRemaining == 0)
        #expect(snapshot.remainingHours == 2)
        #expect(snapshot.remainingMinutes == 30)
        #expect(snapshot.progress == 0)
    }

    @Test func countdownUsesTheRealIntervalBetweenDifferentTimeZones() {
        let paris = TimeZone(identifier: "Europe/Paris")!
        let newYork = TimeZone(identifier: "America/New_York")!
        let start = calendar(for: paris).date(from: DateComponents(year: 2027, month: 6, day: 14, hour: 9))!
        let target = calendar(for: newYork).date(from: DateComponents(year: 2027, month: 6, day: 14, hour: 9))!

        let snapshot = CountdownEngine.snapshot(
            now: start,
            target: target,
            startDate: start,
            calendar: calendar(for: newYork)
        )

        // 09:00 Paris précède 09:00 New York de six heures à cette date.
        #expect(snapshot.remainingHours == 6)
        #expect(snapshot.progress == 0)
    }

    @MainActor
    @Test func persistsTheTimeZoneForEachTarget() {
        let suiteName = "UntiliaTests.targetTimeZone"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let selectionDate = date(2026, 10, 20, 19, 0)
        let store = UntiliaStore(defaults: defaults, calendar: parisCalendar, now: { selectionDate })
        let newYork = TimeZone(identifier: "America/New_York")!
        let newYorkCalendar: Calendar = {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = newYork
            return calendar
        }()
        let target = newYorkCalendar.date(from: DateComponents(year: 2027, month: 6, day: 14, hour: 9, minute: 30))!

        store.updateTarget(target, timeZoneIdentifier: newYork.identifier, for: 1)

        let reloadedStore = UntiliaStore(defaults: defaults, calendar: parisCalendar, now: { selectionDate })
        #expect(reloadedStore.targetTimeZoneIdentifiers[1] == newYork.identifier)
        #expect(reloadedStore.targetDates[1] == target)
    }

    @MainActor
    @Test func persistsAnExplicitCountdownStartDate() {
        let suiteName = "UntiliaTests.explicitStartDate"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let savedAt = date(2026, 10, 20, 19, 0)
        let start = date(2027, 1, 12, 8, 45, 30)
        let target = date(2026, 12, 14, 9, 30)
        let store = UntiliaStore(defaults: defaults, calendar: parisCalendar, now: { savedAt })
        store.updateTarget(target, timeZoneIdentifier: "Europe/Paris", startDate: start, for: 1)

        let reloadedStore = UntiliaStore(defaults: defaults, calendar: parisCalendar, now: { savedAt })
        #expect(reloadedStore.countdownStartDates[1] == start)
        #expect(reloadedStore.targetDates[1] == target)
    }

    @MainActor
    @Test func persistsIndependentStartAndTargetTimeZones() {
        let suiteName = "UntiliaTests.independentTimeZones"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let paris = TimeZone(identifier: "Europe/Paris")!
        let newYork = TimeZone(identifier: "America/New_York")!
        let parisCalendar = calendar(for: paris)
        let newYorkCalendar = calendar(for: newYork)
        let start = parisCalendar.date(from: DateComponents(year: 2027, month: 1, day: 12, hour: 8, minute: 45))!
        let target = newYorkCalendar.date(from: DateComponents(year: 2027, month: 6, day: 14, hour: 9, minute: 30))!
        let store = UntiliaStore(defaults: defaults, calendar: parisCalendar, now: { start })

        store.updateTarget(
            target,
            timeZoneIdentifier: newYork.identifier,
            startDate: start,
            startTimeZoneIdentifier: paris.identifier,
            for: 1
        )

        let reloadedStore = UntiliaStore(defaults: defaults, calendar: parisCalendar, now: { start })
        #expect(reloadedStore.countdownStartTimeZoneIdentifiers[1] == paris.identifier)
        #expect(reloadedStore.targetTimeZoneIdentifiers[1] == newYork.identifier)
        #expect(reloadedStore.countdownStartDates[1] == start)
        #expect(reloadedStore.targetDates[1] == target)
    }

    @MainActor
    @Test func migratesTheSharedTimeZoneToTheStartTimeZone() {
        let suiteName = "UntiliaTests.startTimeZoneMigration"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let sharedZones = ["Europe/Paris", "America/New_York", "Asia/Tokyo"]
        defaults.set(sharedZones, forKey: "daysLeft.targetTimeZones")

        let store = UntiliaStore(defaults: defaults, calendar: parisCalendar, now: { date(2026, 10, 20) })

        #expect(store.countdownStartTimeZoneIdentifiers == sharedZones)
    }

    @MainActor
    @Test func migratesTheLegacyCountdownStartDate() {
        let suiteName = "UntiliaTests.legacyStartDate"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let legacyStart = date(2026, 10, 1, 8, 30)
        defaults.set(legacyStart, forKey: "daysLeft.countdownStartDate")

        let store = UntiliaStore(defaults: defaults, calendar: parisCalendar, now: { date(2026, 10, 20) })
        #expect(store.countdownStartDates == Array(repeating: legacyStart, count: 3))
    }

    private func calendar(for timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    @MainActor
    @Test func updatesOnlyTheSelectedTargetDate() {
        let suiteName = "UntiliaTests.individualTargetUpdate"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let initialDate = date(2026, 10, 20, 19, 0)
        var currentDate = initialDate
        let store = UntiliaStore(defaults: defaults, calendar: parisCalendar, now: { currentDate })
        let originalDates = store.targetDates
        let originalStartDates = store.countdownStartDates
        let updatedDate = date(2027, 6, 14)

        currentDate = date(2026, 10, 21, 8, 30)
        store.updateTargetDate(updatedDate, for: 1)

        #expect(store.targetDates[0] == originalDates[0])
        #expect(store.targetDates[1] == updatedDate)
        #expect(store.targetDates[2] == originalDates[2])
        #expect(store.countdownStartDates[0] == originalStartDates[0])
        #expect(store.countdownStartDates[1] == currentDate)
        #expect(store.countdownStartDates[2] == originalStartDates[2])
    }

    @Test func newDateStartsWithZeroElapsedProgressAtTheMomentItIsSaved() {
        let savedAt = date(2026, 10, 20, 21, 13, 19)
        let target = date(2026, 10, 21)

        let snapshot = CountdownEngine.snapshot(
            now: savedAt,
            target: target,
            startDate: savedAt,
            calendar: parisCalendar
        )

        #expect(snapshot.progress == 0)
    }

    @Test func progressAdvancesFromTheExactSaveInstant() {
        let savedAt = date(2026, 10, 20, 21, 13, 19)
        let target = date(2026, 10, 21)

        let snapshot = CountdownEngine.snapshot(
            now: savedAt.addingTimeInterval(60),
            target: target,
            startDate: savedAt,
            calendar: parisCalendar
        )

        #expect(snapshot.progress > 0)
    }

    @Test func waitsForAFutureStartDateBeforeAdvancingTheCountdown() {
        let now = date(2026, 10, 20, 12, 0)
        let start = date(2026, 10, 22, 12, 0)
        let target = date(2026, 10, 30, 12, 0)
        let snapshot = CountdownEngine.snapshot(
            now: now,
            target: target,
            startDate: start,
            calendar: parisCalendar
        )

        #expect(snapshot.progress == 0)
        #expect(snapshot.daysRemaining == 8)
        // Le changement d’heure d’hiver survient pendant cet intervalle.
        #expect(snapshot.remainingHours == 193)
    }

    @Test func reflectsElapsedProgressWhenTheChosenStartDateIsInThePast() {
        let snapshot = CountdownEngine.snapshot(
            now: date(2026, 10, 25, 12, 0),
            target: date(2026, 10, 30, 12, 0),
            startDate: date(2026, 10, 20, 12, 0),
            calendar: parisCalendar
        )

        #expect(snapshot.progress > 0.49)
        #expect(snapshot.progress < 0.51)
    }

    @MainActor
    @Test func persistsTargetNamesWithoutResettingCountdownStartDate() {
        let suiteName = "UntiliaTests.targetNames"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let selectionDate = date(2026, 10, 20, 19, 0)
        let store = UntiliaStore(defaults: defaults, calendar: parisCalendar, now: { selectionDate })
        let originalStartDates = store.countdownStartDates

        store.updateTargetName("Anniversaire de maman", for: 1)

        let reloadedStore = UntiliaStore(defaults: defaults, calendar: parisCalendar, now: { selectionDate.addingTimeInterval(3600) })
        #expect(reloadedStore.targetNames == ["Crépuscule", "Anniversaire", "Dunes"])
        #expect(reloadedStore.countdownStartDates == originalStartDates)
    }

    @Test func persistsSelectedAppLanguage() {
        let suiteName = "UntiliaTests.appLanguage"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let languageStore = AppLanguageStore(userDefaults: defaults)
        languageStore.setLanguage(.english)

        let reloadedStore = AppLanguageStore(userDefaults: defaults)
        #expect(reloadedStore.language == .english)
        #expect(L10n.text(.settings, language: reloadedStore.language) == "Settings")
    }

    @Test @MainActor func formatsDatesAccordingToSelectedLanguage() {
        let targetDate = date(2027, 10, 23, 10, 49)
        let timeZone = TimeZone(identifier: "Europe/Paris")!

        #expect(UntiliaDateFormatting.dateString(targetDate, timeZone: timeZone, abbreviatedMonth: true, language: .french) == "23 oct. 2027")
        #expect(UntiliaDateFormatting.dateString(targetDate, timeZone: timeZone, abbreviatedMonth: true, language: .english) == "23 Oct 2027")
        #expect(UntiliaDateFormatting.timeString(targetDate, timeZone: timeZone, language: .english) == "10:49")
    }

    @Test @MainActor func formatsClockSecondsWithoutChangingDeadlineTimes() {
        let instant = date(2027, 10, 23, 10, 49).addingTimeInterval(7)
        let paris = TimeZone(identifier: "Europe/Paris")!
        for language in [AppLanguage.french, .english] {
            #expect(UntiliaDateFormatting.timeString(instant, timeZone: paris, language: language, includingSeconds: true) == "10:49:07")
            #expect(UntiliaDateFormatting.timeString(instant, timeZone: .gmt, language: language, includingSeconds: true) == "08:49:07")
            #expect(UntiliaDateFormatting.timeString(instant, timeZone: paris, language: language) == "10:49")
            #expect(UntiliaDateFormatting.timeString(instant.addingTimeInterval(53), timeZone: paris, language: language, includingSeconds: true) == "10:50:00")
        }
    }

    @Test func keepsPrimaryCountdownNumberSeparateFromItsUnit() {
        #expect(L10n.unitName(51, .months, language: .french, uppercase: true) == "MOIS")
        #expect(L10n.unit(51, .months, language: .french) == "51 MOIS")
        #expect(L10n.unitName(51, .months, language: .english, uppercase: true) == "MONTHS")
        #expect(L10n.unit(51, .months, language: .english) == "51 MONTHS")
    }

    @Test @MainActor func aboutVersionUsesTheAppMetadata() {
        #expect(AboutView.versionLabel(info: ["CFBundleShortVersionString": "0.9", "CFBundleVersion": "2"]) == "v0.9 (build 2)")
        #expect(AboutView.versionLabel(info: ["CFBundleShortVersionString": "1.1", "CFBundleVersion": "42"]) == "v1.1 (build 42)")
        #expect(AboutView.versionLabel(info: [:]) == nil)
    }

    @Test @MainActor func aboutLinksOpenTheMatchingSupportLanguage() {
        #expect(AboutView.supportURL(language: .french).absoluteString == "https://focaliz3d.github.io/untilia/#fr")
        #expect(AboutView.supportURL(language: .english).absoluteString == "https://focaliz3d.github.io/untilia/#en")
        #expect(L10n.text(.about, language: .french) == "À propos")
        #expect(L10n.text(.about, language: .english) == "About")
    }
}
