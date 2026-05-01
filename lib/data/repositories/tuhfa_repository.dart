import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/verse.dart';
import '../models/section.dart';
import '../models/sharh_note.dart';
import '../models/word_timing.dart';

class TuhfaRepository {
  List<Verse>? _verses;
  List<Section>? _sections;
  List<SharhNote>? _sharhNotes;
  final Map<int, Map<int, VerseWordTimings>> _wordTimingsByReciter = {};
  String? _title;
  String? _author;
  String? _annotator;

  Future<void> _loadData() async {
    if (_verses != null) return;
    final jsonString = await rootBundle.loadString('assets/data/tuhfa.json');
    final data = json.decode(jsonString) as Map<String, dynamic>;

    _title = data['title'] as String;
    _author = data['author'] as String;
    _annotator = data['annotator'] as String;

    _sections = (data['sections'] as List)
        .map((s) => Section.fromJson(s as Map<String, dynamic>))
        .toList();

    _verses = (data['verses'] as List)
        .map((v) => Verse.fromJson(v as Map<String, dynamic>))
        .toList();

    _sharhNotes = (data['sharhNotes'] as List)
        .map((n) => SharhNote.fromJson(n as Map<String, dynamic>))
        .toList();
  }

  Future<List<Verse>> getVerses() async {
    await _loadData();
    return _verses!;
  }

  Future<List<Section>> getSections() async {
    await _loadData();
    return _sections!;
  }

  Future<List<SharhNote>> getSharhNotes() async {
    await _loadData();
    return _sharhNotes!;
  }

  Future<String> getTitle() async {
    await _loadData();
    return _title!;
  }

  Future<String> getAuthor() async {
    await _loadData();
    return _author!;
  }

  Future<String> getAnnotator() async {
    await _loadData();
    return _annotator!;
  }

  Future<Map<int, VerseWordTimings>> getWordTimings({int reciter = 1}) async {
    final cached = _wordTimingsByReciter[reciter];
    if (cached != null) return cached;

    final path = reciter == 4
        ? 'assets/data/word_timings_reciter4.json'
        : 'assets/data/word_timings.json';

    try {
      final jsonString = await rootBundle.loadString(path);
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final parsed = data.map((key, value) => MapEntry(int.parse(key),
          VerseWordTimings.fromJson(value as Map<String, dynamic>)));
      _wordTimingsByReciter[reciter] = parsed;
      return parsed;
    } catch (_) {
      if (reciter != 1) {
        return getWordTimings(reciter: 1);
      }
      rethrow;
    }
  }

  Future<List<SharhNote>> getSharhForVerse(int verseId) async {
    await _loadData();
    return _sharhNotes!.where((n) => n.verseIds.contains(verseId)).toList();
  }

  Future<Section?> getSectionForVerse(int verseId) async {
    await _loadData();
    try {
      return _sections!.firstWhere(
        (s) => verseId >= s.verseStart && verseId <= s.verseEnd,
      );
    } catch (_) {
      return null;
    }
  }
}
