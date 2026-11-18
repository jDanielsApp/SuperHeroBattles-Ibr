import XCTest
@testable import SuperHeroBattle

final class TeamDraftTests: XCTestCase {
    func testNewDraftHasEmptySlotsForMode() {
        let draft = TeamDraft(side: .teamA, mode: .threeVsThree)

        XCTAssertEqual(draft.slots.count, 3)
        XCTAssertTrue(draft.slots.allSatisfy { $0 == nil })
        XCTAssertFalse(draft.isComplete)
    }

    func testAssignFillsRequestedSlot() throws {
        var draft = TeamDraft(side: .teamA, mode: .twoVsTwo)

        try draft.assign(makeHero(id: "1"), at: 1)

        XCTAssertEqual(draft.hero(in: 1)?.id, "1")
        XCTAssertNil(draft.hero(in: 0))
    }

    func testDuplicateHeroInsideTeamIsRejected() throws {
        var draft = TeamDraft(side: .teamA, mode: .twoVsTwo)
        try draft.assign(makeHero(id: "1"), at: 0)

        XCTAssertThrowsError(try draft.assign(makeHero(id: "1"), at: 1)) { error in
            XCTAssertEqual(error as? TeamValidationError, .duplicateHero)
        }
    }

    func testReplacingHeroKeepsOtherSlots() throws {
        var draft = TeamDraft(side: .teamA, mode: .twoVsTwo)
        try draft.assign(makeHero(id: "1"), at: 0)
        try draft.assign(makeHero(id: "2"), at: 1)

        try draft.assign(makeHero(id: "3"), at: 0)

        XCTAssertEqual(draft.hero(in: 0)?.id, "3")
        XCTAssertEqual(draft.hero(in: 1)?.id, "2")
    }

    func testClearSlotOnlyAffectsThatSlot() throws {
        var draft = TeamDraft(side: .teamA, mode: .twoVsTwo)
        try draft.assign(makeHero(id: "1"), at: 0)
        try draft.assign(makeHero(id: "2"), at: 1)

        try draft.clear(at: 0)

        XCTAssertNil(draft.hero(in: 0))
        XCTAssertEqual(draft.hero(in: 1)?.id, "2")
    }

    func testTeamIsCompleteWhenAllSlotsAreFilled() throws {
        var draft = TeamDraft(side: .teamA, mode: .twoVsTwo)
        try draft.assign(makeHero(id: "1"), at: 0)
        try draft.assign(makeHero(id: "2"), at: 1)

        XCTAssertTrue(draft.isComplete)
    }

    func testInvalidSlotThrows() {
        var draft = TeamDraft(side: .teamA, mode: .oneVsOne)

        XCTAssertThrowsError(try draft.assign(makeHero(id: "1"), at: 4)) { error in
            XCTAssertEqual(error as? TeamValidationError, .invalidSlot)
        }
    }

    private func makeHero(id: String) -> Hero {
        Hero(id: id, name: "Hero \(id)")
    }
}
