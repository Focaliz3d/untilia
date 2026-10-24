//
//  SettingsSheets.swift
//  Untilia
//

import SwiftUI

struct NameEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageStore: AppLanguageStore
    @FocusState private var isNameFocused: Bool
    @State private var name: String

    let theme: UntiliaTheme
    let onSave: (String) -> Void
    private let maximumLength = UntiliaDefaults.maxTargetNameLength

    init(initialName: String, theme: UntiliaTheme, onSave: @escaping (String) -> Void) {
        self.theme = theme
        self.onSave = onSave
        _name = State(initialValue: initialName)
    }

    private var normalizedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var language: AppLanguage { languageStore.language }

    var body: some View {
        ZStack {
            theme.backgroundGradient[0].ignoresSafeArea()

            Circle()
                .fill(RadialGradient(colors: [theme.buttonColor.opacity(0.16), .clear], center: .center, startRadius: 0, endRadius: 150))
                .frame(width: 300, height: 300)
                .offset(x: 130, y: -170)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: theme.iconName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(theme.buttonColor)
                        .frame(width: 40, height: 40)
                        .background(theme.buttonColor.opacity(0.14), in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.text(.countdownName, language: language))
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(L10n.text(.nameOnCard, language: language))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.54))
                    }
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 9) {
                    HStack {
                        Spacer()
                        Text("\(name.count)/\(maximumLength)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.42))
                    }

                    HStack(spacing: 11) {
                        Image(systemName: "tag")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(theme.buttonColor)
                        TextField(language == .english ? "e.g. Trip to Lisbon" : "Ex. Voyage à Lisbonne", text: $name)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .textInputAutocapitalization(.sentences)
                            .autocorrectionDisabled(false)
                            .focused($isNameFocused)
                            .submitLabel(.done)
                            .onSubmit(save)
                            .accessibilityIdentifier("nameTextField")
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 58)
                    .background(theme.surfaceColor.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(theme.buttonColor.opacity(0.34), lineWidth: 1))
                }
                .padding(.top, 30)

                Color.clear.frame(height: 10)

                Button(action: save) {
                    Text(L10n.text(.confirmName, language: language))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(theme.buttonColor.opacity(0.88), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(.white.opacity(0.18), lineWidth: 1))
                        .shadow(color: theme.buttonColor.opacity(0.14), radius: 11, y: 5)
                }
                .buttonStyle(.plain)
                .disabled(normalizedName.isEmpty)
                .opacity(normalizedName.isEmpty ? 0.45 : 1)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 22)
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.visible)
        .task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard !Task.isCancelled else { return }
            isNameFocused = true
        }
        .onChange(of: name) { _, value in
            guard value.count > maximumLength else { return }
            name = String(value.prefix(maximumLength))
        }
    }

    private func save() {
        guard !normalizedName.isEmpty else { return }
        onSave(normalizedName)
        dismiss()
    }
}

struct MonthYearPickerSheet: View {
    @EnvironmentObject private var languageStore: AppLanguageStore
    @Binding var month: Int
    @Binding var year: Int
    let calendar: Calendar
    let theme: UntiliaTheme

    private var monthNames: [String] {
        calendar.monthSymbols.map { $0.capitalized(with: languageStore.language.locale) }
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: theme.backgroundGradient, startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            MonthYearWheelPicker(
                month: $month,
                year: $year,
                monthNames: monthNames,
                monthLabel: L10n.text(.month, language: languageStore.language),
                yearLabel: L10n.text(.year, language: languageStore.language)
            )
            .tint(theme.accent)
            .frame(height: 180)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(L10n.text(.chooseMonthAndYear, language: languageStore.language))
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.height(230)])
        .presentationDragIndicator(.visible)
    }
}

struct TimePickerSheet: View {
    @EnvironmentObject private var languageStore: AppLanguageStore
    @Binding var hour: Int
    @Binding var minute: Int
    let title: String
    let theme: UntiliaTheme

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(colors: theme.backgroundGradient, startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            HStack(spacing: 0) {
                Picker(L10n.text(.hours, language: languageStore.language), selection: $hour) {
                    ForEach(0..<24, id: \.self) { value in Text(verbatim: String(format: "%02d", value)).tag(value) }
                }
                Picker(L10n.text(.minutes, language: languageStore.language), selection: $minute) {
                    ForEach(0..<60, id: \.self) { value in Text(verbatim: String(format: "%02d", value)).tag(value) }
                }
            }
            .pickerStyle(.wheel)
            .tint(theme.accent)
            .frame(height: 220)
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(title)
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.height(230)])
        .presentationDragIndicator(.visible)
    }
}

struct TimeZonePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageStore: AppLanguageStore
    @State private var searchText = ""
    @State private var options: [TargetTimeZoneOption] = []
    let selectedIdentifier: String
    let targetDate: Date
    let theme: UntiliaTheme
    let onSelect: (String) -> Void

    private var filteredOptions: [TargetTimeZoneOption] {
        guard !searchText.isEmpty else { return options }
        return options.filter { $0.searchableText.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            timeZoneHeader
            timeZoneSearchField

            if options.isEmpty {
                ProgressView()
                    .tint(theme.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredOptions) { option in
                    let timeZone = TimeZone(identifier: option.identifier) ?? .gmt
                    let offset = UntiliaDateFormatting.utcOffsetString(for: timeZone, at: targetDate)
                    Button {
                        onSelect(option.identifier)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(theme.accent)
                                .frame(width: 26, height: 26)
                                .background(theme.accent.opacity(0.14), in: Circle())
                            VStack(alignment: .leading, spacing: 3) {
                                Text(option.city).font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.94))
                                Text(option.identifier == "UTC" ? offset : "\(option.region) · \(offset)")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.56))
                            }
                            Spacer(minLength: 8)
                            if option.identifier == selectedIdentifier {
                                Image(systemName: "checkmark.circle.fill").font(.system(size: 18, weight: .semibold)).foregroundStyle(theme.accent)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(theme.surfaceColor.opacity(0.9))
                    .accessibilityLabel("\(option.city), \(offset)")
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .background(LinearGradient(colors: theme.backgroundGradient, startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(false)
        .task {
            guard options.isEmpty else { return }
            options = await Task.detached(priority: .userInitiated) {
                TargetTimeZoneOption.loadAll()
            }.value
        }
    }

    private var timeZoneHeader: some View {
        HStack(spacing: 12) {
            Text(L10n.text(.timeZone, language: languageStore.language))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.96))

            Spacer()
        }
        .frame(height: 32)
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 2)
    }

    private var timeZoneSearchField: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(theme.accent)

            TextField(L10n.text(.cityOrRegion, language: languageStore.language), text: $searchText)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.94))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityIdentifier("timeZoneSearchField")

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.48))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.text(.close, language: languageStore.language))
            }
        }
        .padding(.horizontal, 13)
        .frame(height: 42)
        .background(theme.surfaceColor.opacity(0.88), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
