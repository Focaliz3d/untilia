import SwiftUI

struct CountdownProgressCard: View {
    let progress: CGFloat
    let startDate: Date
    let startTimeZone: TimeZone
    let targetDate: Date
    let targetTimeZone: TimeZone
    let isElapsed: Bool
    let isCompact: Bool
    let theme: UntiliaTheme
    let verticalPadding: CGFloat
    let language: AppLanguage

    private var startDateText: String {
        UntiliaDateFormatting.dateString(startDate, timeZone: startTimeZone, abbreviatedMonth: true, language: language)
    }

    private var startTimeText: String {
        UntiliaDateFormatting.timeString(startDate, timeZone: startTimeZone, language: language)
    }

    private var startTimeZoneText: String {
        UntiliaDateFormatting.timeZoneAbbreviationOrUTCOffset(for: startTimeZone, at: startDate)
    }

    private var targetDateText: String {
        UntiliaDateFormatting.dateString(targetDate, timeZone: targetTimeZone, abbreviatedMonth: true, language: language)
    }

    private var targetTimeText: String {
        UntiliaDateFormatting.timeString(targetDate, timeZone: targetTimeZone, language: language)
    }

    private var targetTimeZoneText: String {
        UntiliaDateFormatting.timeZoneAbbreviationOrUTCOffset(for: targetTimeZone, at: targetDate)
    }

    var body: some View {
        Group {
            if isCompact {
                compactProgressContent
                    .opacity(isElapsed ? 0 : 1)
                    .accessibilityHidden(isElapsed)
                    .overlay {
                        if isElapsed { compactElapsedContent }
                    }
            } else {
                // L'overlay ne participe pas à la mesure : les deux états ont
                // exactement la hauteur naturelle de la carte de progression.
                progressContent
                    .opacity(isElapsed ? 0 : 1)
                    .accessibilityHidden(isElapsed)
                    .overlay {
                        if isElapsed { elapsedContent }
                    }
            }
        }
        .padding(.horizontal, isCompact ? 14 : 20)
        .padding(.vertical, verticalPadding)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("countdownProgressCard")
        .accessibilityLabel(
            isElapsed
                ? L10n.elapsedAccessibility(date: targetDateText, time: targetTimeText, timeZone: targetTimeZoneText, language: language)
                : L10n.progressAccessibility(date: startDateText, time: startTimeText, timeZone: startTimeZoneText, percent: Int(progress * 100), language: language)
        )
    }

    private var progressContent: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(L10n.text(.progressSince, language: language))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.58))

                    HStack(spacing: 5) {
                        Text(startDateText)
                            .foregroundStyle(.white.opacity(0.96))
                        separator
                        Text(startTimeText)
                            .foregroundStyle(theme.accent)
                            .monospacedDigit()
                        separator
                        Text(startTimeZoneText)
                            .foregroundStyle(theme.accent.opacity(0.88))
                    }
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                }

                Spacer()
                Text("\(Int(progress * 100)) %")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }

            GeometryReader { geometry in
                let filledWidth = progress > 0 ? max(12, geometry.size.width * progress) : 0

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.12))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: theme.ringColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width)
                        .mask(alignment: .leading) {
                            Capsule()
                                .frame(width: filledWidth)
                        }
                        .shadow(color: theme.accent.opacity(0.35), radius: 8)
                }
            }
            .frame(height: 12)
        }
    }

    private var elapsedContent: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: theme.ringColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: theme.accent.opacity(0.4), radius: 10)

                Circle()
                    .stroke(.white.opacity(0.32), lineWidth: 1)

                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 5) {
                Text(L10n.text(.deadlineReached, language: language))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.15)
                    .foregroundStyle(.white.opacity(0.72))

                HStack(spacing: 5) {
                    Text(targetDateText)
                        .foregroundStyle(.white.opacity(0.96))
                    separator
                    Text(targetTimeText)
                        .foregroundStyle(theme.accent)
                        .monospacedDigit()
                    separator
                    Text(targetTimeZoneText)
                        .foregroundStyle(theme.accent.opacity(0.88))
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 8)

            Text(L10n.text(.done, language: language))
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(theme.accent)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(theme.accent.opacity(0.12), in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(theme.accent.opacity(0.3), lineWidth: 1)
                )
        }
    }

    private var compactProgressContent: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(L10n.text(.progress, language: language))
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.58))

                Spacer()

                Text("\(Int(progress * 100)) %")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.94))
            }

            HStack(spacing: 4) {
                Text(L10n.text(.since, language: language))
                    .foregroundStyle(.white.opacity(0.5))
                Text(startDateText)
                    .foregroundStyle(.white.opacity(0.88))
                separator
                Text(startTimeText)
                    .foregroundStyle(theme.accent)
                    .monospacedDigit()
                separator
                Text(startTimeZoneText)
                    .foregroundStyle(theme.accent.opacity(0.82))
            }
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.75)

            GeometryReader { geometry in
                let filledWidth = progress > 0 ? max(10, geometry.size.width * progress) : 0

                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.12))
                    Capsule()
                        .fill(LinearGradient(colors: theme.ringColors, startPoint: .leading, endPoint: .trailing))
                        .frame(width: filledWidth)
                }
            }
            .frame(height: 7)
        }
    }

    private var compactElapsedContent: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(
                    LinearGradient(
                        colors: theme.ringColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Circle()
                )
                .shadow(color: theme.accent.opacity(0.38), radius: 7)

            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.text(.deadlineReached, language: language))
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(0.9)
                    .foregroundStyle(.white.opacity(0.68))

                HStack(spacing: 4) {
                    Text(targetDateText)
                        .foregroundStyle(.white.opacity(0.94))
                    separator
                    Text(targetTimeText)
                        .foregroundStyle(theme.accent)
                        .monospacedDigit()
                    separator
                    Text(targetTimeZoneText)
                        .foregroundStyle(theme.accent.opacity(0.82))
                }
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 4)

            Text(L10n.text(.done, language: language))
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .tracking(0.7)
                .foregroundStyle(theme.accent)
        }
    }

    private var separator: some View {
        Text("·")
            .foregroundStyle(.white.opacity(0.42))
    }
}
