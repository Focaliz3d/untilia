//
//  CountdownEngine.swift
//  Untilia
//

import Foundation

struct CountdownSnapshot: Equatable {
    let daysRemaining: Int
    let isReached: Bool
    let isElapsed: Bool
    let progress: CGFloat
    let remainingHours: Int
    let remainingMinutes: Int
    let remainingSeconds: Int
    let yearsRemaining: Int
    let monthsAfterYearsRemaining: Int
    let weeksAfterMonthsRemaining: Int
    let daysAfterWeeksRemaining: Int
    let hoursAfterCalendarUnitsRemaining: Int
}

enum CountdownEngine {
    static func daysRemaining(from now: Date, to target: Date, calendar: Calendar = .autoupdatingCurrent) -> Int {
        let start = calendar.startOfDay(for: now)
        let end = calendar.startOfDay(for: target)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    static func snapshot(
        now: Date,
        target: Date,
        startDate: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> CountdownSnapshot {
        // Une échéance déjà passée devient un compteur de temps écoulé. Le
        // point de départ configuré reste alors indépendant de ce calcul.
        let isElapsed = target <= now
        let durationStart: Date
        let durationEnd: Date
        let wholeSeconds: Int

        if isElapsed {
            durationStart = target
            durationEnd = now
            wholeSeconds = Int(now.timeIntervalSince(target).rounded(.down))
        } else {
            // Avant le départ, le décompte reste volontairement figé à sa durée
            // initiale. La progression repartira de zéro au moment exact choisi.
            durationStart = max(now, startDate)
            durationEnd = target
            let remainingInterval = max(target.timeIntervalSince(durationStart), 0)
            // A positive fraction of a second is still one second remaining.
            // Rounding down would display zero before the ring reaches its target.
            wholeSeconds = Int(remainingInterval.rounded(.up))
        }

        let displayedNow = calendar.date(
            from: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: durationStart)
        ) ?? durationStart
        let displayedTarget = calendar.date(
            from: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: durationEnd)
        ) ?? durationEnd
        let calendarRemainder = calendarRemainder(
            now: durationStart,
            target: durationEnd,
            displayedNow: displayedNow,
            displayedTarget: displayedTarget,
            calendar: calendar
        )

        return CountdownSnapshot(
            daysRemaining: max(daysRemaining(from: durationStart, to: durationEnd, calendar: calendar), 0),
            isReached: isElapsed,
            isElapsed: isElapsed,
            progress: elapsedProgress(now: now, target: target, startDate: startDate),
            remainingHours: wholeSeconds / 3_600,
            remainingMinutes: (wholeSeconds / 60) % 60,
            remainingSeconds: wholeSeconds % 60,
            yearsRemaining: calendarRemainder.years,
            monthsAfterYearsRemaining: calendarRemainder.months,
            weeksAfterMonthsRemaining: calendarRemainder.weeks,
            daysAfterWeeksRemaining: calendarRemainder.days,
            hoursAfterCalendarUnitsRemaining: calendarRemainder.hours
        )
    }

    private static func calendarRemainder(
        now: Date,
        target: Date,
        displayedNow: Date,
        displayedTarget: Date,
        calendar: Calendar
    ) -> CalendarRemainder {
        let years = max(calendar.dateComponents([.year], from: displayedNow, to: displayedTarget).year ?? 0, 0)
        let displayedAfterYears = calendar.date(byAdding: .year, value: years, to: displayedNow) ?? displayedNow
        let months = max(calendar.dateComponents([.month], from: displayedAfterYears, to: displayedTarget).month ?? 0, 0)

        var cursor = calendar.date(byAdding: .year, value: years, to: now) ?? now
        cursor = calendar.date(byAdding: .month, value: months, to: cursor) ?? cursor

        let residualSeconds = max(Int(target.timeIntervalSince(cursor).rounded(.down)), 0)
        let weeks = residualSeconds / 604_800
        let afterWeeks = residualSeconds % 604_800
        let days = afterWeeks / 86_400
        let afterDays = afterWeeks % 86_400

        return CalendarRemainder(
            years: years,
            months: months,
            weeks: weeks,
            days: days,
            hours: afterDays / 3_600
        )
    }

    static func elapsedProgress(
        now: Date,
        target: Date,
        startDate: Date
    ) -> CGFloat {
        let countdownStart = startDate
        let current = now
        let end = target

        guard current < end else { return 1 }

        let elapsed = current.timeIntervalSince(countdownStart)
        let total = end.timeIntervalSince(countdownStart)
        guard total > 0 else { return 1 }

        return min(max(CGFloat(elapsed / total), 0), 1)
    }
}

private struct CalendarRemainder {
    let years: Int
    let months: Int
    let weeks: Int
    let days: Int
    let hours: Int
}

enum UntiliaDefaults {
    static let targetNames = ["Crépuscule", "Forêt", "Dunes"]
    static let maxTargetNameLength = 12

    static func targetNames(for language: AppLanguage) -> [String] {
        language == .english ? ["Twilight", "Forest", "Dunes"] : targetNames
    }

    static func targetDates(
        from launchDate: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [Date] {
        [
            date(byAdding: .year, value: 1, to: launchDate, calendar: calendar),
            date(byAdding: .month, value: 6, to: launchDate, calendar: calendar),
            date(byAdding: .month, value: -18, to: launchDate, calendar: calendar)
        ]
    }

    static func countdownStartDates(
        from launchDate: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [Date] {
        [
            launchDate,
            date(byAdding: .month, value: -6, to: launchDate, calendar: calendar),
            launchDate
        ]
    }

    private static func date(
        byAdding component: Calendar.Component,
        value: Int,
        to date: Date,
        calendar: Calendar
    ) -> Date {
        calendar.date(byAdding: component, value: value, to: date) ?? date
    }
}
