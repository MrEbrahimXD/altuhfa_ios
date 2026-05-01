import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/verse.dart';
import '../../../data/models/section.dart';
import '../../../data/models/sharh_note.dart';
import '../../../data/models/word_timing.dart';
import '../../../data/repositories/tuhfa_repository.dart';
import '../../../core/theme/theme_provider.dart';

final tuhfaRepositoryProvider = Provider<TuhfaRepository>((ref) {
  return TuhfaRepository();
});

final versesProvider = FutureProvider<List<Verse>>((ref) async {
  return ref.read(tuhfaRepositoryProvider).getVerses();
});

final sectionsProvider = FutureProvider<List<Section>>((ref) async {
  return ref.read(tuhfaRepositoryProvider).getSections();
});

final sharhNotesProvider = FutureProvider<List<SharhNote>>((ref) async {
  return ref.read(tuhfaRepositoryProvider).getSharhNotes();
});

final wordTimingsProvider =
    FutureProvider<Map<int, VerseWordTimings>>((ref) async {
  final reciter = ref.watch(themeProvider.select((s) => s.reciter));
  return ref.read(tuhfaRepositoryProvider).getWordTimings(reciter: reciter);
});
