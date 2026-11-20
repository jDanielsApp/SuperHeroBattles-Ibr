import Foundation

/// Translates SuperHeroAPI DTOs into domain entities.
/// The markers `"-"`, `"null"` and `""` are treated as unavailable data;
/// any other text is preserved without reinterpretation.
nonisolated struct HeroMapper: Sendable {
    init() {}

    func map(_ dto: HeroDTO) -> Hero? {
        guard let id = Self.text(dto.id),
              let name = Self.text(dto.name) else {
            return nil
        }

        return Hero(
            id: id,
            name: name,
            biography: biography(from: dto.biography),
            appearance: appearance(from: dto.appearance),
            work: work(from: dto.work),
            connections: connections(from: dto.connections),
            powerStats: powerStats(from: dto.powerstats),
            imageURL: imageURL(from: dto.image)
        )
    }

    private func biography(from dto: BiographyDTO?) -> HeroBiography {
        guard let dto else { return .unknown }

        return HeroBiography(
            fullName: Self.text(dto.fullName),
            alterEgos: Self.text(dto.alterEgos),
            aliases: (dto.aliases ?? []).compactMap(Self.text),
            placeOfBirth: Self.text(dto.placeOfBirth),
            firstAppearance: Self.text(dto.firstAppearance),
            publisher: Self.text(dto.publisher),
            alignment: Self.alignment(dto.alignment)
        )
    }

    private func appearance(from dto: AppearanceDTO?) -> HeroAppearance {
        guard let dto else { return .unknown }

        return HeroAppearance(
            gender: Self.text(dto.gender),
            race: Self.text(dto.race),
            height: (dto.height ?? []).compactMap(Self.text),
            weight: (dto.weight ?? []).compactMap(Self.text),
            eyeColor: Self.text(dto.eyeColor),
            hairColor: Self.text(dto.hairColor)
        )
    }

    private func work(from dto: WorkDTO?) -> HeroWork {
        guard let dto else { return .unknown }

        return HeroWork(
            occupation: Self.text(dto.occupation),
            base: Self.text(dto.base)
        )
    }

    private func connections(from dto: ConnectionsDTO?) -> HeroConnections {
        guard let dto else { return .unknown }

        return HeroConnections(
            groupAffiliation: Self.text(dto.groupAffiliation),
            relatives: Self.text(dto.relatives)
        )
    }

    private func powerStats(from dto: PowerStatsDTO?) -> PowerStats {
        guard let dto else { return .unknown }

        return PowerStats(
            intelligence: Self.integer(dto.intelligence),
            strength: Self.integer(dto.strength),
            speed: Self.integer(dto.speed),
            durability: Self.integer(dto.durability),
            power: Self.integer(dto.power),
            combat: Self.integer(dto.combat)
        )
    }

    private func imageURL(from dto: ImageDTO?) -> URL? {
        guard let rawURL = Self.text(dto?.url),
              let url = URL(string: rawURL),
              url.host != nil else {
            return nil
        }
        return url
    }

    /// Returns `nil` for markers that indicate missing data.
    static func text(_ raw: String?) -> String? {
        guard let raw else { return nil }

        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        switch trimmed.lowercased() {
        case "-", "null", "n/a":
            return nil
        default:
            return trimmed
        }
    }

    static func integer(_ raw: String?) -> Int? {
        guard let text = text(raw) else { return nil }
        return Int(text)
    }

    static func alignment(_ raw: String?) -> HeroAlignment {
        guard let text = text(raw)?.lowercased() else { return .unknown }

        switch text {
        case "good":
            return .good
        case "bad":
            return .bad
        case "neutral":
            return .neutral
        default:
            return .unknown
        }
    }
}
