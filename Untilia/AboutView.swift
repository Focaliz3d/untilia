import SwiftUI

struct AboutView: View {
    @EnvironmentObject private var languageStore: AppLanguageStore
    @Environment(\.dismiss) private var dismiss
    @State private var helpLanguage: AppLanguage?
    @State private var isShowingLanguagePicker = false
    let theme: UntiliaTheme

    private var language: AppLanguage { helpLanguage ?? languageStore.language }

    static func supportURL(language: AppLanguage) -> URL {
        URL(string: "https://focaliz3d.github.io/untilia/#\(language.rawValue)")!
    }

    static func versionLabel(info: [String: Any]) -> String? {
        guard let version = info["CFBundleShortVersionString"] as? String,
            let build = info["CFBundleVersion"] as? String
        else { return nil }
        return "v\(version) (build \(build))"
    }

    var body: some View {
        VStack(spacing: 0) {
            dismissHandle
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    VStack(alignment: .leading, spacing: 14) {
                        Text(L10n.text(.aboutTagline, language: language))
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundStyle(theme.accent)
                        Text(L10n.text(.aboutDescription, language: language))
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.65))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HelpGuideView(theme: theme, language: language)

                    Link(destination: Self.supportURL(language: language)) {
                        HStack(spacing: 16) {
                            Image(systemName: "hand.raised.fill")
                                .font(.title2)
                                .foregroundStyle(theme.accent)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(L10n.text(.supportAndPrivacy, language: language))
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundStyle(.white)
                                Text(L10n.text(.supportAndPrivacyDescription, language: language))
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.65))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.up.right")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(theme.accent)
                        }
                        .padding(22)
                        .background(theme.accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 24))
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(theme.accent.opacity(0.18), lineWidth: 1))
                    }
                    .accessibilityIdentifier("supportPrivacyLink")
                }
                .frame(maxWidth: 620, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity)
            }
            .clipped()
            .accessibilityIdentifier("helpScrollView")
        }
        .background {
            LinearGradient(colors: [theme.backgroundGradient[0], .untiliaInk], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
        }
        .tint(theme.accent)
        .environment(\.locale, language.locale)
        .preferredColorScheme(.dark)
        .presentationDragIndicator(.hidden)
        .accessibilityAction(.escape) { dismiss() }
        .onAppear {
            helpLanguage = languageStore.language
            isShowingLanguagePicker = false
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "hourglass")
                .font(.system(size: 23, weight: .medium))
                .foregroundStyle(theme.accent)
                .frame(width: 48, height: 48)
                .background(theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                .accessibilityHidden(true)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("Untilia")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.94))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if let version = Self.versionLabel(info: Bundle.main.infoDictionary ?? [:]) {
                    Text(version)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                        .fixedSize()
                        .accessibilityIdentifier("appVersionLabel")
                }
            }

            Spacer(minLength: 0)
            HStack(spacing: 6) {
                if isShowingLanguagePicker {
                    ForEach(AppLanguage.allCases) { option in
                        Button {
                            helpLanguage = option
                            isShowingLanguagePicker = false
                        } label: {
                            Text(option.flag)
                                .font(.system(size: 16))
                                .frame(width: 28, height: 28)
                                .background(theme.accent.opacity(option == language ? 0.22 : 0.07), in: Circle())
                        }
                        .accessibilityLabel(option.nativeName)
                        .accessibilityIdentifier("helpLanguage-\(option.rawValue)")
                        .accessibilityAddTraits(option == language ? .isSelected : [])
                    }
                }

                Button {
                    isShowingLanguagePicker.toggle()
                } label: {
                    Image(systemName: "globe")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92))
                        .frame(width: 48, height: 48)
                        .background(theme.accent.opacity(isShowingLanguagePicker ? 0.2 : 0.18), in: Circle())
                        .overlay(Circle().stroke(isShowingLanguagePicker ? theme.accent.opacity(0.7) : .white.opacity(0.14), lineWidth: 1))
                        .compositingGroup()
                        .shadow(color: theme.accent.opacity(0.18), radius: 14, y: 6)
                }
                .accessibilityLabel(L10n.text(.language, language: language))
                .accessibilityValue(language.nativeName)
                .accessibilityIdentifier("helpLanguageButton")
            }
            .buttonStyle(.plain)
            .fixedSize(horizontal: true, vertical: false)
        }
        .frame(maxWidth: .infinity)
    }

    private var dismissHandle: some View {
        // Le grabber système est masqué en hauteur compacte :
        // ce repère reste visible et utilisable dans les deux orientations.
        Button {
            dismiss()
        } label: {
            Capsule()
                .fill(.white.opacity(0.3))
                .frame(width: 44, height: 5)
                .frame(width: 80, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.text(.close, language: language))
        .accessibilityIdentifier("closeAboutButton")
        .frame(maxWidth: .infinity)
        .highPriorityGesture(
            DragGesture(minimumDistance: 12).onEnded { gesture in
                if gesture.translation.height > 44,
                    gesture.translation.height > abs(gesture.translation.width)
                {
                    dismiss()
                }
            }
        )
    }
}
