import Foundation

/// Copia inmutable de un personaje para persistir el historial sin depender de la API.
nonisolated struct HeroSnapshot: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let fullName: String?
    let publisher: String?
    let alignment: HeroAlignment
    let imageURL: URL?

    init(
        id: String,
        name: String,
        fullName: String? = nil,
        publisher: String? = nil,
        alignment: HeroAlignment = .unknown,
        imageURL: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.fullName = fullName
        self.publisher = publisher
        self.alignment = alignment
        self.imageURL = imageURL
    }

    init(hero: Hero) {
        self.init(
            id: hero.id,
            name: hero.name,
            fullName: hero.fullName,
            publisher: hero.publisher,
            alignment: hero.alignment,
            imageURL: hero.imageURL
        )
    }
}
