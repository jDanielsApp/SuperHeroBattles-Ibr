import SwiftUI

/// Detalle local de un héroe del catálogo.
struct HeroDetailView: View {
    let hero: Hero

    var body: some View {
        ZStack {
            ComicBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    powerStatsSection
                    biographySection
                    appearanceSection
                    workSection
                    connectionsSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle(hero.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(spacing: 16) {
            HeroImageView(url: hero.imageURL, size: 110)

            VStack(alignment: .leading, spacing: 6) {
                Text(hero.name)
                    .font(ComicTypography.title)
                    .foregroundStyle(ComicPalette.paper)
                    .fixedSize(horizontal: false, vertical: true)

                if let fullName = hero.fullName {
                    Text(fullName)
                        .font(ComicTypography.body)
                        .foregroundStyle(ComicPalette.paper.opacity(0.7))
                }

                if let publisher = hero.publisher {
                    Text(publisher)
                        .font(ComicTypography.caption)
                        .foregroundStyle(ComicPalette.yellow)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(ComicPalette.ink.opacity(0.8), in: Capsule())
                }
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var powerStatsSection: some View {
        section(title: .guideDetailPowerStats) {
            PowerStatsView(stats: hero.powerStats)
        }
    }

    private var biographySection: some View {
        section(title: .guideDetailBiography) {
            VStack(alignment: .leading, spacing: 8) {
                detailRow(.guideDetailAlterEgos, hero.biography.alterEgos)
                detailRow(
                    .guideDetailAliases,
                    hero.biography.aliases.isEmpty ? nil : hero.biography.aliases.joined(separator: ", ")
                )
                detailRow(.guideDetailPlaceOfBirth, hero.biography.placeOfBirth)
                detailRow(.guideDetailFirstAppearance, hero.biography.firstAppearance)
                detailRow(.guideDetailAlignment, L10n.string(hero.alignment.localizedKey))
            }
        }
    }

    private var appearanceSection: some View {
        section(title: .guideDetailAppearance) {
            VStack(alignment: .leading, spacing: 8) {
                detailRow(.guideDetailGender, hero.appearance.gender)
                detailRow(.guideDetailRace, hero.appearance.race)
                detailRow(.guideDetailHeight, joined(hero.appearance.height))
                detailRow(.guideDetailWeight, joined(hero.appearance.weight))
                detailRow(.guideDetailEyeColor, hero.appearance.eyeColor)
                detailRow(.guideDetailHairColor, hero.appearance.hairColor)
            }
        }
    }

    private var workSection: some View {
        section(title: .guideDetailWork) {
            VStack(alignment: .leading, spacing: 8) {
                detailRow(.guideDetailOccupation, hero.work.occupation)
                detailRow(.guideDetailBase, hero.work.base)
            }
        }
    }

    private var connectionsSection: some View {
        section(title: .guideDetailConnections) {
            VStack(alignment: .leading, spacing: 8) {
                detailRow(.guideDetailAffiliations, hero.connections.groupAffiliation)
                detailRow(.guideDetailRelatives, hero.connections.relatives)
            }
        }
    }

    private func section<Content: View>(
        title: LocalizableStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            L10n.text(title)
                .font(ComicTypography.headline)
                .foregroundStyle(ComicPalette.yellow)

            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(ComicPalette.midnight.opacity(0.86))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ComicPalette.panelBorder, lineWidth: 2)
        }
    }

    @ViewBuilder
    private func detailRow(_ title: LocalizableStringKey, _ value: String?) -> some View {
        if let value, !value.isEmpty {
            HStack(alignment: .top, spacing: 8) {
                L10n.text(title)
                    .font(ComicTypography.caption)
                    .foregroundStyle(ComicPalette.paper.opacity(0.6))

                Spacer(minLength: 8)

                Text(value)
                    .font(ComicTypography.body)
                    .foregroundStyle(ComicPalette.paper)
                    .multilineTextAlignment(.trailing)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private func joined(_ values: [String]) -> String? {
        let cleaned = values.filter { !$0.isEmpty }
        return cleaned.isEmpty ? nil : cleaned.joined(separator: " / ")
    }
}

private extension HeroAlignment {
    var localizedKey: LocalizableStringKey {
        switch self {
        case .good: .alignmentGood
        case .bad: .alignmentBad
        case .neutral: .alignmentNeutral
        case .unknown: .alignmentUnknown
        }
    }
}
