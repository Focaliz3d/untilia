//
//  SettingsView.swift
//  Untilia
//

import Foundation
import SwiftUI

private enum CalendarEditingDate: Equatable {
    case target
    case start

    func title(language: AppLanguage) -> String {
        switch self {
        case .target: L10n.text(.deadline, language: language)
        case .start: L10n.text(.start, language: language)
        }
    }

    var iconName: String {
        switch self {
        case .target: "calendar"
        case .start: "play.circle.fill"
        }
    }

    func timeTitle(language: AppLanguage) -> String {
        switch self {
        case .target: L10n.text(.deadlineTime, language: language)
        case .start: L10n.text(.startTime, language: language)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: UntiliaStore
    @EnvironmentObject private var languageStore: AppLanguageStore
    @Environment(\.dismiss) private var dismiss
    @State private var displayedMonth = Calendar.autoupdatingCurrent.startOfMonth(for: Date())
    @State private var isShowingMonthYearPicker = false
    @State private var isShowingTimePicker = false
    @State private var isShowingTimeZonePicker = false
    @State private var isShowingNameEditor = false
    @State private var isShowingHelp = false
    @State private var draftTargetDates: [Date] = []
    @State private var savedTargetDates: [Date] = []
    @State private var draftTargetNames: [String] = []
    @State private var savedTargetNames: [String] = []
    @State private var draftTargetTimeZoneIdentifiers: [String] = []
    @State private var savedTargetTimeZoneIdentifiers: [String] = []
    @State private var draftCountdownStartDates: [Date] = []
    @State private var savedCountdownStartDates: [Date] = []
    @State private var draftCountdownStartTimeZoneIdentifiers: [String] = []
    @State private var savedCountdownStartTimeZoneIdentifiers: [String] = []
    @State private var selectedCalendarIndex = 0
    @State private var editingDate: CalendarEditingDate = .target
    @State private var isShowingDiscardAlert = false
    @State private var isShowingLanguagePicker = false

    init(store: UntiliaStore) {
        // Le premier rendu possède déjà les valeurs finales. Une initialisation
        // dans onAppear reconstruisait tout l'éditeur pendant sa transition.
        _draftTargetDates = State(initialValue: store.targetDates)
        _savedTargetDates = State(initialValue: store.targetDates)
        _draftTargetNames = State(initialValue: store.targetNames)
        _savedTargetNames = State(initialValue: store.targetNames)
        _draftTargetTimeZoneIdentifiers = State(initialValue: store.targetTimeZoneIdentifiers)
        _savedTargetTimeZoneIdentifiers = State(initialValue: store.targetTimeZoneIdentifiers)
        _draftCountdownStartDates = State(initialValue: store.countdownStartDates)
        _savedCountdownStartDates = State(initialValue: store.countdownStartDates)
        _draftCountdownStartTimeZoneIdentifiers = State(initialValue: store.countdownStartTimeZoneIdentifiers)
        _savedCountdownStartTimeZoneIdentifiers = State(initialValue: store.countdownStartTimeZoneIdentifiers)
        _selectedCalendarIndex = State(initialValue: store.selectedTargetIndex)

        var calendar = Calendar.autoupdatingCurrent
        calendar.timeZone = TimeZone(identifier: store.targetTimeZoneIdentifiers[store.selectedTargetIndex])
            ?? .autoupdatingCurrent
        _displayedMonth = State(initialValue: calendar.startOfMonth(for: store.targetDate))
    }

    private var language: AppLanguage { languageStore.language }

    private var selectedTargetTimeZoneIdentifier: String {
        draftTargetTimeZoneIdentifiers[safe: selectedCalendarIndex]
            ?? store.targetTimeZoneIdentifiers[safe: selectedCalendarIndex]
            ?? TimeZone.autoupdatingCurrent.identifier
    }

    private var selectedTargetTimeZone: TimeZone {
        TimeZone(identifier: selectedTargetTimeZoneIdentifier) ?? .autoupdatingCurrent
    }

    private var selectedCountdownStartTimeZoneIdentifier: String {
        draftCountdownStartTimeZoneIdentifiers[safe: selectedCalendarIndex]
            ?? store.countdownStartTimeZoneIdentifiers[safe: selectedCalendarIndex]
            ?? selectedTargetTimeZoneIdentifier
    }

    private var selectedCountdownStartTimeZone: TimeZone {
        TimeZone(identifier: selectedCountdownStartTimeZoneIdentifier) ?? selectedTargetTimeZone
    }

    private var editedTimeZoneIdentifier: String {
        switch editingDate {
        case .target: selectedTargetTimeZoneIdentifier
        case .start: selectedCountdownStartTimeZoneIdentifier
        }
    }

    private var editedTimeZone: TimeZone {
        switch editingDate {
        case .target: selectedTargetTimeZone
        case .start: selectedCountdownStartTimeZone
        }
    }

    private var calendar: Calendar {
        var calendar = Calendar.autoupdatingCurrent
        calendar.locale = language.locale
        calendar.firstWeekday = 2
        calendar.timeZone = editedTimeZone
        return calendar
    }

    private var selectedTargetDate: Date {
        draftTargetDates[safe: selectedCalendarIndex] ?? store.targetDates[safe: selectedCalendarIndex] ?? store.targetDates[0]
    }

    private var selectedCountdownStartDate: Date {
        draftCountdownStartDates[safe: selectedCalendarIndex]
            ?? store.countdownStartDates[safe: selectedCalendarIndex]
            ?? Date()
    }

    private var isStartDateEditingDisabled: Bool {
        selectedTargetDate < Date()
    }

    private var dateSummaryTimeZoneColumnWidth: CGFloat {
        var timeZoneLabels = [
            UntiliaDateFormatting.timeZoneAbbreviationOrUTCOffset(
                for: selectedTargetTimeZone,
                at: selectedTargetDate
            )
        ]
        if !isStartDateEditingDisabled {
            timeZoneLabels.append(
                UntiliaDateFormatting.timeZoneAbbreviationOrUTCOffset(
                    for: selectedCountdownStartTimeZone,
                    at: selectedCountdownStartDate
                )
            )
        }
        let longestLabelLength = timeZoneLabels.map(\.count).max() ?? 0

        // Les deux lignes partagent une colonne compacte : son minimum laisse
        // respirer une abréviation, sa largeur suit un éventuel repli UTC±… .
        return max(28, CGFloat(longestLabelLength) * 8 + 2)
    }

    private var editedDate: Date {
        switch editingDate {
        case .target: selectedTargetDate
        case .start: selectedCountdownStartDate
        }
    }

    private var editedHourBinding: Binding<Int> {
        Binding(
            get: { calendar.component(.hour, from: editedDate) },
            set: { hour in
                updateEditedDateTime(hour: hour, minute: calendar.component(.minute, from: editedDate))
            }
        )
    }

    private var editedMinuteBinding: Binding<Int> {
        Binding(
            get: { calendar.component(.minute, from: editedDate) },
            set: { minute in
                updateEditedDateTime(hour: calendar.component(.hour, from: editedDate), minute: minute)
            }
        )
    }

    private var selectedTargetName: String {
        draftTargetNames[safe: selectedCalendarIndex] ?? store.targetNames[safe: selectedCalendarIndex] ?? L10n.fallbackDate(selectedCalendarIndex + 1, language: language)
    }

    private var selectedTheme: UntiliaTheme {
        UntiliaTheme(rawValue: selectedCalendarIndex) ?? .twilight
    }

    private var monthTitle: String {
        let month = calendar.component(.month, from: displayedMonth)
        return calendar.monthSymbols[month - 1].capitalized(with: language.locale)
    }

    private var displayedYear: Int {
        calendar.component(.year, from: displayedMonth)
    }

    private var displayedYearBinding: Binding<Int> {
        Binding(
            get: { displayedYear },
            set: { year in
                var components = calendar.dateComponents([.year, .month], from: displayedMonth)
                components.year = year
                components.day = 1
                updateDisplayedMonth(to: calendar.date(from: components) ?? displayedMonth)
            }
        )
    }

    private var displayedMonthBinding: Binding<Int> {
        Binding(
            get: { calendar.component(.month, from: displayedMonth) },
            set: { month in
                var components = calendar.dateComponents([.year, .month], from: displayedMonth)
                components.month = month
                components.day = 1
                updateDisplayedMonth(to: calendar.date(from: components) ?? displayedMonth)
            }
        )
    }

    private func updateDisplayedMonth(to value: Date) {
        let newMonth = calendar.startOfMonth(for: value)
        displayedMonth = newMonth

        guard draftTargetDates.indices.contains(selectedCalendarIndex) else { return }

        let updatedDate = CalendarMonthSelection.date(in: newMonth, preserving: editedDate, calendar: calendar)
        updateEditedDate(updatedDate)
        displayedMonth = calendar.startOfMonth(for: editedDate)
    }

    private var unsavedIndices: [Int] {
        guard draftTargetDates.count == 3,
              savedTargetDates.count == 3,
              draftTargetNames.count == 3,
              savedTargetNames.count == 3,
              draftTargetTimeZoneIdentifiers.count == 3,
              savedTargetTimeZoneIdentifiers.count == 3,
              draftCountdownStartDates.count == 3,
              savedCountdownStartDates.count == 3,
              draftCountdownStartTimeZoneIdentifiers.count == 3,
              savedCountdownStartTimeZoneIdentifiers.count == 3
        else { return [] }

        return draftTargetDates.indices.filter {
            draftTargetDates[$0] != savedTargetDates[$0]
                || draftTargetNames[$0] != savedTargetNames[$0]
                || draftTargetTimeZoneIdentifiers[$0] != savedTargetTimeZoneIdentifiers[$0]
                || draftCountdownStartDates[$0] != savedCountdownStartDates[$0]
                || draftCountdownStartTimeZoneIdentifiers[$0] != savedCountdownStartTimeZoneIdentifiers[$0]
        }
    }

    private var selectedHasUnsavedChanges: Bool {
        unsavedIndices.contains(selectedCalendarIndex)
    }

    private var saveButtonTitle: String {
        selectedHasUnsavedChanges
            ? L10n.text(.saveChanges, language: language)
            : L10n.text(.dateConfirmed, language: language)
    }

    private var monthDays: [Date?] {
        let monthStart = calendar.startOfMonth(for: displayedMonth)
        let dayCount = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let leadingDays = (firstWeekday - calendar.firstWeekday + 7) % 7

        var dates = Array<Date?>(repeating: nil, count: leadingDays)
        dates.append(contentsOf: (1...dayCount).compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: monthStart)
        })

        // Une grille de calendrier reste toujours sur six semaines pour que
        // sa hauteur ne change jamais d’un mois ou d’une année à l’autre.
        if dates.count < 42 {
            dates.append(contentsOf: Array(repeating: nil, count: 42 - dates.count))
        }
        return dates
    }

    var body: some View {
        VStack(spacing: 0) {
            dismissHandle
            GeometryReader { geometry in
                let usableHeight = geometry.size.height - geometry.safeAreaInsets.top - geometry.safeAreaInsets.bottom
                let isLandscape = geometry.size.width > geometry.size.height
                // La zone sûre d’un iPhone 15 laisse environ 760 points utiles :
                // le palier dense maintient alors le bouton d’enregistrement à vue
                // sans sacrifier la lisibilité ni imposer de défilement.
                let isVeryCompact = usableHeight < 800
                let isCompact = usableHeight < 900
                let stackSpacing: CGFloat = isVeryCompact ? 6 : isCompact ? 9 : 16
                let selectorHeight: CGFloat = isVeryCompact ? 56 : isCompact ? 66 : 74
                let targetPadding: CGFloat = isVeryCompact ? 8 : isCompact ? 12 : 20
                let targetSpacing: CGFloat = isVeryCompact ? 7 : isCompact ? 10 : 14
                let targetDateHeight: CGFloat = isVeryCompact ? 42 : isCompact ? 50 : 60
                let targetNameHeight: CGFloat = isVeryCompact ? 42 : isCompact ? 50 : 58
                let calendarPadding: CGFloat = isVeryCompact ? 10 : isCompact ? 14 : 20
                let calendarSpacing: CGFloat = isVeryCompact ? 6 : isCompact ? 10 : 20
                let calendarGridSpacing: CGFloat = isVeryCompact ? 5 : isCompact ? 8 : 18
                let calendarDayHeight: CGFloat = isVeryCompact ? 24 : isCompact ? 28 : 32
                let buttonHeight: CGFloat = isVeryCompact ? 50 : isCompact ? 54 : 60

                ZStack {
                    selectedTheme.backgroundGradient[0]
                        .ignoresSafeArea()

                    Circle()
                        .fill(selectedTheme.accent.opacity(0.09))
                        .frame(width: 360, height: 360)
                        .blur(radius: 90)
                        .offset(x: 100, y: -240)
                        .allowsHitTesting(false)

                    if isLandscape {
                        landscapeSettingsContent(
                            width: geometry.size.width,
                            height: geometry.size.height,
                            safeAreaTop: geometry.safeAreaInsets.top,
                            safeAreaBottom: geometry.safeAreaInsets.bottom
                        )
                    } else {
                        VStack(spacing: stackSpacing) {
                            header
                            Spacer(minLength: 0)
                            dateSelectors(height: selectorHeight)
                                .frame(maxWidth: .infinity)
                            Spacer(minLength: 0)
                            targetDateRow(
                                verticalPadding: targetPadding,
                                spacing: targetSpacing,
                                dateHeight: targetDateHeight,
                                nameHeight: targetNameHeight
                            )
                            .frame(maxWidth: .infinity)
                            // Compensate optically for the cards' downward shadow.
                            // Portrait only; the surrounding blocks keep their positions.
                            .offset(y: 3)
                            Spacer(minLength: 0)
                            calendarCard(
                                verticalPadding: calendarPadding,
                                spacing: calendarSpacing,
                                gridSpacing: calendarGridSpacing,
                                dayHeight: calendarDayHeight
                            )
                            .frame(maxWidth: .infinity)
                            Spacer(minLength: 0)

                            saveButton(height: buttonHeight)

                            Spacer(minLength: 0)
                            Spacer(minLength: isVeryCompact ? 0 : isCompact ? 4 : 16)
                        }
                        .padding(.horizontal, isCompact ? 16 : 20)
                        .padding(.top, isCompact ? 5 : 8)
                        .padding(.bottom, isCompact ? 2 : 8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                }
            }
        }
        .background(selectedTheme.backgroundGradient[0].ignoresSafeArea())
        .background(SettingsSheetConfiguration(backgroundColor: selectedTheme.backgroundGradient[0]).frame(width: 0, height: 0))
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
        .presentationCompactAdaptation(.none)
        .modifier(SettingsSheetSizing())
        .presentationDragIndicator(.hidden)
        .defersSystemGestures(on: .top)
        .interactiveDismissDisabled(!unsavedIndices.isEmpty)
        .accessibilityAction(.escape, requestDismiss)
        .sheet(isPresented: $isShowingHelp) {
            AboutView(theme: selectedTheme)
                .environmentObject(languageStore)
        }
        .sheet(isPresented: $isShowingMonthYearPicker) {
            MonthYearPickerSheet(
                month: displayedMonthBinding,
                year: displayedYearBinding,
                calendar: calendar,
                theme: selectedTheme
            )
        }
        .sheet(isPresented: $isShowingTimePicker) {
            TimePickerSheet(
                hour: editedHourBinding,
                minute: editedMinuteBinding,
                title: editingDate.timeTitle(language: language),
                theme: selectedTheme
            )
        }
        .sheet(isPresented: $isShowingTimeZonePicker) {
            TimeZonePickerSheet(
                selectedIdentifier: editedTimeZoneIdentifier,
                targetDate: editedDate,
                theme: selectedTheme,
                onSelect: updateEditedDateTimeZone(to:)
            )
        }
        .sheet(isPresented: $isShowingNameEditor) {
            NameEditorSheet(
                initialName: selectedTargetName,
                theme: selectedTheme,
                onSave: updateDraftName
            )
        }
        .alert(L10n.text(.unsavedChanges, language: language), isPresented: $isShowingDiscardAlert) {
            Button(L10n.text(.stayInSettings, language: language), role: .cancel) { }
            Button(L10n.text(.leaveWithoutSaving, language: language), role: .destructive) {
                dismiss()
            }
        } message: {
            Text(L10n.text(.unsavedChangesMessage, language: language))
        }
    }

    private func landscapeSettingsContent(
        width: CGFloat,
        height: CGFloat,
        safeAreaTop: CGFloat,
        safeAreaBottom: CGFloat
    ) -> some View {
        let editorColumnWidth = min(max(width * 0.42, 336), 430)
        let isShort = height < 380
        let landscapeScale = min(max((height - 390) / 40, 0), 1)
        let calendarVerticalPadding = 8 + (4 * landscapeScale)
        let calendarSpacing = 5 + (3 * landscapeScale)
        let calendarGridSpacing = 4 + landscapeScale
        let calendarDayHeight = 18 + (4 * landscapeScale)
        let saveSpacing = isShort ? 12 : 22 + (6 * landscapeScale)

        return VStack(spacing: 0) {
            Spacer(minLength: 0)

            HStack(alignment: .bottom, spacing: 16) {
                VStack(spacing: isShort ? 6 : 8) {
                    header
                        .offset(y: -20 * landscapeScale)

                    VStack(spacing: isShort ? 6 : 8) {
                        dateSelectors(height: isShort ? 56 : 64)

                        targetDateRow(
                            verticalPadding: isShort ? 5 : 7,
                            spacing: 5,
                            dateHeight: isShort ? 36 : 38,
                            nameHeight: isShort ? 36 : 38
                        )
                        // Move only the field group; keep the cards and save button anchored.
                        .offset(y: (saveSpacing - (isShort ? 0 : 10)) / 2)
                    }
                    .offset(y: isShort ? 0 : 10)

                    saveButton(height: isShort ? 44 : 48)
                        .padding(.top, saveSpacing)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: editorColumnWidth)

                calendarCard(
                    verticalPadding: calendarVerticalPadding,
                    spacing: calendarSpacing,
                    gridSpacing: calendarGridSpacing,
                    dayHeight: calendarDayHeight
                )
                .frame(maxWidth: .infinity)
            }
            .offset(y: isShort ? -8 : 4 + (8 * landscapeScale))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.top, isShort ? 4 : safeAreaTop + 4)
        .padding(.bottom, isShort ? 6 : safeAreaBottom + 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func saveButton(height: CGFloat) -> some View {
        Button(action: saveChanges) {
            HStack(spacing: 11) {
                if !selectedHasUnsavedChanges {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 25, weight: .semibold))
                }

                Text(saveButtonTitle)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                selectedTheme.buttonColor.opacity(selectedHasUnsavedChanges ? 0.88 : 0.34),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.22), lineWidth: 1)
            )
            // Une seule silhouette ombrée pour le bloc, pas pour chaque enfant.
            .compositingGroup()
            .shadow(color: selectedTheme.buttonColor.opacity(selectedHasUnsavedChanges ? 0.14 : 0.05), radius: 11, y: 6)
            .opacity(selectedHasUnsavedChanges ? 1 : 0.62)
        }
        .buttonStyle(.plain)
        .disabled(!selectedHasUnsavedChanges)
        .accessibilityValue(selectedHasUnsavedChanges ? L10n.text(.unsavedChanges, language: language) : L10n.text(.dateConfirmed, language: language))
        .accessibilityIdentifier("validateDateButton")
    }

    private func saveChanges() {
        guard selectedHasUnsavedChanges,
              draftTargetDates.indices.contains(selectedCalendarIndex),
              draftTargetNames.indices.contains(selectedCalendarIndex),
              savedTargetDates.indices.contains(selectedCalendarIndex),
              savedTargetNames.indices.contains(selectedCalendarIndex),
              draftTargetTimeZoneIdentifiers.indices.contains(selectedCalendarIndex),
              savedTargetTimeZoneIdentifiers.indices.contains(selectedCalendarIndex),
              draftCountdownStartDates.indices.contains(selectedCalendarIndex),
              savedCountdownStartDates.indices.contains(selectedCalendarIndex),
              draftCountdownStartTimeZoneIdentifiers.indices.contains(selectedCalendarIndex),
              savedCountdownStartTimeZoneIdentifiers.indices.contains(selectedCalendarIndex)
        else { return }

        if draftTargetDates[selectedCalendarIndex] != savedTargetDates[selectedCalendarIndex]
            || draftTargetTimeZoneIdentifiers[selectedCalendarIndex] != savedTargetTimeZoneIdentifiers[selectedCalendarIndex]
            || draftCountdownStartDates[selectedCalendarIndex] != savedCountdownStartDates[selectedCalendarIndex]
            || draftCountdownStartTimeZoneIdentifiers[selectedCalendarIndex] != savedCountdownStartTimeZoneIdentifiers[selectedCalendarIndex] {
            store.updateTarget(
                draftTargetDates[selectedCalendarIndex],
                timeZoneIdentifier: draftTargetTimeZoneIdentifiers[selectedCalendarIndex],
                startDate: draftCountdownStartDates[selectedCalendarIndex],
                startTimeZoneIdentifier: draftCountdownStartTimeZoneIdentifiers[selectedCalendarIndex],
                for: selectedCalendarIndex
            )
        }

        if draftTargetNames[selectedCalendarIndex] != savedTargetNames[selectedCalendarIndex] {
            store.updateTargetName(draftTargetNames[selectedCalendarIndex], for: selectedCalendarIndex)
        }

        var updatedSavedDates = savedTargetDates
        updatedSavedDates[selectedCalendarIndex] = draftTargetDates[selectedCalendarIndex]
        savedTargetDates = updatedSavedDates

        var updatedSavedNames = savedTargetNames
        updatedSavedNames[selectedCalendarIndex] = draftTargetNames[selectedCalendarIndex]
        savedTargetNames = updatedSavedNames

        var updatedSavedTimeZones = savedTargetTimeZoneIdentifiers
        updatedSavedTimeZones[selectedCalendarIndex] = draftTargetTimeZoneIdentifiers[selectedCalendarIndex]
        savedTargetTimeZoneIdentifiers = updatedSavedTimeZones

        var updatedSavedStartDates = savedCountdownStartDates
        updatedSavedStartDates[selectedCalendarIndex] = draftCountdownStartDates[selectedCalendarIndex]
        savedCountdownStartDates = updatedSavedStartDates

        var updatedSavedStartTimeZones = savedCountdownStartTimeZoneIdentifiers
        updatedSavedStartTimeZones[selectedCalendarIndex] = draftCountdownStartTimeZoneIdentifiers[selectedCalendarIndex]
        savedCountdownStartTimeZoneIdentifiers = updatedSavedStartTimeZones
    }

    private func updateDraftName(_ name: String) {
        guard draftTargetNames.indices.contains(selectedCalendarIndex) else { return }
        var updatedNames = draftTargetNames
        updatedNames[selectedCalendarIndex] = name
        draftTargetNames = updatedNames
    }

    private func requestDismiss() {
        guard let firstUnsavedIndex = unsavedIndices.first else {
            dismiss()
            return
        }

        selectedCalendarIndex = firstUnsavedIndex
        displayedMonth = calendar.startOfMonth(for: draftTargetDates[firstUnsavedIndex])
        isShowingDiscardAlert = true
    }

    private var dismissHandle: some View {
        Button(action: requestDismiss) {
            Capsule()
                .fill(.white.opacity(0.3))
                .frame(width: 44, height: 5)
                .frame(width: 80, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.text(.close, language: language))
        .accessibilityIdentifier("closeSettingsButton")
        .frame(maxWidth: .infinity)
        .highPriorityGesture(
            DragGesture(minimumDistance: 12).onEnded { gesture in
                if gesture.translation.height > 44,
                   gesture.translation.height > abs(gesture.translation.width) {
                    requestDismiss()
                }
            }
        )
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(L10n.text(.settings, language: language))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 0)

            Button { isShowingHelp = true } label: {
                Image(systemName: "questionmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(width: 48, height: 48)
                    .background(selectedTheme.accent.opacity(0.18), in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.14), lineWidth: 1))
                    .compositingGroup()
                    .shadow(color: selectedTheme.accent.opacity(0.18), radius: 14, y: 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.text(.about, language: language))
            .accessibilityIdentifier("settingsHelpButton")

            HStack(spacing: 6) {
                if isShowingLanguagePicker {
                    ForEach(AppLanguage.allCases) { option in
                        Button {
                            isShowingLanguagePicker = false
                            languageStore.setLanguage(option)
                        } label: {
                            Text(option.flag)
                                .font(.system(size: 16))
                                .frame(width: 28, height: 28)
                                .background(
                                    option == language
                                        ? selectedTheme.accent.opacity(0.22)
                                        : .white.opacity(0.07),
                                    in: Circle()
                                )
                                .overlay(
                                    Circle()
                                        .stroke(
                                            option == language
                                                ? selectedTheme.accent.opacity(0.88)
                                                : .white.opacity(0.1),
                                            lineWidth: 1
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(option.nativeName)
                    }
                }

                Button {
                    isShowingLanguagePicker.toggle()
                } label: {
                    Image(systemName: "globe")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92))
                        .frame(width: 48, height: 48)
                        .background(
                            isShowingLanguagePicker
                                ? selectedTheme.accent.opacity(0.2)
                                : selectedTheme.accent.opacity(0.18),
                            in: Circle()
                        )
                        .overlay(
                            Circle().stroke(
                                isShowingLanguagePicker
                                    ? selectedTheme.accent.opacity(0.7)
                                    : .white.opacity(0.14),
                                lineWidth: 1
                            )
                        )
                        .compositingGroup()
                        .shadow(color: selectedTheme.accent.opacity(0.18), radius: 14, y: 6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.text(.language, language: language))
                .accessibilityIdentifier("languageButton")
            }
            .animation(.easeOut(duration: 0.12), value: isShowingLanguagePicker)
        }
    }

    private func dateSelectors(height: CGFloat) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<UntiliaTheme.allCases.count, id: \.self) { index in
                let date = draftTargetDates[safe: index] ?? store.targetDates[index]
                let name = draftTargetNames[safe: index] ?? store.targetNames[index]
                let theme = UntiliaTheme.allCases[index]
                let timeZone = TimeZone(
                    identifier: draftTargetTimeZoneIdentifiers[safe: index]
                        ?? store.targetTimeZoneIdentifiers[safe: index]
                        ?? ""
                ) ?? .autoupdatingCurrent

                Button {
                    selectedCalendarIndex = index
                    if date < Date() {
                        editingDate = .target
                    }
                    displayedMonth = calendar.startOfMonth(for: date)
                } label: {
                    VStack(alignment: .center, spacing: 5) {
                        Text(name)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(0.5)
                            .foregroundStyle(.white.opacity(0.96))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity, alignment: .center)

                        VStack(alignment: .center, spacing: 1) {
                            Text(UntiliaDateFormatting.dateString(date, timeZone: timeZone, abbreviatedMonth: true, language: language))
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.62))
                                .lineLimit(1)
                                .minimumScaleFactor(0.65)

                            HStack(alignment: .firstTextBaseline, spacing: 3) {
                                Text(UntiliaDateFormatting.timeString(date, timeZone: timeZone, language: language))
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(theme.accent)

                                Text("·")
                                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.42))

                                Text(UntiliaDateFormatting.timeZoneAbbreviationOrUTCOffset(for: timeZone, at: date))
                                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(theme.accent.opacity(0.78))
                            }
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 14)
                    .frame(height: height)
                    .background(
                        LinearGradient(
                            colors: theme.cardGradient,
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(selectedCalendarIndex == index ? theme.accent.opacity(0.88) : .white.opacity(0.12), lineWidth: selectedCalendarIndex == index ? 1.5 : 1)
                    )
                    .compositingGroup()
                    .shadow(color: selectedCalendarIndex == index ? theme.accent.opacity(0.18) : .black.opacity(0.12), radius: selectedCalendarIndex == index ? 14 : 8, y: 6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.dateCardEditorAccessibility(name: name, index: index + 1, language: language))
                .accessibilityIdentifier("settingsDateSelector\(index)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settingsDateSelectors")
    }

    private func targetDateRow(
        verticalPadding: CGFloat,
        spacing: CGFloat,
        dateHeight: CGFloat,
        nameHeight: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: spacing) {
            Button {
                isShowingNameEditor = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(selectedTheme.accent)
                        .frame(width: 18)

                    Text(L10n.text(.name, language: language))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .tracking(0.3)
                        .foregroundStyle(.white.opacity(0.78))
                        .frame(width: 60, alignment: .leading)

                    Spacer(minLength: 8)

                    Text(selectedTargetName)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.93))
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(selectedTheme.accent.opacity(0.7))
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .frame(height: nameHeight)
                .background(selectedTheme.surfaceHighlight.opacity(0.30), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(selectedTheme.accent.opacity(0.24), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.editNameAccessibility(name: selectedTargetName, language: language))
            .accessibilityHint(language == .english ? "Edit name" : "Modifier le nom")
            .accessibilityIdentifier("nameEditorButton")

            dateSummaryButton(
                editing: .start,
                date: selectedCountdownStartDate,
                height: dateHeight
            )

            dateSummaryButton(
                editing: .target,
                date: selectedTargetDate,
                height: dateHeight
            )
        }
        .padding(.horizontal, 0)
        .padding(.vertical, verticalPadding)
    }

    private func dateSummaryButton(
        editing: CalendarEditingDate,
        date: Date,
        height: CGFloat
    ) -> some View {
        let timeZone = editing == .target ? selectedTargetTimeZone : selectedCountdownStartTimeZone
        let isDisabled = editing == .start && isStartDateEditingDisabled
        let isCurrentEditing = editingDate == editing && !isDisabled

        return Button {
            guard !isDisabled else { return }
            selectDateForEditing(editing)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: editing.iconName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isDisabled ? .white.opacity(0.24) : selectedTheme.accent)
                    .frame(width: 18)

                Text(editing.title(language: language).uppercased(with: language.locale))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .tracking(0.3)
                    .foregroundStyle(.white.opacity(isDisabled ? 0.32 : 0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(width: 60, alignment: .leading)

                Spacer(minLength: 0)

                if isDisabled {
                    HStack(spacing: 5) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9, weight: .semibold))

                        Text(L10n.text(.deadlinePassed, language: language))
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .tracking(0.7)
                    }
                    .foregroundStyle(.white.opacity(0.28))
                } else {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text(UntiliaDateFormatting.dateString(date, timeZone: timeZone, abbreviatedMonth: true, language: language))
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.93))
                                .lineLimit(1)
                                .frame(width: 88, alignment: .trailing)

                            Text("\u{2002}·\u{2002}")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.42))

                            Text(UntiliaDateFormatting.timeString(date, timeZone: timeZone, language: language))
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(selectedTheme.accent.opacity(0.92))

                            Text("\u{2002}·\u{2002}")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.42))

                            Text(UntiliaDateFormatting.timeZoneAbbreviationOrUTCOffset(for: timeZone, at: date))
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(selectedTheme.accent.opacity(0.92))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(width: dateSummaryTimeZoneColumnWidth, alignment: .leading)
                        }
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)

                        VStack(alignment: .trailing, spacing: 1) {
                            HStack(spacing: 0) {
                                Text(UntiliaDateFormatting.dateString(date, timeZone: timeZone, abbreviatedMonth: true, language: language))
                                    .foregroundStyle(.white.opacity(0.93))
                                Text("\u{2002}·\u{2002}")
                                    .foregroundStyle(.white.opacity(0.42))
                                Text(UntiliaDateFormatting.timeString(date, timeZone: timeZone, language: language))
                                    .monospacedDigit()
                                    .foregroundStyle(selectedTheme.accent.opacity(0.92))
                            }
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            Text(UntiliaDateFormatting.timeZoneAbbreviationOrUTCOffset(for: timeZone, at: date))
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(selectedTheme.accent.opacity(0.92))
                        }
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }

            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                isDisabled
                    ? .white.opacity(0.05)
                    : isCurrentEditing
                    ? selectedTheme.surfaceHighlight.opacity(0.52)
                    : selectedTheme.surfaceHighlight.opacity(0.32),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        isDisabled ? .white.opacity(0.08) : selectedTheme.accent.opacity(isCurrentEditing ? 0.48 : 0.24),
                        lineWidth: isCurrentEditing ? 1.4 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityLabel(
            isDisabled
                ? L10n.text(.startUnavailable, language: language)
                : L10n.editDateAccessibility(
                    title: editing.title(language: language),
                    date: UntiliaDateFormatting.dateString(date, timeZone: timeZone, abbreviatedMonth: true, language: language),
                    time: UntiliaDateFormatting.timeString(date, timeZone: timeZone, language: language),
                    timeZone: UntiliaDateFormatting.timeZoneAbbreviationOrUTCOffset(for: timeZone, at: date),
                    language: language
                )
        )
        .accessibilityIdentifier(editing == .target ? "targetDateSummaryButton" : "startDateSummaryButton")
    }

    private func calendarCard(
        verticalPadding: CGFloat,
        spacing: CGFloat,
        gridSpacing: CGFloat,
        dayHeight: CGFloat
    ) -> some View {
        VStack(spacing: spacing) {
            HStack {
                HStack(spacing: 8) {
                    Button {
                        isShowingMonthYearPicker = true
                    } label: {
                        HStack(spacing: 5) {
                            Text(monthTitle)
                            Text(verbatim: String(displayedYear))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .font(.system(size: calendarValueFontSize, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))
                        .padding(.horizontal, 10)
                        .frame(height: 34)
                        .background(selectedTheme.surfaceHighlight.opacity(0.34), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.text(.chooseMonthAndYear, language: language))
                    .accessibilityIdentifier("monthYearPickerButton")
                }

                Spacer()

                HStack(spacing: 22) {
                    monthButton(symbol: "chevron.left") {
                        updateDisplayedMonth(to: calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth)
                    }
                    Button(action: resetCalendarToToday) {
                        shortcutIcon("calendar.badge.clock")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.text(.returnToToday, language: language))
                    monthButton(symbol: "chevron.right") {
                        updateDisplayedMonth(to: calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth)
                    }
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: gridSpacing) {
                ForEach(language == .english ? ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"] : ["LUN", "MAR", "MER", "JEU", "VEN", "SAM", "DIM"], id: \.self) { weekday in
                    Text(weekday)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(selectedTheme.accent.opacity(0.62))
                }

                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, date in
                    if let date {
                        CalendarDayButton(
                            date: date,
                            calendar: calendar,
                            theme: selectedTheme,
                            isSelected: calendar.isDate(date, inSameDayAs: editedDate),
                            height: dayHeight,
                            action: {
                                let updatedDate = calendar.date(
                                    bySettingHour: calendar.component(.hour, from: editedDate),
                                    minute: calendar.component(.minute, from: editedDate),
                                    second: 0,
                                    of: date
                                ) ?? date
                                updateEditedDate(updatedDate)
                            }
                        )
                    } else {
                        Color.clear.frame(height: dayHeight)
                    }
                }
            }

            VStack(spacing: 4) {
                dateTimeControl

                HStack(spacing: 8) {
                    Button {
                        isShowingTimeZonePicker = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "globe.americas.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(selectedTheme.accent)
                                .frame(width: 18, height: 28)

                            settingsControlCaption(
                                title: L10n.text(.timeZone, language: language),
                                subtitle: "\(selectedTimeZoneCity) · \(selectedTimeZoneAbbreviation)"
                            )

                            Spacer(minLength: 0)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel(L10n.text(.chooseTimeZone, language: language))

                    HStack(spacing: 8) {
                        Button(action: resetEditedTimeZoneToCurrent) {
                            shortcutIcon("location.fill")
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(L10n.text(.useLocalTimeZone, language: language))

                        Button {
                            isShowingTimeZonePicker = true
                        } label: {
                            editableValuePill(UntiliaDateFormatting.utcOffsetString(for: editedTimeZone, at: editedDate))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(L10n.timeZoneAccessibility(city: selectedTimeZoneCity, offset: UntiliaDateFormatting.utcOffsetString(for: editedTimeZone, at: editedDate), language: language))
                    }
                    .frame(width: timeControlActionsWidth)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, verticalPadding)
        .background(selectedTheme.surfaceColor.opacity(0.92), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(selectedTheme.accent.opacity(0.24), lineWidth: 1)
        )
        .accessibilityIdentifier("targetDatePicker")
    }

    private let timeControlActionsWidth: CGFloat = 176
    private let calendarValueFontSize: CGFloat = 18

    private var dateTimeControl: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(selectedTheme.accent)
                .frame(width: 18, height: 28)

            settingsControlCaption(
                title: editingDate.timeTitle(language: language),
                subtitle: L10n.text(.localTimeInTimeZone, language: language)
            )
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                Button(action: setEditedDateToNow) {
                    shortcutIcon("calendar.badge.clock")
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.setNowAccessibility(title: editingDate.timeTitle(language: language), language: language))

                Button(action: resetEditedDateTime) {
                    shortcutIcon("moon.fill")
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.resetMidnightAccessibility(title: editingDate.timeTitle(language: language), language: language))

                Spacer(minLength: 0)

                Button {
                    isShowingTimePicker = true
                } label: {
                    editableValuePill(UntiliaDateFormatting.timeString(editedDate, timeZone: editedTimeZone, language: language))
                        .frame(width: 84, alignment: .trailing)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.timeAccessibility(title: editingDate.timeTitle(language: language), time: UntiliaDateFormatting.timeString(editedDate, timeZone: editedTimeZone, language: language), language: language))
            }
            .frame(width: timeControlActionsWidth)
        }
        .frame(height: 48)
    }

    private func editableValuePill(_ value: String) -> some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.system(size: calendarValueFontSize, weight: .semibold, design: .rounded))
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.system(size: 11, weight: .bold))
                .accessibilityHidden(true)
        }
        .foregroundStyle(.white.opacity(0.92))
        .fixedSize(horizontal: true, vertical: false)
        .padding(.horizontal, 8)
        .frame(height: 34)
        .background(selectedTheme.surfaceHighlight.opacity(0.34), in: Capsule())
    }

    private func shortcutIcon(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(selectedTheme.accent)
            .frame(width: 30, height: 30)
            .background(selectedTheme.surfaceHighlight.opacity(0.42), in: Circle())
            .overlay(Circle().stroke(selectedTheme.accent.opacity(0.22), lineWidth: 1))
    }

    private func settingsControlCaption(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title.uppercased(with: language.locale))
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .tracking(0.3)
                .foregroundStyle(.white.opacity(0.78))
            Text(subtitle)
                .font(.system(size: 9, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.42))
        }
        .lineLimit(1)
        .allowsTightening(true)
        .minimumScaleFactor(0.85)
    }

    private func selectDateForEditing(_ selection: CalendarEditingDate) {
        guard selection != .start || !isStartDateEditingDisabled else { return }

        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            editingDate = selection
            displayedMonth = calendar.startOfMonth(for: editedDate)
        }
    }

    private func updateEditedDate(_ date: Date) {
        guard draftTargetDates.indices.contains(selectedCalendarIndex),
              draftCountdownStartDates.indices.contains(selectedCalendarIndex)
        else { return }

        switch editingDate {
        case .target:
            var updatedTargets = draftTargetDates
            updatedTargets[selectedCalendarIndex] = date
            draftTargetDates = updatedTargets
        case .start:
            var updatedStarts = draftCountdownStartDates
            updatedStarts[selectedCalendarIndex] = date
            draftCountdownStartDates = updatedStarts
        }
    }

    private func resetEditedDateTime() {
        let midnight = calendar.startOfDay(for: editedDate)
        updateEditedDate(midnight)
    }

    private func updateEditedDateTime(hour: Int, minute: Int) {
        let updatedDate = calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: editedDate
        ) ?? editedDate
        updateEditedDate(updatedDate)
    }

    private func setEditedDateToNow() {
        updateEditedDate(Date())
        displayedMonth = calendar.startOfMonth(for: editedDate)
    }

    private func resetCalendarToToday() {
        let today = Date()
        displayedMonth = calendar.startOfMonth(for: today)

        let updatedDate = calendar.date(
            bySettingHour: calendar.component(.hour, from: editedDate),
            minute: calendar.component(.minute, from: editedDate),
            second: 0,
            of: today
        ) ?? today
        updateEditedDate(updatedDate)
        displayedMonth = calendar.startOfMonth(for: editedDate)
    }

    private var selectedTimeZoneCity: String {
        // Ne force pas la construction et le tri de tous les fuseaux (plusieurs
        // centaines d'éléments) à la première ouverture des réglages.
        TargetTimeZoneOption.cityName(for: editedTimeZoneIdentifier)
    }

    private var selectedTimeZoneAbbreviation: String {
        editedTimeZone.abbreviation(for: editedDate) ?? "UTC"
    }

    private func resetEditedTimeZoneToCurrent() {
        updateEditedDateTimeZone(to: TimeZone.autoupdatingCurrent.identifier)
    }

    private func updateEditedDateTimeZone(to identifier: String) {
        guard draftTargetDates.indices.contains(selectedCalendarIndex),
              draftTargetTimeZoneIdentifiers.indices.contains(selectedCalendarIndex),
              draftCountdownStartDates.indices.contains(selectedCalendarIndex),
              draftCountdownStartTimeZoneIdentifiers.indices.contains(selectedCalendarIndex),
              let newTimeZone = TimeZone(identifier: identifier)
        else { return }

        // Le changement de fuseau conserve ce que l’utilisateur a saisi
        // (jour et heure civile), puis le réinterprète dans le nouveau fuseau.
        let oldCalendar = calendar
        let editedComponents = oldCalendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: editedDate
        )
        var newCalendar = Calendar.autoupdatingCurrent
        newCalendar.locale = language.locale
        newCalendar.firstWeekday = 2
        newCalendar.timeZone = newTimeZone

        let reinterpretedDate = newCalendar.date(from: editedComponents) ?? editedDate

        switch editingDate {
        case .target:
            var updatedTargets = draftTargetDates
            updatedTargets[selectedCalendarIndex] = reinterpretedDate
            draftTargetDates = updatedTargets

            var updatedTimeZones = draftTargetTimeZoneIdentifiers
            updatedTimeZones[selectedCalendarIndex] = identifier
            draftTargetTimeZoneIdentifiers = updatedTimeZones
        case .start:
            var updatedStarts = draftCountdownStartDates
            updatedStarts[selectedCalendarIndex] = reinterpretedDate
            draftCountdownStartDates = updatedStarts

            var updatedTimeZones = draftCountdownStartTimeZoneIdentifiers
            updatedTimeZones[selectedCalendarIndex] = identifier
            draftCountdownStartTimeZoneIdentifiers = updatedTimeZones
        }
        displayedMonth = newCalendar.startOfMonth(for: editedDate)
    }

    private func monthButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(selectedTheme.accent)
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
    }
}

private struct CalendarDayButton: View {
    let date: Date
    let calendar: Calendar
    let theme: UntiliaTheme
    let isSelected: Bool
    let height: CGFloat
    let action: () -> Void

    private var dayNumber: String {
        calendar.component(.day, from: date).description
    }

    var body: some View {
        Button(action: action) {
            Text(dayNumber)
                .font(.system(size: 15, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.84))
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(
                    isSelected
                        ? AnyShapeStyle(theme.buttonColor)
                        : AnyShapeStyle(.clear),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
                .shadow(
                    color: isSelected ? theme.buttonColor.opacity(0.22) : .clear,
                    radius: isSelected ? 6 : 0,
                    y: 2
                )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("calendarDay\(dayNumber)")
    }
}

private struct SettingsSheetSizing: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.presentationSizing(.page)
        } else {
            // Page sizing is already UIKit's default on iOS 17.
            content
        }
    }
}

private extension Calendar {
    func startOfMonth(for value: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: value)) ?? value
    }
}

#Preview {
    let store = UntiliaStore()
    SettingsView(store: store)
        .environmentObject(store)
        .environmentObject(AppLanguageStore())
}
