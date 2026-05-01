class Verse {
  final int id;
  final int number;
  final int sectionId;
  final String sadr;
  final String ajuz;

  const Verse({
    required this.id,
    required this.number,
    required this.sectionId,
    required this.sadr,
    required this.ajuz,
  });

  String get fullText => '$sadr ... $ajuz';

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      id: json['id'] as int,
      number: json['number'] as int,
      sectionId: json['sectionId'] as int,
      sadr: json['sadr'] as String,
      ajuz: json['ajuz'] as String,
    );
  }
}
