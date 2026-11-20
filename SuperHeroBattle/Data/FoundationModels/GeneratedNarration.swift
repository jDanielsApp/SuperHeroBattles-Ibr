import FoundationModels

/// Structured output of the narration generated with Foundation Models.
///
/// Four beats joined into paragraphs after validation: they force the model
/// to present both teams, develop the combat, and proclaim the result
/// exactly as given.
@Generable
struct GeneratedNarration: Sendable {
    @Guide(
        description: """
        Opening beat: present both teams by their team names, heroes and \
        rivalry stakes. Plain prose, 25 to 50 words.
        """
    )
    var opening: String

    @Guide(
        description: """
        Exchange beat: standout moments, signature moves and dazzling \
        displays of ability. Teammates cooperate with each other; \
        confrontations happen only between heroes from different teams. \
        Plain prose, 25 to 50 words.
        """
    )
    var exchange: String

    @Guide(
        description: """
        Climax beat: strategies and decisive teamwork that turn the tide; \
        confrontations only across teams. Plain prose, 25 to 50 words.
        """
    )
    var climax: String

    @Guide(
        description: """
        Verdict beat: resolution proclaiming the winner exactly as given, \
        or the draw with no winner. Plain prose, 20 to 40 words.
        """
    )
    var verdict: String
}
