import SwiftUI

struct HelpGuideView: View {
    let theme: UntiliaTheme
    let language: AppLanguage

    private func copy(_ french: String, _ english: String) -> String {
        language == .english ? english : french
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(copy("BIEN DÉMARRER", "GETTING STARTED"))
                    .font(.caption.weight(.bold))
                    .tracking(1.8)
                    .foregroundStyle(theme.accent)
                Text(copy("Vos repères, en un instant.", "Your moments, at a glance."))
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .accessibilityAddTraits(.isHeader)
                Text(copy("Trois décomptes indépendants, pour les moments à venir comme pour ceux qui comptent déjà.", "Three independent countdowns, for the moments ahead and the ones that already matter."))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                Text(copy("Guide en français", "Guide in English"))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))
            }
            .accessibilityIdentifier("helpGuideIntro")

            section(number: "01", title: copy("L’écran principal", "The main screen"), subtitle: copy("Tout se lit. Tout se touche.", "A clear view. A simple touch.")) {
                row(icon: "hand.draw", title: copy("Choisir un décompte", "Choose a countdown"), text: copy("Balayez vers la gauche ou la droite : après la dernière carte, vous retrouvez la première, et inversement. Touchez une carte pour l’afficher directement ; son contour indique le décompte actif.", "Swipe left or right: the last card leads back to the first, and vice versa. Tap a card to jump straight to it; its outline marks the active countdown."))
                row(icon: "hand.tap", title: copy("Toucher le cercle", "Tap the circle"), text: copy("Chaque toucher change l’unité principale : années, mois, semaines, jours, heures, minutes ou secondes. Seules les unités principales adaptées à la durée sont proposées. En dessous, les mois, semaines et jours à zéro sont masqués ; les champs horaires inférieurs restent toujours complets, même à zéro. Chaque carte mémorise sa propre unité, même après fermeture de l’app.", "Each tap changes the main unit: years, months, weeks, days, hours, minutes or seconds. Only main units that fit the duration are offered. Below, zero months, weeks and days are hidden; the lower clock fields always stay complete, even at zero. Each card remembers its own unit, even after you close the app."))
                row(icon: "clock", title: copy("Choisir le fuseau de l’horloge", "Choose the clock’s time zone"), text: copy("En haut à gauche, la date et l’heure courantes s’affichent avec les secondes. Touchez cette zone pour parcourir le fuseau local, celui de l’échéance puis celui du départ, uniquement s’ils sont différents : jusqu’à trois fuseaux, sans doublons. Les dates du décompte ne sont pas modifiées.", "The top-left corner shows the current date and time, including seconds. Tap this area to cycle through local, deadline and start time zones when they differ: up to three zones, with no duplicates. Your countdown dates stay unchanged."))
                row(icon: "eye.slash", title: copy("Afficher ou masquer date et heure", "Show or hide date and time"), text: copy("Après le dernier fuseau, un toucher masque toute l’horloge : date, heure et fuseau sont remplacés par un discret point coloré. Touchez le point ou la zone habituelle de l’horloge pour retrouver l’heure locale. Ce choix est mémorisé ; le cercle continue son décompte normalement.", "After the last time zone, one more tap hides the entire clock: a discreet coloured dot replaces the date, time and zone. Tap the dot or the usual clock area to restore local time. Your choice is remembered; the circle keeps counting normally."))
                row(icon: "chart.bar.fill", title: copy("Suivre la progression", "Track your progress"), text: copy("Le pourcentage situe l’instant présent entre le départ et l’échéance. Si le départ est encore à venir, la progression reste à zéro et le décompte conserve sa durée initiale jusqu’au départ.", "The percentage shows where you are between the start and the deadline. If the start is still in the future, progress stays at zero and the countdown keeps its initial duration until the start."))

                note(icon: "checkmark.circle.fill", title: copy("Et quand la date est passée ?", "What happens when the date has passed?"), text: copy("« Il reste » devient automatiquement « Il s’est écoulé », accompagné de « depuis le ». Le cercle reste coloré, sans point mobile, et la progression laisse place à « Échéance atteinte ». Vous pouvez toujours changer d’unité.", "“Time left” automatically becomes “Time elapsed”, followed by “since”. The circle stays coloured, without a moving dot, and progress is replaced by “Deadline reached”. You can still change the unit."))
            }

            section(number: "02", title: copy("Les paramètres", "Settings"), subtitle: copy("Une carte, une date, votre rythme.", "Your card. Your date. Your pace.")) {
                row(icon: "gearshape.fill", title: copy("1. Choisir la carte à modifier", "1. Choose a card to edit"), text: copy("Ouvrez la roue dentée, puis touchez l’une des trois cartes en haut. Touchez ensuite la ligne portant son nom pour la renommer.", "Tap the gear, then choose one of the three cards at the top. Tap the row showing its name to rename it."))
                row(icon: "calendar", title: copy("2. Choisir la date à régler", "2. Choose a date to edit"), text: copy("Touchez « Échéance » ou « Départ », puis un jour du calendrier. Les chevrons changent de mois ; la pastille du mois ouvre les roues du mois et de l’année, de 1900 à 2500.", "Tap “Deadline” or “Start”, then a day in the calendar. Use the arrows to change months, or tap the month pill to open the month and year wheels, from 1900 to 2500."))
                row(icon: "clock", title: copy("3. Régler l’heure et le fuseau", "3. Set the time and time zone"), text: copy("Touchez l’heure pour ouvrir le sélecteur. Touchez « Fuseau horaire » ou le décalage UTC pour rechercher une ville ou une région. Départ et échéance peuvent avoir des fuseaux différents.", "Tap the time to open the picker. Tap “Time zone” or the UTC offset to search for a city or region. The start and deadline can use different time zones."))
                row(icon: "checkmark.circle", title: copy("4. Enregistrer et fermer", "4. Save and close"), text: copy("Touchez « Enregistrer les modifications » pour chaque carte modifiée. « Date validée » signifie qu’aucun changement n’est en attente pour cette carte. Pour fermer la feuille, touchez le trait en haut ou faites-le glisser vers le bas. Si des modifications restent en attente, vous pouvez rester pour les enregistrer ou confirmer leur abandon.", "Tap “Save changes” for each card you edit. “Date confirmed” means that card has no unsaved changes. To close the sheet, tap the handle at the top or drag it down. If changes are still pending, you can stay to save them or confirm you want to discard them."))

                note(icon: "lock.fill", title: copy("Le départ est grisé ? C’est normal.", "Is the start greyed out? That’s normal."), text: copy("Si l’échéance est passée, le départ n’est plus utilisé ni modifiable. Sa valeur est conservée : elle réapparaît si vous choisissez à nouveau une échéance future.", "Once the deadline has passed, the start is no longer used and cannot be edited. Its value is kept: it reappears if you choose a future deadline again."))
            }

            section(number: "03", title: copy("Les petits raccourcis", "Handy shortcuts"), subtitle: copy("Les bons gestes, au bon endroit.", "Small touches. Useful shortcuts.")) {
                row(icon: "calendar.badge.clock", title: copy("Revenir à aujourd’hui ou à maintenant", "Jump to today or now"), text: copy("Dans l’en-tête du calendrier, cette icône choisit aujourd’hui en gardant l’heure réglée. Sur la ligne de l’heure, elle choisit la date et l’heure actuelles.", "In the calendar header, this icon selects today while keeping the time you set. On the time row, it selects the current date and time."))
                row(icon: "moon.fill", title: copy("Passer à minuit", "Set the time to midnight"), text: copy("La lune, à côté de l’heure, règle celle-ci sur 00:00 sans changer le jour.", "The moon beside the time sets it to 00:00 without changing the day."))
                row(icon: "location.circle.fill", title: copy("Retrouver le fuseau de l’appareil", "Use your device’s time zone"), text: copy("La flèche sur la ligne « Fuseau horaire » rétablit le fuseau local. Changer de fuseau conserve le jour et l’heure saisis : c’est l’instant correspondant qui change.", "The arrow on the “Time zone” row restores your local time zone. Changing time zones keeps the date and time you entered: it changes the actual moment they refer to."))
                row(icon: "globe", title: copy("Changer la langue", "Change the language"), text: copy("Dans les paramètres, touchez le globe puis le drapeau français ou anglais. Ce choix est mémorisé pour les prochains lancements.", "In Settings, tap the globe, then the French or British flag. Your choice is remembered the next time you open the app."))
                row(icon: "questionmark", title: copy("L’aide, dans la langue de votre choix", "Help in your preferred language"), text: copy("Le point d’interrogation ouvre ce guide depuis l’écran principal ou les paramètres. Le globe de l’aide change uniquement la langue du guide, sans modifier celle de l’app. À chaque nouvelle ouverture, l’aide reprend la langue de l’app. Son titre défile avec le contenu ; le trait en haut permet de la fermer.", "The question mark opens this guide from the main screen or Settings. The guide’s globe changes only the help language, not the app language. Each new visit starts in the app’s language. The heading scrolls with the content; use the handle at the top to close the guide."))
            }

            Label {
                Text(copy("Vos réglages restent sur votre appareil. Les décomptes fonctionnent hors ligne, sans compte.", "Your settings stay on your device. Countdowns work offline, with no account needed."))
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "iphone")
            }
            .font(.footnote)
            .foregroundStyle(.white.opacity(0.55))
            .padding(.horizontal, 4)
        }
        .foregroundStyle(.white.opacity(0.94))
        .accessibilityIdentifier("helpGuide")
    }

    private func section<Content: View>(number: String, title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top, spacing: 14) {
                Text(number)
                    .font(.system(.subheadline, design: .monospaced, weight: .bold))
                    .foregroundStyle(theme.accent)
                    .padding(10)
                    .background(theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .accessibilityAddTraits(.isHeader)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            content()
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(.white.opacity(0.09), lineWidth: 1))
    }

    private func row(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(theme.accent)
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 7) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func note(icon: String, title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(theme.accent)
            Text(text)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.65))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }
}
