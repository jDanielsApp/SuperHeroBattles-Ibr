import SwiftUI

/// Team slot card: the occupying hero, or an empty state with actions.
struct TeamSlotView: View {
    let side: TeamSide
    let slot: Int
    let hero: Hero?
    let isBusy: Bool
    let onSelect: () -> Void
    let onRandom: () -> Void
    let onClear: () -> Void

    @Environment(\.locale) private var locale

    private var accent: Color {
        side == .teamA ? TeamPalette.teamA : TeamPalette.teamB
    }

    /// Extra context for VoiceOver: team and slot number.
    private var slotContext: String {
        Self.slotContext(side: side, slot: slot, locale: locale)
    }

    /// Pure and testable: the VoiceOver value in the requested locale.
    /// It must honor the app language, never the system language.
    static func slotContext(side: TeamSide, slot: Int, locale: Locale) -> String {
        let team = L10n.string(
            side == .teamA ? .teamSelectionTeamA : .teamSelectionTeamB,
            locale: locale
        )
        return "\(team), \(slot + 1)"
    }

    var body: some View {
        if let hero {
            occupiedCard(hero)
        } else {
            emptyCard
        }
    }

    // MARK: - Occupied Slot

    private func occupiedCard(_ hero: Hero) -> some View {
        HStack(spacing: 12) {
            HeroImageView(url: hero.imageURL, size: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(hero.name)
                    .font(ComicTypography.headline)
                    .foregroundStyle(ComicPalette.paper)
                    .lineLimit(1)

                if let publisher = hero.publisher {
                    Text(publisher)
                        .font(ComicTypography.caption)
                        .foregroundStyle(accent)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            VStack(spacing: 8) {
                slotButton(
                    titleKey: .teamSelectionSlotReplace,
                    systemImage: "arrow.triangle.2.circlepath",
                    identifier: "team.slot.replace.\(side.rawValue)-\(slot)",
                    action: onSelect
                )

                slotButton(
                    titleKey: .teamSelectionSlotRemove,
                    systemImage: "xmark",
                    identifier: "team.slot.remove.\(side.rawValue)-\(slot)",
                    action: onClear
                )
            }
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(ComicPalette.midnight.opacity(0.88))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accent.opacity(0.75), lineWidth: 2)
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Empty Slot

    private var emptyCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(ComicPalette.paper.opacity(0.06))

                if isBusy {
                    ProgressView()
                        .tint(ComicPalette.yellow)
                } else {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(ComicPalette.paper.opacity(0.4))
                }
            }
            .frame(width: 56, height: 56)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                L10n.text(.teamSelectionSlotEmpty)
                    .font(ComicTypography.headline)
                    .foregroundStyle(ComicPalette.paper.opacity(0.85))

                Text("\(slot + 1)")
                    .font(ComicTypography.caption)
                    .foregroundStyle(ComicPalette.paper.opacity(0.5))
            }

            Spacer(minLength: 8)

            VStack(spacing: 8) {
                slotButton(
                    titleKey: .teamSelectionSlotChoose,
                    systemImage: "magnifyingglass",
                    identifier: "team.slot.choose.\(side.rawValue)-\(slot)",
                    action: onSelect
                )
                .disabled(isBusy)

                slotButton(
                    titleKey: .teamSelectionSlotRandom,
                    systemImage: "dice.fill",
                    identifier: "team.slot.random.\(side.rawValue)-\(slot)",
                    action: onRandom
                )
                .disabled(isBusy)
            }
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(ComicPalette.midnight.opacity(0.88))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    ComicPalette.panelBorder,
                    style: StrokeStyle(lineWidth: 2, dash: [6, 5])
                )
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Actions

    private func slotButton(
        titleKey: LocalizableStringKey,
        systemImage: String,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(L10n.localizedKey(titleKey), systemImage: systemImage)
                .font(ComicTypography.caption)
                .foregroundStyle(ComicPalette.paper)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(accent.opacity(0.28), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
        .accessibilityLabel(L10n.text(titleKey))
        .accessibilityValue(Text(slotContext))
    }
}
