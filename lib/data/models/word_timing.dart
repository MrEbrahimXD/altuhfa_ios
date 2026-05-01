class WordTiming {
  final String word;
  final int startMs;
  final int endMs;

  const WordTiming({
    required this.word,
    required this.startMs,
    required this.endMs,
  });

  factory WordTiming.fromJson(Map<String, dynamic> json) {
    return WordTiming(
      word: json['word'] as String,
      startMs: json['startMs'] as int,
      endMs: json['endMs'] as int,
    );
  }
}

class VerseWordTimings {
  final int clipDurationMs;
  final int sadrWordCount;
  final List<WordTiming> words;

  const VerseWordTimings({
    required this.clipDurationMs,
    required this.sadrWordCount,
    required this.words,
  });

  factory VerseWordTimings.fromJson(Map<String, dynamic> json) {
    return VerseWordTimings(
      clipDurationMs: json['clipDurationMs'] as int,
      sadrWordCount: json['sadrWordCount'] as int,
      words: (json['words'] as List)
          .map((w) => WordTiming.fromJson(w as Map<String, dynamic>))
          .toList(),
    );
  }
}
