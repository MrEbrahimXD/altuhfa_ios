class Section {
  final int id;
  final String title;
  final int verseStart;
  final int verseEnd;

  const Section({
    required this.id,
    required this.title,
    required this.verseStart,
    required this.verseEnd,
  });

  int get verseCount => verseEnd - verseStart + 1;

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['id'] as int,
      title: json['title'] as String,
      verseStart: json['verseStart'] as int,
      verseEnd: json['verseEnd'] as int,
    );
  }
}
