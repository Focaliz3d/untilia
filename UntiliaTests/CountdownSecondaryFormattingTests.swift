import Foundation
import Testing
@testable import Untilia

@MainActor
struct CountdownSecondaryFormattingTests {
    private var calendar: Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(secondsFromGMT: 0)!
        return result
    }

    private var now: Date { calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 12))! }

    private func snapshot(seconds: Int, elapsed: Bool = false) -> CountdownSnapshot {
        CountdownEngine.snapshot(now: now, target: now.addingTimeInterval(TimeInterval(elapsed ? -seconds : seconds)), startDate: now, calendar: calendar)
    }

    @Test func zeroCalendarUnitsAreHiddenButAllClockFieldsRemainInBothLanguages() {
        let durations: [(CountdownDisplayMode, Int)] = [
            (.years, 365 * 86_400), (.months, 31 * 86_400), (.weeks, 7 * 86_400),
            (.days, 86_400), (.hours, 3_600), (.minutes, 60), (.seconds, 1)
        ]
        for language in [AppLanguage.french, .english] {
            for (mode, seconds) in durations {
                let lines = CountdownSecondaryFormatting.lines(for: snapshot(seconds: seconds), mode: mode, language: language)
                switch mode {
                case .years, .months, .weeks, .days: #expect(lines == ["00 h · 00 min · 00 s"])
                case .hours: #expect(lines == ["00 min · 00 s"])
                case .minutes: #expect(lines == ["00 s"])
                case .seconds: #expect(lines.isEmpty)
                }
            }
        }
    }

    @Test func clockZerosNeverDisappearInAnyPositionForFutureOrElapsedDurations() {
        for elapsed in [false, true] {
            for hours in [0, 3] {
                for minutes in [0, 7] {
                    for seconds in [0, 11] {
                        let duration = 2 * 86_400 + hours * 3_600 + minutes * 60 + seconds
                        let current = snapshot(seconds: duration, elapsed: elapsed)
                        let hour = hours == 0 ? "00" : String(hours)
                        let minute = minutes == 0 ? "00" : String(minutes)
                        let second = seconds == 0 ? "00" : String(seconds)
                        #expect(CountdownSecondaryFormatting.lines(for: current, mode: .days, language: .french) == ["\(hour) h · \(minute) min · \(second) s"])
                        #expect(CountdownSecondaryFormatting.lines(for: current, mode: .hours, language: .english) == ["\(minute) min · \(second) s"])
                        #expect(CountdownSecondaryFormatting.lines(for: current, mode: .minutes, language: .french) == ["\(second) s"])
                    }
                }
            }
        }
    }

    @Test func secondaryFieldsRemainPresentAcrossSecondMinuteHourAndDayRollovers() {
        for (duration, mode, expected) in [
            (120, CountdownDisplayMode.minutes, ["00 s"]),
            (119, .minutes, ["59 s"]),
            (7_200, .hours, ["00 min · 00 s"]),
            (7_199, .hours, ["59 min · 59 s"]),
            (172_801, .days, ["00 h · 00 min · 1 s"]),
            (172_800, .days, ["00 h · 00 min · 00 s"]),
            (172_799, .days, ["23 h · 59 min · 59 s"]),
            (604_800, .weeks, ["00 h · 00 min · 00 s"]),
            (604_799, .weeks, ["6 days", "23 h · 59 min · 59 s"])
        ] {
            #expect(CountdownSecondaryFormatting.lines(for: snapshot(seconds: duration), mode: mode, language: .english) == expected)
        }
    }

    @Test func elapsedAnniversariesOmitZeroCalendarFieldsButKeepTheClock() {
        let start = calendar.date(byAdding: .year, value: -1, to: now)!
        let elapsed = CountdownEngine.snapshot(now: now, target: start, startDate: start, calendar: calendar)
        #expect(elapsed.isElapsed)
        #expect(CountdownSecondaryFormatting.lines(for: elapsed, mode: .years, language: .french) == ["00 h · 00 min · 00 s"])
    }

    @Test func shortCalendarUnitsOmitZeroAndRespectPluralization() {
        #expect(L10n.shortUnit(0, .months, language: .french) == nil)
        #expect(L10n.shortUnit(0, .days, language: .english) == nil)
        #expect(L10n.shortUnit(1, .days, language: .english) == "1 day")
        #expect(L10n.shortUnit(2, .days, language: .english) == "2 days")
        #expect(L10n.shortUnit(-1, .days, language: .english) == nil)
    }

    @Test func screenshotExamplesKeepTheirExactValuesWithoutZeroDays() {
        var paris = calendar
        paris.timeZone = TimeZone(identifier: "Europe/Paris")!
        let target = paris.date(from: DateComponents(year: 2027, month: 5, day: 16))!
        for (second, mode, expected) in [
            (18, CountdownDisplayMode.months, ["3 sem.", "7 h · 55 min · 42 s"]),
            (27, .weeks, ["7 h · 55 min · 33 s"])
        ] {
            let current = paris.date(from: DateComponents(year: 2026, month: 10, day: 24, hour: 16, minute: 4, second: second))!
            let state = CountdownEngine.snapshot(now: current, target: target, startDate: current, calendar: paris)
            #expect(CountdownSecondaryFormatting.lines(for: state, mode: mode, language: .french) == expected)
        }
    }

    @Test func nonzeroCalendarFieldsStayVisibleWithoutBlankLinesOrSeparators() {
        let target = calendar.date(byAdding: .day, value: 1, to: calendar.date(byAdding: .year, value: 1, to: now)!)!
        let state = CountdownEngine.snapshot(now: now, target: target, startDate: now, calendar: calendar)
        #expect(CountdownSecondaryFormatting.lines(for: state, mode: .years, language: .french) == ["1 jour", "00 h · 00 min · 00 s"])
        #expect(CountdownSecondaryFormatting.lines(for: state, mode: .years, language: .english) == ["1 day", "00 h · 00 min · 00 s"])
    }
}
