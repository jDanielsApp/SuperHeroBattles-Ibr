import Foundation
import XCTest
@testable import SuperHeroBattle

enum TestFixtures {
    static let token = "test-token"
    static let baseURLString = "https://api.test/api"

    static func configuration() throws -> SuperHeroAPIConfiguration {
        try XCTUnwrap(
            SuperHeroAPIConfiguration(
                baseURLString: baseURLString,
                token: token
            )
        )
    }

    static func response(_ json: String, statusCode: Int = 200) -> HTTPResponse {
        HTTPResponse(
            data: Data(json.utf8),
            statusCode: statusCode,
            headers: ["Content-Type": "application/json"]
        )
    }

    static let batmanHeroJSON = """
    {
      "id": "70",
      "name": "Batman",
      "powerstats": {
        "intelligence": "100",
        "strength": "26",
        "speed": "-",
        "durability": "null",
        "power": "150",
        "combat": ""
      },
      "biography": {
        "full-name": "Bruce Wayne",
        "alter-egos": "No alter egos found.",
        "aliases": ["Insider", "-", "Matches Malone"],
        "place-of-birth": "Crest Hill, Bristol Township; Gotham County",
        "first-appearance": "Detective Comics #27",
        "publisher": "DC Comics",
        "alignment": "antihero"
      },
      "appearance": {
        "gender": "Male",
        "race": "Human",
        "height": ["6'2", "188 cm", "-"],
        "weight": ["210 lb", "95 kg"],
        "eye-color": "blue",
        "hair-color": ""
      },
      "work": {
        "occupation": "Businessman",
        "base": "Gotham City"
      },
      "connections": {
        "group-affiliation": "Batman Family, Justice League",
        "relatives": "Damian Wayne (son), Dick Grayson (adopted son)"
      },
      "image": {
        "url": "https://www.superherodb.com/pictures2/portraits/10/100/639.jpg"
      }
    }
    """

    static let batmanSearchJSON = """
    {
      "response": "success",
      "results-for": "batman",
      "results": [\(batmanHeroJSON)]
    }
    """

    static let batmanDetailJSON = """
    {
      "response": "success",
      \(batmanHeroJSON.dropFirst().dropLast())
    }
    """
}
