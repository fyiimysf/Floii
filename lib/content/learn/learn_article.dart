/// One heading-and-body block inside a Learn article.
class LearnSection {
  final String heading;
  final List<String> paragraphs;

  const LearnSection(this.heading, this.paragraphs);
}

/// A label/value row rendered as a compact table above the prose.
class LearnFact {
  final String label;
  final String value;

  const LearnFact(this.label, this.value);
}

/// A complete educational article: the card copy used by the Learn list plus
/// the long-form text of the topic page.
class LearnArticle {
  final String title;
  final String caption;
  final String summary;
  final List<LearnFact>? facts;
  final List<LearnSection> sections;

  const LearnArticle({
    required this.title,
    required this.caption,
    required this.summary,
    this.facts,
    required this.sections,
  });
}
