//
//  UntiliaStore.swift
//  Untilia
//

import Foundation
import Combine

@MainActor
final class UntiliaStore: ObservableObject {
    @Published private(set) var targetDates: [Date]
    @Published private(set) var targetNames: [String]
    @Published private(set) var targetTimeZoneIdentifiers: [String]
    @Published private(set) var countdownStartDates: [Date]
    @Published private(set) var countdownStartTimeZoneIdentifiers: [String]
    @Published private(set) var countdownDisplayModeRawValues: [Int]
    @Published private(set) var selectedTargetIndex: Int

    var targetDate: Date {
        targetDates[safe: selectedTargetIndex] ?? targetDates[0]
    }

    var countdownStartDate: Date {
        countdownStartDates[safe: selectedTargetIndex] ?? countdownStartDates[0]
    }

    private let defaults: UserDefaults
    private let calendar: Calendar
    private let now: () -> Date
    private let legacyTargetDateKey = "daysLeft.targetDate"
    private let legacyStartDateKey = "daysLeft.countdownStartDate"
    private let targetDatesKey = "daysLeft.targetDates"
    private let targetNamesKey = "daysLeft.targetNames"
    private let targetTimeZonesKey = "daysLeft.targetTimeZones"
    private let startDatesKey = "daysLeft.countdownStartDates"
    private let startTimeZonesKey = "daysLeft.countdownStartTimeZones"
    private let displayModesKey = "daysLeft.countdownDisplayModes"
    private let selectedTargetKey = "daysLeft.selectedTargetIndex"
    private let startDateVersionKey = "daysLeft.countdownStartDateVersion"
    private let currentStartDateVersion = 3

    init(
        defaults: UserDefaults = .standard,
        calendar: Calendar = .autoupdatingCurrent,
        now: @escaping () -> Date = Date.init
    ) {
        self.defaults = defaults
        self.calendar = calendar
        self.now = now

        let launchDate = now()
        let defaultsDates = UntiliaDefaults.targetDates(from: launchDate, calendar: calendar)
        let fallbackTimeZoneIdentifier = calendar.timeZone.identifier
        let storedTimeZoneIdentifiers = defaults.stringArray(forKey: targetTimeZonesKey) ?? []
        let migratedTimeZoneIdentifiers = Array(
            (storedTimeZoneIdentifiers + Array(repeating: fallbackTimeZoneIdentifier, count: 3)).prefix(3)
        ).map { Self.normalizedTimeZoneIdentifier($0, fallback: fallbackTimeZoneIdentifier) }
        self.targetTimeZoneIdentifiers = migratedTimeZoneIdentifiers

        let legacyTargetDate = defaults.object(forKey: legacyTargetDateKey) as? Date
        let storedDates = (defaults.array(forKey: targetDatesKey) as? [Date]) ?? []
        let migratedDates = Array((storedDates + defaultsDates).prefix(3))
        let normalizedDates = migratedDates.enumerated().map { index, date in
            var targetCalendar = calendar
            targetCalendar.timeZone = TimeZone(identifier: migratedTimeZoneIdentifiers[index]) ?? calendar.timeZone
            return Self.normalizedTargetDate(
                index == 0 ? (legacyTargetDate ?? date) : date,
                calendar: targetCalendar
            )
        }
        self.targetDates = normalizedDates.count == 3 ? normalizedDates : defaultsDates

        let defaultNames = UntiliaDefaults.targetNames(for: AppLanguage.detectedFromSystem)
        let storedNames = defaults.array(forKey: targetNamesKey) as? [String] ?? []
        let migratedNames = Array((storedNames + defaultNames).prefix(3))
        self.targetNames = migratedNames.count == 3
            ? migratedNames.map { Self.normalizedName($0) }
            : defaultNames

        let storedStartDates = (defaults.array(forKey: startDatesKey) as? [Date]) ?? []
        let storedVersion = defaults.integer(forKey: startDateVersionKey)
        let legacyStartDate = defaults.object(forKey: legacyStartDateKey) as? Date
        let fallbackStartDates = legacyStartDate.map {
            Array(repeating: $0, count: 3)
        } ?? UntiliaDefaults.countdownStartDates(from: launchDate, calendar: calendar)
        let migratedStartDates = Array((storedStartDates + fallbackStartDates).prefix(3))
        self.countdownStartDates = storedVersion >= currentStartDateVersion && migratedStartDates.count == 3
            ? migratedStartDates
            : fallbackStartDates

        // Les anciennes versions avaient un seul fuseau commun. Il devient
        // naturellement le fuseau de départ lors de la migration.
        let storedStartTimeZoneIdentifiers = defaults.stringArray(forKey: startTimeZonesKey) ?? []
        self.countdownStartTimeZoneIdentifiers = Array(
            (storedStartTimeZoneIdentifiers + migratedTimeZoneIdentifiers).prefix(3)
        ).enumerated().map { index, identifier in
            Self.normalizedTimeZoneIdentifier(
                identifier,
                fallback: migratedTimeZoneIdentifiers[index]
            )
        }

        let storedDisplayModeRawValues = defaults.array(forKey: displayModesKey) as? [Int] ?? []
        self.countdownDisplayModeRawValues = Array(
            (storedDisplayModeRawValues + Array(repeating: 0, count: 3)).prefix(3)
        )

        let savedIndex = defaults.integer(forKey: selectedTargetKey)
        self.selectedTargetIndex = min(max(savedIndex, 0), 2)

        persist()
    }

    func selectTarget(at index: Int) {
        guard (0..<targetDates.count).contains(index) else { return }
        selectedTargetIndex = index
        defaults.set(index, forKey: selectedTargetKey)
    }

    func updateCountdownDisplayMode(rawValue: Int, for index: Int) {
        guard countdownDisplayModeRawValues.indices.contains(index),
              countdownDisplayModeRawValues[index] != rawValue
        else { return }

        var updatedDisplayModes = countdownDisplayModeRawValues
        updatedDisplayModes[index] = rawValue
        countdownDisplayModeRawValues = updatedDisplayModes
        // A unit change must not rewrite dates, names and zones on the tap path.
        defaults.set(updatedDisplayModes, forKey: displayModesKey)
    }

    func updateTargetDate(_ date: Date) {
        updateTargetDate(date, for: selectedTargetIndex)
    }

    func updateTargetDate(_ date: Date, for index: Int) {
        updateTarget(date, timeZoneIdentifier: targetTimeZoneIdentifiers[safe: index] ?? calendar.timeZone.identifier, for: index)
    }

    func updateTarget(_ date: Date, timeZoneIdentifier: String, for index: Int) {
        updateTarget(date, timeZoneIdentifier: timeZoneIdentifier, startDate: now(), for: index)
    }

    func updateTarget(_ date: Date, timeZoneIdentifier: String, startDate: Date, for index: Int) {
        updateTarget(
            date,
            timeZoneIdentifier: timeZoneIdentifier,
            startDate: startDate,
            startTimeZoneIdentifier: timeZoneIdentifier,
            for: index
        )
    }

    func updateTarget(
        _ date: Date,
        timeZoneIdentifier: String,
        startDate: Date,
        startTimeZoneIdentifier: String,
        for index: Int
    ) {
        guard (0..<targetDates.count).contains(index) else { return }

        let normalizedTimeZoneIdentifier = Self.normalizedTimeZoneIdentifier(
            timeZoneIdentifier,
            fallback: calendar.timeZone.identifier
        )
        let targetCalendar = calendar(for: normalizedTimeZoneIdentifier)
        let normalizedTargetDate = Self.normalizedTargetDate(date, calendar: targetCalendar)
        let normalizedStartTimeZoneIdentifier = Self.normalizedTimeZoneIdentifier(
            startTimeZoneIdentifier,
            fallback: normalizedTimeZoneIdentifier
        )

        var updatedDates = targetDates
        updatedDates[index] = normalizedTargetDate
        var updatedTimeZoneIdentifiers = targetTimeZoneIdentifiers
        updatedTimeZoneIdentifiers[index] = normalizedTimeZoneIdentifier
        var updatedStartDates = countdownStartDates
        updatedStartDates[index] = startDate
        var updatedStartTimeZoneIdentifiers = countdownStartTimeZoneIdentifiers
        updatedStartTimeZoneIdentifiers[index] = normalizedStartTimeZoneIdentifier
        targetDates = updatedDates
        targetTimeZoneIdentifiers = updatedTimeZoneIdentifiers
        countdownStartDates = updatedStartDates
        countdownStartTimeZoneIdentifiers = updatedStartTimeZoneIdentifiers
        selectTarget(at: index)
        persist()
    }

    func updateTargetName(_ name: String, for index: Int) {
        guard (0..<targetNames.count).contains(index) else { return }

        var updatedNames = targetNames
        updatedNames[index] = Self.normalizedName(name, fallback: targetNames[index])
        targetNames = updatedNames
        selectTarget(at: index)
        persist()
    }

    func refresh() {
        objectWillChange.send()
    }

    private func persist() {
        defaults.set(targetDates, forKey: targetDatesKey)
        defaults.set(targetNames, forKey: targetNamesKey)
        defaults.set(targetTimeZoneIdentifiers, forKey: targetTimeZonesKey)
        defaults.set(countdownStartDates, forKey: startDatesKey)
        defaults.set(countdownStartTimeZoneIdentifiers, forKey: startTimeZonesKey)
        defaults.set(countdownDisplayModeRawValues, forKey: displayModesKey)
        defaults.set(targetDates[0], forKey: legacyTargetDateKey)
        defaults.set(countdownStartDates[0], forKey: legacyStartDateKey)
        defaults.set(selectedTargetIndex, forKey: selectedTargetKey)
        defaults.set(currentStartDateVersion, forKey: startDateVersionKey)
    }

    private static func normalizedName(_ name: String, fallback: String = "Date") -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return fallback }
        return String(trimmed.prefix(UntiliaDefaults.maxTargetNameLength))
    }

    private static func normalizedTargetDate(_ date: Date, calendar: Calendar) -> Date {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return calendar.date(from: components) ?? calendar.startOfDay(for: date)
    }

    private func calendar(for timeZoneIdentifier: String) -> Calendar {
        var targetCalendar = calendar
        targetCalendar.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? calendar.timeZone
        return targetCalendar
    }

    private static func normalizedTimeZoneIdentifier(_ identifier: String, fallback: String) -> String {
        TimeZone(identifier: identifier) == nil ? fallback : identifier
    }
}
