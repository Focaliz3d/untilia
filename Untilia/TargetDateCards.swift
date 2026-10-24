import SwiftUI

struct TargetDateCards: View {
    let dates: [Date]
    let names: [String]
    let timeZoneIdentifiers: [String]
    let selectedIndex: Int
    let cardHeight: CGFloat
    let isVertical: Bool
    let language: AppLanguage
    let onSelect: (Int) -> Void

    var body: some View {
        Group {
            if isVertical {
                VStack(spacing: 8) {
                    cards
                }
            } else {
                HStack(spacing: 10) {
                    cards
                }
            }
        }
        .frame(maxWidth: .infinity)
        .transaction { transaction in
            transaction.animation = nil
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("targetDateCards")
    }

    @ViewBuilder
    private var cards: some View {
            ForEach(0..<min(dates.count, UntiliaTheme.allCases.count), id: \.self) { index in
                TargetDateCard(
                    index: index,
                    date: dates[index],
                    name: names[safe: index] ?? L10n.fallbackDate(index + 1, language: language),
                    timeZone: TimeZone(identifier: timeZoneIdentifiers[safe: index] ?? "") ?? .autoupdatingCurrent,
                    theme: UntiliaTheme.allCases[index],
                    isSelected: index == selectedIndex,
                    height: cardHeight,
                    isCompact: isVertical,
                    language: language,
                    action: { onSelect(index) }
                )
                .frame(maxWidth: .infinity)
            }
    }
}

private struct TargetDateCard: View {
    let index: Int
    let date: Date
    let name: String
    let timeZone: TimeZone
    let theme: UntiliaTheme
    let isSelected: Bool
    let height: CGFloat
    let isCompact: Bool
    let language: AppLanguage
    let action: () -> Void

    private var formattedDate: String {
        UntiliaDateFormatting.dateString(date, timeZone: timeZone, abbreviatedMonth: true, language: language)
    }

    private var formattedTime: String {
        UntiliaDateFormatting.timeString(date, timeZone: timeZone, language: language)
    }

    private var timeZoneText: String {
        UntiliaDateFormatting.timeZoneAbbreviationOrUTCOffset(for: timeZone, at: date)
    }

    var body: some View {
        Button(action: action) {
            Group {
                if isCompact {
                    compactCardContent
                } else {
                    regularCardContent
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: height)
            .background(
                LinearGradient(
                    colors: [
                        theme.surfaceHighlight.opacity(0.46),
                        theme.surfaceColor.opacity(0.72)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? theme.accent.opacity(0.88) : .white.opacity(0.12), lineWidth: isSelected ? 1.5 : 1)
            )
            .compositingGroup()
            .shadow(color: .black.opacity(0.12), radius: 8, y: 6)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel(L10n.cardAccessibility(name: name, date: formattedDate, time: formattedTime, timeZone: timeZoneText, theme: L10n.themeTitle(theme, language: language), language: language))
        .accessibilityHint(isSelected ? L10n.text(.displayedDate, language: language) : L10n.text(.showDate, language: language))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("targetDateCard\(index)")
    }

    private var regularCardContent: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Spacer(minLength: 0)

                    Image(systemName: theme.iconName)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(theme.accent)

                    Spacer(minLength: 0)
                }

                Spacer(minLength: 0)

                VStack(spacing: 2) {
                    Text(formattedDate)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.62))

                    timeAndTimeZone(fontSize: 11)
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .center)
            }

            Text(name)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.96))
                .lineLimit(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 13)
    }

    private var compactCardContent: some View {
        HStack(spacing: 11) {
            Image(systemName: theme.iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.accent)
                .frame(width: 32, height: 32)
                .background(theme.accent.opacity(0.12), in: Circle())

            Text(name)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.96))
                .lineLimit(1)

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedDate)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)

                timeAndTimeZone(fontSize: 11)
            }
        }
        .padding(.horizontal, 13)
    }

    private func timeAndTimeZone(fontSize: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(formattedTime)
                .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.accent)

            Text("·")
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.42))

            Text(timeZoneText)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(theme.accent.opacity(0.78))
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
}
