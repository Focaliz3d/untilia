import SwiftUI
import Testing
import UIKit
@testable import Untilia

@MainActor
struct MonthYearWheelPickerTests {
    @MainActor private final class Selection {
        var month = 10
        var year = 2026
        var writes = 0

        func view(locale: String = "fr_FR") -> MonthYearWheelPicker {
            var calendar = Calendar(identifier: .gregorian)
            calendar.locale = Locale(identifier: locale)
            return MonthYearWheelPicker(
                month: Binding(get: { self.month }, set: { self.month = $0; self.writes += 1 }),
                year: Binding(get: { self.year }, set: { self.year = $0; self.writes += 1 }),
                monthNames: calendar.monthSymbols
            )
        }
    }

    @Test func opensAtCurrentSelectionWithoutChangingTheDate() {
        let selection = Selection()
        let coordinator = selection.view().makeCoordinator()
        let picker = coordinator.makePicker()
        #expect(picker.numberOfComponents == 2)
        #expect(picker.numberOfRows(inComponent: 0) == 12)
        #expect(picker.numberOfRows(inComponent: 1) == 601)
        #expect(picker.selectedRow(inComponent: 0) == 9)
        #expect(picker.selectedRow(inComponent: 1) == 126)
        #expect(selection.writes == 0)
    }

    @Test func selectsBothYearLimitsAndMonthsIndependently() {
        let selection = Selection()
        let coordinator = selection.view().makeCoordinator()
        let picker = coordinator.makePicker()
        for (row, year) in [(0, 1900), (600, 2500)] {
            coordinator.pickerView(picker, didSelectRow: row, inComponent: 1)
            #expect(selection.year == year)
            #expect(selection.month == 10)
            coordinator.update(selection.view(), picker: picker)
        }
        for (row, month) in [(0, 1), (11, 12)] {
            coordinator.pickerView(picker, didSelectRow: row, inComponent: 0)
            #expect(selection.month == month)
            #expect(selection.year == 2500)
        }
        #expect(selection.writes == 4)
        coordinator.pickerView(picker, didSelectRow: 11, inComponent: 0)
        #expect(selection.writes == 4)
    }

    @Test func unrelatedUpdatesDoNotResetAnInFlightWheel() {
        let selection = Selection()
        let coordinator = selection.view().makeCoordinator()
        let picker = coordinator.makePicker()
        // Simulate UIKit moving ahead of the model during a gesture.
        picker.selectRow(200, inComponent: 1, animated: false)
        picker.selectRow(5, inComponent: 0, animated: false)
        for _ in 0..<20 { coordinator.update(selection.view(), picker: picker) }
        #expect(picker.selectedRow(inComponent: 1) == 200)
        #expect(picker.selectedRow(inComponent: 0) == 5)
        #expect(selection.writes == 0)
        coordinator.pickerView(picker, didSelectRow: 200, inComponent: 1)
        coordinator.update(selection.view(), picker: picker)
        #expect(selection.year == 2100)
        #expect(picker.selectedRow(inComponent: 0) == 5)
    }

    @Test func externalSelectionAndLanguageChangesAreReflectedWithoutWrites() {
        let selection = Selection()
        let coordinator = selection.view().makeCoordinator()
        let picker = coordinator.makePicker()
        selection.year = 2500
        selection.month = 12
        coordinator.update(selection.view(locale: "en_US"), picker: picker)
        #expect(picker.selectedRow(inComponent: 0) == 11)
        #expect(picker.selectedRow(inComponent: 1) == 600)
        let label = coordinator.pickerView(picker, viewForRow: 11, forComponent: 0, reusing: nil) as! UILabel
        #expect(label.text == "December")
        let reused = coordinator.pickerView(picker, viewForRow: 600, forComponent: 1, reusing: label)
        #expect(reused === label)
        #expect(label.text == "2500")
        #expect(selection.writes == 0)
    }

    @Test func datesBeyondWheelLimitsAreNeverClampedOnOpeningOrUpdating() {
        for year in [1899, 2501] {
            let selection = Selection()
            selection.year = year
            let coordinator = selection.view().makeCoordinator()
            let picker = coordinator.makePicker()
            let row = picker.selectedRow(inComponent: 1)
            let label = coordinator.pickerView(picker, viewForRow: row, forComponent: 1, reusing: nil) as! UILabel
            #expect(label.text == String(year))
            #expect(selection.writes == 0)
            selection.year = year + 5
            coordinator.update(selection.view(), picker: picker)
            let updated = coordinator.pickerView(picker, viewForRow: picker.selectedRow(inComponent: 1), forComponent: 1, reusing: nil) as! UILabel
            #expect(updated.text == String(year + 5))
            #expect(selection.writes == 0)
        }
    }

    @Test func year2500PersistsWithItsTimeAndZonesAndCountsExactSeconds() {
        let suite = "UntiliaTests.year2500"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 24, hour: 12, minute: 0, second: 1))!
        let target = calendar.date(from: DateComponents(year: 2500, month: 12, day: 31, hour: 23, minute: 59))!
        let store = UntiliaStore(defaults: defaults, calendar: calendar, now: { now })
        store.updateTarget(target, timeZoneIdentifier: "Europe/Paris", startDate: now, startTimeZoneIdentifier: "America/New_York", for: 0)
        let restored = UntiliaStore(defaults: defaults, calendar: calendar, now: { now })
        #expect(restored.targetDates[0] == target)
        #expect(restored.countdownStartDates[0] == now)
        #expect(restored.targetTimeZoneIdentifiers[0] == "Europe/Paris")
        #expect(restored.countdownStartTimeZoneIdentifiers[0] == "America/New_York")
        let snapshot = CountdownEngine.snapshot(now: now, target: restored.targetDates[0], startDate: now, calendar: calendar)
        let seconds = snapshot.remainingHours * 3600 + snapshot.remainingMinutes * 60 + snapshot.remainingSeconds
        #expect(seconds == Int(target.timeIntervalSince(now)))
        #expect(!snapshot.isElapsed)
        #expect(snapshot.progress == 0)
    }
}
