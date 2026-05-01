import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/section.dart';

final memorizationProvider =
    StateNotifierProvider<MemorizationNotifier, MemorizationState>((ref) {
  return MemorizationNotifier();
});

class MemorizationState {
  final Set<int> memorizedVerses;
  final Set<int> celebratedSectionIds;
  final bool isLoaded;

  const MemorizationState({
    this.memorizedVerses = const <int>{},
    this.celebratedSectionIds = const <int>{},
    this.isLoaded = false,
  });

  MemorizationState copyWith({
    Set<int>? memorizedVerses,
    Set<int>? celebratedSectionIds,
    bool? isLoaded,
  }) {
    return MemorizationState(
      memorizedVerses:
          Set<int>.unmodifiable(memorizedVerses ?? this.memorizedVerses),
      celebratedSectionIds: Set<int>.unmodifiable(
        celebratedSectionIds ?? this.celebratedSectionIds,
      ),
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  bool isVerseMemorized(int verseNumber) {
    return memorizedVerses.contains(verseNumber);
  }

  int get memorizedCount => memorizedVerses.length;

  double memorizationRatio(int totalVerses) {
    if (totalVerses <= 0) return 0;
    return memorizedVerses.length / totalVerses;
  }

  int completedSectionsCount(List<Section> sections) {
    int completed = 0;
    for (final section in sections) {
      if (_isSectionComplete(section, memorizedVerses)) {
        completed++;
      }
    }
    return completed;
  }

  static bool _isSectionComplete(Section section, Set<int> memorized) {
    for (int verse = section.verseStart; verse <= section.verseEnd; verse++) {
      if (!memorized.contains(verse)) {
        return false;
      }
    }
    return true;
  }
}

class MemorizationToggleResult {
  final bool isMemorized;
  final Section? completedSection;

  const MemorizationToggleResult({
    required this.isMemorized,
    this.completedSection,
  });
}

class MemorizationNotifier extends StateNotifier<MemorizationState> {
  MemorizationNotifier() : super(const MemorizationState()) {
    _loadingFuture = _load();
  }

  static const _memorizedVersesKey = 'memorization_verses';
  static const _celebratedSectionsKey = 'memorization_celebrated_sections';

  bool _hasLoaded = false;
  Future<void>? _loadingFuture;

  Future<void> _ensureLoaded() async {
    if (_hasLoaded) return;
    _loadingFuture ??= _load();
    await _loadingFuture;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final memorized = _decodeIntSet(prefs.getStringList(_memorizedVersesKey));
    final celebrated =
        _decodeIntSet(prefs.getStringList(_celebratedSectionsKey));

    _hasLoaded = true;
    state = state.copyWith(
      memorizedVerses: memorized,
      celebratedSectionIds: celebrated,
      isLoaded: true,
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _memorizedVersesKey,
      _encodeIntSet(state.memorizedVerses),
    );
    await prefs.setStringList(
      _celebratedSectionsKey,
      _encodeIntSet(state.celebratedSectionIds),
    );
  }

  Set<int> _decodeIntSet(List<String>? rawValues) {
    if (rawValues == null || rawValues.isEmpty) return <int>{};
    return rawValues.map(int.tryParse).whereType<int>().toSet();
  }

  List<String> _encodeIntSet(Set<int> values) {
    final sorted = values.toList()..sort();
    return sorted.map((e) => e.toString()).toList();
  }

  Section? _sectionForVerse(int verseNumber, List<Section> sections) {
    for (final section in sections) {
      if (verseNumber >= section.verseStart &&
          verseNumber <= section.verseEnd) {
        return section;
      }
    }
    return null;
  }

  bool _isSectionComplete(Section section, Set<int> memorized) {
    return MemorizationState._isSectionComplete(section, memorized);
  }

  Future<MemorizationToggleResult> toggleVerse({
    required int verseNumber,
    required List<Section> sections,
  }) async {
    await _ensureLoaded();

    final updatedMemorized = Set<int>.from(state.memorizedVerses);
    final updatedCelebrated = Set<int>.from(state.celebratedSectionIds);

    final wasMemorized = updatedMemorized.contains(verseNumber);
    Section? completedSection;

    if (wasMemorized) {
      updatedMemorized.remove(verseNumber);
    } else {
      updatedMemorized.add(verseNumber);

      final section = _sectionForVerse(verseNumber, sections);
      if (section != null &&
          _isSectionComplete(section, updatedMemorized) &&
          !updatedCelebrated.contains(section.id)) {
        completedSection = section;
        updatedCelebrated.add(section.id);
      }
    }

    state = state.copyWith(
      memorizedVerses: updatedMemorized,
      celebratedSectionIds: updatedCelebrated,
      isLoaded: true,
    );

    await _save();

    return MemorizationToggleResult(
      isMemorized: !wasMemorized,
      completedSection: completedSection,
    );
  }
}
