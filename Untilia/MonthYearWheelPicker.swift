import SwiftUI
import UIKit

/// One native picker owns both columns and their gestures. Rows are requested on
/// demand rather than building a SwiftUI view for every year when the sheet opens.
struct MonthYearWheelPicker: UIViewRepresentable {
    static let years = 1900...2500

    @Binding var month: Int
    @Binding var year: Int
    let monthNames: [String]
    var monthLabel = "Month"
    var yearLabel = "Year"

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UIPickerView {
        context.coordinator.makePicker()
    }

    func updateUIView(_ picker: UIPickerView, context: Context) {
        context.coordinator.update(self, picker: picker)
    }

    final class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewAccessibilityDelegate {
        private var parent: MonthYearWheelPicker
        private var displayedMonth: Int
        private var displayedYear: Int
        private var yearRange: ClosedRange<Int>

        init(_ parent: MonthYearWheelPicker) {
            self.parent = parent
            displayedMonth = parent.month
            displayedYear = parent.year
            // Calendar arrows can navigate beyond the wheel's usual limits.
            // Reopening the wheel must never silently replace an existing date.
            yearRange = min(MonthYearWheelPicker.years.lowerBound, parent.year)...max(MonthYearWheelPicker.years.upperBound, parent.year)
        }

        func makePicker() -> UIPickerView {
            let picker = UIPickerView()
            picker.overrideUserInterfaceStyle = .dark
            picker.dataSource = self
            picker.delegate = self
            picker.selectRow(displayedMonth - 1, inComponent: 0, animated: false)
            picker.selectRow(displayedYear - yearRange.lowerBound, inComponent: 1, animated: false)
            return picker
        }

        func update(_ newParent: MonthYearWheelPicker, picker: UIPickerView) {
            let monthsChanged = parent.monthNames != newParent.monthNames
            parent = newParent
            if monthsChanged { picker.reloadComponent(0) }
            let yearRangeChanged = !yearRange.contains(newParent.year)
            if yearRangeChanged {
                yearRange = min(yearRange.lowerBound, newParent.year)...max(yearRange.upperBound, newParent.year)
                picker.reloadComponent(1)
            }
            // Compare model values, not selectedRow: during a gesture UIKit can
            // already be between rows while SwiftUI still holds the old value.
            // An unrelated render must not snap or restart the spinning wheel.
            if monthsChanged || displayedMonth != newParent.month {
                picker.selectRow(newParent.month - 1, inComponent: 0, animated: false)
            }
            if yearRangeChanged || displayedYear != newParent.year {
                picker.selectRow(newParent.year - yearRange.lowerBound, inComponent: 1, animated: false)
            }
            displayedMonth = newParent.month
            displayedYear = newParent.year
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int { 2 }

        func pickerView(_ pickerView: UIPickerView, accessibilityLabelForComponent component: Int) -> String? {
            component == 0 ? parent.monthLabel : parent.yearLabel
        }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            component == 0 ? parent.monthNames.count : yearRange.count
        }

        func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { 32 }

        func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
            let label = (view as? UILabel) ?? UILabel()
            label.text = component == 0 ? parent.monthNames[row] : String(yearRange.lowerBound + row)
            label.font = .systemFont(ofSize: 23)
            label.textColor = .white
            label.textAlignment = .center
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.75
            return label
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            // Publish only the settled column, without rebuilding the native picker.
            if component == 0 {
                let month = row + 1
                guard displayedMonth != month else { return }
                displayedMonth = month
                parent.month = month
            } else {
                let year = yearRange.lowerBound + row
                guard displayedYear != year else { return }
                displayedYear = year
                parent.year = year
            }
        }
    }
}
