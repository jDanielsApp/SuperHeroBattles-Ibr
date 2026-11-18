import XCTest
@testable import SuperHeroBattle

final class FilterHeroesUseCaseTests: XCTestCase {
    private let useCase = FilterHeroesUseCase()

    func testEmptyFilterReturnsEveryHero() {
        let result = useCase.execute(heroes: heroes, filter: HeroFilter())

        XCTAssertEqual(result.map(\.id), ["1", "2", "3"])
    }

    func testSearchMatchesNameAndAliasesCaseInsensitively() {
        let byName = useCase.execute(heroes: heroes, filter: HeroFilter(query: "SUPERMAN"))
        let byAlias = useCase.execute(heroes: heroes, filter: HeroFilter(query: "dark knight"))

        XCTAssertEqual(byName.map(\.id), ["1"])
        XCTAssertEqual(byAlias.map(\.id), ["2"])
    }

    func testSearchMatchesFullName() {
        let result = useCase.execute(heroes: heroes, filter: HeroFilter(query: "bruce wayne"))

        XCTAssertEqual(result.map(\.id), ["2"])
    }

    func testCombinedPublisherAndGenderFilters() {
        let result = useCase.execute(
            heroes: heroes,
            filter: HeroFilter(query: "", publisher: "DC Comics", gender: "male")
        )

        XCTAssertEqual(result.map(\.id), ["1", "2"])
    }

    func testPublisherFilterDoesNotUsePartialMatches() {
        let result = useCase.execute(heroes: heroes, filter: HeroFilter(publisher: "DC"))

        XCTAssertTrue(result.isEmpty)
    }

    private var heroes: [Hero] {
        [
            Hero(
                id: "1",
                name: "Superman",
                biography: HeroBiography(
                    fullName: "Clark Kent",
                    aliases: ["Man of Steel"],
                    publisher: "DC Comics",
                    alignment: .good
                ),
                appearance: HeroAppearance(gender: "Male")
            ),
            Hero(
                id: "2",
                name: "Batman",
                biography: HeroBiography(
                    fullName: "Bruce Wayne",
                    aliases: ["Dark Knight"],
                    publisher: "DC Comics",
                    alignment: .good
                ),
                appearance: HeroAppearance(gender: "Male")
            ),
            Hero(
                id: "3",
                name: "Wonder Woman",
                biography: HeroBiography(
                    fullName: "Diana Prince",
                    aliases: ["Amazon Princess"],
                    publisher: "DC Comics",
                    alignment: .good
                ),
                appearance: HeroAppearance(gender: "Female")
            ),
        ]
    }
}
