/// One heading-and-body block inside a legal document.
class LegalSection {
  final String heading;
  final List<String> paragraphs;

  const LegalSection(this.heading, this.paragraphs);
}

/// A legal document — privacy policy or terms & conditions — rendered with the
/// same section styling as a Learn article.
///
/// The title, icon and accent live on the screen (they are interface choices);
/// only the prose lives here.
class LegalDocument {
  final String intro;
  final List<LegalSection> sections;

  const LegalDocument({
    required this.intro,
    required this.sections,
  });
}
