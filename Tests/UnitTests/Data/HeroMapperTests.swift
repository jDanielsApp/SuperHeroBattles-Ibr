import XCTest
@testable import SuperHeroBattle

final class HeroMapperTests: XCTestCase {
    private let mapper = HeroMapper()

    func testMapsCompletePayload() throws {
        let dto = try decodeHero(TestFixtures.batmanDetailJSON)
        let hero = try XCTUnwrap(mapper.map(dto))

        XCTAssertEqual(hero.id, "70")
        XCTAssertEqual(hero.name, "Batman")
        XCTAssertEqual(hero.fullName, "Bruce Wayne")
        XCTAssertEqual(hero.publisher, "DC Comics")
        XCTAssertEqual(hero.alignment, .unknown)
        XCTAssertNil(hero.biography.alterEgos, "El marcador 'No alter egos found.' debe tratarse como dato ausente")
        XCTAssertEqual(hero.biography.aliases, ["Insider", "Matches Malone"])
        XCTAssertEqual(hero.appearance.gender, "Male")
        XCTAssertEqual(hero.appearance.race, "Human")
        XCTAssertEqual(hero.appearance.height, ["6'2", "188 cm"])
        XCTAssertEqual(hero.appearance.weight, ["210 lb", "95 kg"])
        XCTAssertEqual(hero.appearance.eyeColor, "blue")
        XCTAssertNil(hero.appearance.hairColor)
        XCTAssertEqual(hero.work.occupation, "Businessman")
        XCTAssertEqual(hero.work.base, "Gotham City")
        XCTAssertEqual(hero.connections.groupAffiliation, "Batman Family, Justice League")
        XCTAssertEqual(hero.connections.relatives, "Damian Wayne (son), Dick Grayson (adopted son)")
        XCTAssertEqual(
            hero.imageURL?.absoluteString,
            "https://www.superherodb.com/pictures2/portraits/10/100/639.jpg"
        )
    }

    func testPowerStatsTreatMarkersAndOutOfRangeAsUnknown() throws {
        let dto = try decodeHero(TestFixtures.batmanDetailJSON)
        let hero = try XCTUnwrap(mapper.map(dto))

        XCTAssertEqual(hero.powerStats[.intelligence], 100)
        XCTAssertEqual(hero.powerStats[.strength], 26)
        XCTAssertNil(hero.powerStats[.speed])
        XCTAssertNil(hero.powerStats[.durability])
        XCTAssertNil(hero.powerStats[.power])
        XCTAssertNil(hero.powerStats[.combat])
        XCTAssertEqual(hero.powerStats.knownCount, 2)
    }

    func testMapsHeroWithOnlyRequiredFields() throws {
        let dto = try decodeHero(#"{"response":"success","id":"1","name":"Solo"}"#)
        let hero = try XCTUnwrap(mapper.map(dto))

        XCTAssertEqual(hero.id, "1")
        XCTAssertEqual(hero.name, "Solo")
        XCTAssertTrue(hero.powerStats.isUnknown)
        XCTAssertEqual(hero.biography, .unknown)
        XCTAssertEqual(hero.appearance, .unknown)
        XCTAssertEqual(hero.work, .unknown)
        XCTAssertEqual(hero.connections, .unknown)
        XCTAssertNil(hero.imageURL)
    }

    func testReturnsNilWithoutIdentifierOrName() throws {
        let withoutID = try decodeHero(#"{"response":"success","name":"Nameless"}"#)
        let withoutName = try decodeHero(#"{"response":"success","id":"1"}"#)
        let markerID = try decodeHero(#"{"response":"success","id":"-","name":"Marker"}"#)

        XCTAssertNil(mapper.map(withoutID))
        XCTAssertNil(mapper.map(withoutName))
        XCTAssertNil(mapper.map(markerID))
    }

    func testAlignmentIsCaseInsensitiveAndTolerant() throws {
        let good = try decodeHero(#"{"id":"1","name":"A","biography":{"alignment":"GOOD"}}"#)
        let bad = try decodeHero(#"{"id":"2","name":"B","biography":{"alignment":"bad"}}"#)
        let neutral = try decodeHero(#"{"id":"3","name":"C","biography":{"alignment":"neutral"}}"#)
        let other = try decodeHero(#"{"id":"4","name":"D","biography":{"alignment":"chaotic"}}"#)

        XCTAssertEqual(mapper.map(good)?.alignment, .good)
        XCTAssertEqual(mapper.map(bad)?.alignment, .bad)
        XCTAssertEqual(mapper.map(neutral)?.alignment, .neutral)
        XCTAssertEqual(mapper.map(other)?.alignment, .unknown)
    }

    func testTextMarkersAreTreatedAsUnavailable() {
        XCTAssertNil(HeroMapper.text("-"))
        XCTAssertNil(HeroMapper.text("null"))
        XCTAssertNil(HeroMapper.text("NULL"))
        XCTAssertNil(HeroMapper.text(""))
        XCTAssertNil(HeroMapper.text("   "))
        XCTAssertNil(HeroMapper.text(nil))
        XCTAssertEqual(HeroMapper.text("  Batman  "), "Batman")
        XCTAssertEqual(HeroMapper.text("No alter egos found."), "No alter egos found.")
    }

    func testAlterEgosMarkerIsTreatedAsUnavailable() {
        XCTAssertNil(HeroMapper.alterEgos("No alter egos found."))
        XCTAssertNil(HeroMapper.alterEgos("  no ALTER egos FOUND.  "))
        XCTAssertNil(HeroMapper.alterEgos("-"))
        XCTAssertNil(HeroMapper.alterEgos(nil))
        XCTAssertEqual(HeroMapper.alterEgos("  Matches Malone  "), "Matches Malone")
        XCTAssertEqual(HeroMapper.alterEgos("No alter egos were harmed."), "No alter egos were harmed.")
    }

    func testInvalidImageURLIsIgnored() throws {
        let dto = try decodeHero(#"{"id":"1","name":"A","image":{"url":"not a url"}}"#)

        XCTAssertNil(mapper.map(dto)?.imageURL)
    }

    private func decodeHero(_ json: String) throws -> HeroDTO {
        try JSONDecoder().decode(HeroDTO.self, from: Data(json.utf8))
    }
}
