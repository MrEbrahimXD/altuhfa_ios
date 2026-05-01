class SharhNote {
  final int id;
  final String noteNumber;
  final List<int> verseIds;
  final String text;

  const SharhNote({
    required this.id,
    required this.noteNumber,
    required this.verseIds,
    required this.text,
  });

  factory SharhNote.fromJson(Map<String, dynamic> json) {
    return SharhNote(
      id: json['id'] as int,
      noteNumber: json['noteNumber'] as String,
      verseIds: (json['verseIds'] as List).cast<int>(),
      text: json['text'] as String,
    );
  }
}
