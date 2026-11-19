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

    func testRelativesMatchYieldsBonusOfThirtyThree() {
        let heroA = makeHero(id: "1", relatives: "Damian Wayne (son)")
        let heroB = makeHero(id: "2", relatives: "Damian Wayne (son)")

        let bonus = AffinityMatcher.bonus(between: heroA, and: heroB)

        XCTAssertEqual(bonus?.bonus, 33)
        XCTAssertEqual(bonus?.matchedRelatives, ["damian wayne (son)"])
    }

    func testBothMatchesYieldSingleBonusNeverSixtySix() {
        let heroA = makeHero(id: "1", affiliation: "Justice League", relatives: "Alfred Pennyworth")
        let heroB = makeHero(id: "2", affiliation: "Justice League", relatives: "Alfred Pennyworth")

        let bonus = AffinityMatcher.bonus(between: heroA, and: heroB)

        XCTAssertEqual(bonus?.bonus, 33)
        XCTAssertEqual(bonus?.matchedAffiliations, ["justice league"])
        XCTAssertEqual(bonus?.matchedRelatives, ["alfred pennyworth"])
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
        let unknown = AffinityMatcher.bonus(
            between: makeHero(id: "3", relatives: "Unknown"),
            and: makeHero(id: "4", relatives: "unknown")
        )
        let none = AffinityMatcher.bonus(
            between: makeHero(id: "5", affiliation: "None"),
            and: makeHero(id: "6", affiliation: "none")
        )

        XCTAssertNil(dash)
        XCTAssertNil(unknown)
        XCTAssertNil(none)
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

    private func makeHero(
        id: String,
        affiliation: String? = nil,
        relatives: String? = nil
    ) -> Hero {
        Hero(
            id: id,
            name: "Hero \(id)",
            connections: HeroConnections(
                groupAffiliation: affiliation,
                relatives: relatives
            )
        )
    }
}
