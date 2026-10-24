import Foundation

/// Presentation only: omit zero calendar units, but keep complete clock fields.
/// Calendar remainders and exact second totals still come from CountdownEngine.
enum CountdownSecondaryFormatting {
    static func lines(for snapshot: CountdownSnapshot, mode: CountdownDisplayMode, language: AppLanguage) -> [String] {
        let totalSeconds = remainingSecondsTotal(for: snapshot)
        func calendarClock() -> String {
            clock(hours: snapshot.hoursAfterCalendarUnitsRemaining, minutes: snapshot.remainingMinutes, seconds: snapshot.remainingSeconds)
        }

        func calendarLine(_ units: [(Int, L10n.Unit)]) -> String? {
            let text = units.compactMap { L10n.shortUnit($0.0, $0.1, language: language) }
                .joined(separator: " · ")
            return text.isEmpty ? nil : text
        }

        switch mode {
        case .years:
            return [calendarLine([
                (snapshot.monthsAfterYearsRemaining, .months),
                (snapshot.weeksAfterMonthsRemaining, .weeks),
                (snapshot.daysAfterWeeksRemaining, .days)
            ]), calendarClock()].compactMap { $0 }
        case .months:
            return [calendarLine([
                (snapshot.weeksAfterMonthsRemaining, .weeks),
                (snapshot.daysAfterWeeksRemaining, .days)
            ]), calendarClock()].compactMap { $0 }
        case .weeks:
            let remainder = totalSeconds % 604_800
            return [calendarLine([(remainder / 86_400, .days)]),
                    clock(hours: (remainder % 86_400) / 3_600, minutes: (remainder % 3_600) / 60, seconds: remainder % 60)].compactMap { $0 }
        case .days:
            let remainder = totalSeconds % 86_400
            return [clock(hours: remainder / 3_600, minutes: (remainder % 3_600) / 60, seconds: remainder % 60)]
        case .hours:
            return [clock(hours: nil, minutes: snapshot.remainingMinutes, seconds: snapshot.remainingSeconds)]
        case .minutes:
            return [value(snapshot.remainingSeconds, unit: "s")]
        case .seconds:
            return []
        }
    }

    private static func clock(hours: Int?, minutes: Int, seconds: Int) -> String {
        var units = hours.map { [value($0, unit: "h")] } ?? []
        units.append(value(minutes, unit: "min"))
        units.append(value(seconds, unit: "s"))
        return units.joined(separator: " · ")
    }

    private static func value(_ number: Int, unit: String) -> String {
        "\(number == 0 ? "00" : String(number)) \(unit)"
    }
}
