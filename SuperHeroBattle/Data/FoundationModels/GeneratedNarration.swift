import FoundationModels

/// Salida estructurada de la narración generada con Foundation Models.
@Generable
struct GeneratedNarration: Sendable {
    @Guide(
        description: """
        Cinematic narration of the battle in the requested language, \
        between 80 and 160 words, in 3 to 5 short paragraphs of plain prose. \
        No headings, no lists, no quotation marks.
        """
    )
    var text: String
}
