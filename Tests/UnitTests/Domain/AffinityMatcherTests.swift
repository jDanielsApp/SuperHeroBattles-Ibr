import XCTest
@testable import SuperHeroBattle

final class AffinityMatcherTests: XCTestCase {
    func testAffiliationMatchYieldsBonusOfThirtyThree() {
        let heroA = makeHero(id: "1", affiliation: "Justice League")
        let heroB = makeHero(id: "2", affiliation: "Justice League")

        let bonus = AffinityMatcher.bonus(between: heroA, and: heroB)

        XCTAssertEqual(bonus?.bonus, 33)
        XCTAssertEqual(bonus?.matchedAffiliations, ["justice league"])
        XCTAssertEqual(bonus?.matchedRelatives, [])
    }

    func testAffiliationParenthesesAreIgnoredWhenMatching() {
        let heroA = makeHero(id: "1", affiliation: "Avengers (honorary member), Secret Avengers")
        let heroB = makeHero(id: "2", affiliation: "avengers")

        let bonus = AffinityMatcher.bonus(between: heroA, and: heroB)

        XCTAssertEqual(bonus?.matchedAffiliations, ["avengers"])
    }

    func testAffiliationWithoutParenthesesDoesNotMatch() {
        let heroA = makeHero(id: "1", affiliation: "Avengers (prime)")
        let heroB = makeHero(id: "2", affiliation: "prime")

        XCTAssertNil(AffinityMatcher.bonus(between: heroA, and: heroB))
    }

    func testRelativesMatchTeammateName() {
        let thor = makeHero(id: "1", name: "Thor", relatives: "Loki (adoptive brother), Odin (father)")
        let loki = makeHero(id: "2", name: "Loki")

        let bonus = AffinityMatcher.bonus(between: thor, and: loki)

        XCTAssertEqual(bonus?.bonus, 33)
        XCTAssertEqual(bonus?.matchedRelatives, ["loki"])
        XCTAssertEqual(bonus?.matchedAffiliations, [])
    }

    func testRelativesMatchTeammateAlias() {
        let foster = makeHero(id: "1", relatives: "Bruce Wayne (father figure)")
        let batman = makeHero(id: "2", name: "Batman", aliases: ["Bruce Wayne", "The Dark Knight"])

        let bonus = AffinityMatcher.bonus(between: foster, and: batman)

        XCTAssertEqual(bonus?.matchedRelatives, ["bruce wayne"])
    }

    func testRelativesMatchIsCheckedInBothDirections() {
        let superman = makeHero(
            id: "1",
            name: "Superman",
            relatives: "Jor-El (father), Supergirl (cousin)"
        )
        let supergirl = makeHero(id: "2", name: "Kara Zor-El", aliases: ["Supergirl"])

        let bonus = AffinityMatcher.bonus(between: superman, and: supergirl)

        XCTAssertEqual(bonus?.matchedRelatives, ["supergirl"])
    }

    func testSharedRelativeNoLongerYieldsBonus() {
        // La regla antigua de intersección de familiares queda sustituida:
        // compartir familiar entre los dos héroes no otorga feeling.
        let heroA = makeHero(id: "1", relatives: "Alfred Pennyworth (butler)")
        let heroB = makeHero(id: "2", relatives: "Alfred Pennyworth (butler)")

        XCTAssertNil(AffinityMatcher.bonus(between: heroA, and: heroB))
    }

    func testRelativeParenthesesAreStrippedBeforeMatching() {
        let heroA = makeHero(id: "1", relatives: "Loki [adoptive brother]")
        let heroB = makeHero(id: "2", name: "Loki")

        let bonus = AffinityMatcher.bonus(between: heroA, and: heroB)

        XCTAssertEqual(bonus?.matchedRelatives, ["loki"])
    }

    func testSemicolonSeparatedRelativesMatch() {
        let heroA = makeHero(id: "1", relatives: "Jor-El (father); Kal-El; Lara (mother)")
        let heroB = makeHero(id: "2", name: "Kal-El")

        let bonus = AffinityMatcher.bonus(between: heroA, and: heroB)

        XCTAssertEqual(bonus?.matchedRelatives, ["kal-el"])
    }

    func testBothMatchesYieldSingleBonusNeverSixtySix() {
        let heroA = makeHero(
            id: "1",
            name: "Batman",
            aliases: ["Bruce Wayne"],
            affiliation: "Justice League",
            relatives: "Superman (close friend)"
        )
        let heroB = makeHero(
            id: "2",
            name: "Superman",
            affiliation: "Justice League"
        )

        let bonus = AffinityMatcher.bonus(between: heroA, and: heroB)

        XCTAssertEqual(bonus?.bonus, 33)
        XCTAssertEqual(bonus?.matchedAffiliations, ["justice league"])
        XCTAssertEqual(bonus?.matchedRelatives, ["superman"])
    }

    func testNoMatchYieldsNoBonus() {
        let heroA = makeHero(id: "1", affiliation: "Justice League")
        let heroB = makeHero(id: "2", affiliation: "Avengers")

        XCTAssertNil(AffinityMatcher.bonus(between: heroA, and: heroB))
    }

    func testCaseInsensitiveAndWhitespaceTolerant() {
        let heroA = makeHero(id: "1", affiliation: "  Justice League ")
        let heroB = makeHero(id: "2", affiliation: "justice LEAGUE")

        XCTAssertNotNil(AffinityMatcher.bonus(between: heroA, and: heroB))
    }

    func testPartialMatchesAreRejected() {
        let heroA = makeHero(id: "1", affiliation: "Justice League")
        let heroB = makeHero(id: "2", affiliation: "Justice League of America")

        XCTAssertNil(AffinityMatcher.bonus(between: heroA, and: heroB))
    }

    func testCommaSeparatedListsMatchIndividualItems() {
        let heroA = makeHero(id: "1", affiliation: "Justice League, Avengers")
        let heroB = makeHero(id: "2", affiliation: "avengers")

        let bonus = AffinityMatcher.bonus(between: heroA, and: heroB)

        XCTAssertEqual(bonus?.matchedAffiliations, ["avengers"])
    }

    func testUnknownMarkersNeverMatch() {
        let dash = AffinityMatcher.bonus(
            between: makeHero(id: "1", affiliation: "-"),
            and: makeHero(id: "2", affiliation: "-")
        )
        let none = AffinityMatcher.bonus(
            between: makeHero(id: "5", affiliation: "None"),
            and: makeHero(id: "6", affiliation: "none")
        )

        XCTAssertNil(dash)
        XCTAssertNil(none)
    }

    func testUnknownRelativeNeverMatches() {
        // Los marcadores de desconocido se descartan de la lista de
        // familiares antes de comparar con la identidad del compañero.
        let heroA = makeHero(id: "3", relatives: "Unknown")
        let heroB = makeHero(id: "4", name: "unknown", relatives: "unknown")

        XCTAssertNil(AffinityMatcher.bonus(between: heroA, and: heroB))
    }

    func testNilConnectionsYieldNoBonus() {
        let heroA = makeHero(id: "1")
        let heroB = makeHero(id: "2")

        XCTAssertNil(AffinityMatcher.bonus(between: heroA, and: heroB))
    }

    func testEmptyAndWhitespaceOnlyItemsAreDiscarded() {
        let heroA = makeHero(id: "1", affiliation: " ,  ,")
        let heroB = makeHero(id: "2", affiliation: "")

        XCTAssertNil(AffinityMatcher.bonus(between: heroA, and: heroB))
    }

    func testParenthesisOnlyItemsAreDiscarded() {
        let heroA = makeHero(id: "1", relatives: "(wife)")
        let heroB = makeHero(id: "2", name: "Wife")

        XCTAssertNil(AffinityMatcher.bonus(between: heroA, and: heroB))
    }

    private func makeHero(
        id: String,
        name: String? = nil,
        aliases: [String] = [],
        affiliation: String? = nil,
        relatives: String? = nil
    ) -> Hero {
        Hero(
            id: id,
            name: name ?? "Hero \(id)",
            biography: HeroBiography(aliases: aliases),
            connections: HeroConnections(
                groupAffiliation: affiliation,
                relatives: relatives
            )
        )
    }
}
