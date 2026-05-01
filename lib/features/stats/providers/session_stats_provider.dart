import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sessionStatsProvider =
    StateNotifierProvider<SessionStatsNotifier, SessionStats>((ref) {
  return SessionStatsNotifier();
});

class SessionStats {
  final int versesListened;
  final int totalSessions;
  final int totalSecondsListened;

  const SessionStats({
    this.versesListened = 0,
    this.totalSessions = 0,
    this.totalSecondsListened = 0,
  });

  SessionStats copyWith({
    int? versesListened,
    int? totalSessions,
    int? totalSecondsListened,
  }) {
    return SessionStats(
      versesListened: versesListened ?? this.versesListened,
      totalSessions: totalSessions ?? this.totalSessions,
      totalSecondsListened: totalSecondsListened ?? this.totalSecondsListened,
    );
  }

  String get formattedTime {
    final hours = totalSecondsListened ~/ 3600;
    final minutes = (totalSecondsListened % 3600) ~/ 60;
    if (hours > 0) return '$hoursس $minutesد';
    return '$minutesد';
  }
}

class SessionStatsNotifier extends StateNotifier<SessionStats> {
  SessionStatsNotifier() : super(const SessionStats()) {
    _load();
  }

  bool _sessionCounted = false;
  int _listeningRemainderMs = 0;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = SessionStats(
      versesListened: prefs.getInt('stats_versesListened') ?? 0,
      totalSessions: prefs.getInt('stats_totalSessions') ?? 0,
      totalSecondsListened: prefs.getInt('stats_totalSeconds') ?? 0,
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('stats_versesListened', state.versesListened);
    await prefs.setInt('stats_totalSessions', state.totalSessions);
    await prefs.setInt('stats_totalSeconds', state.totalSecondsListened);
  }

  void recordPlaybackStarted() {
    if (_sessionCounted) return;
    _sessionCounted = true;
    state = state.copyWith(totalSessions: state.totalSessions + 1);
    _save();
  }

  void recordPlaybackStopped() {
    _sessionCounted = false;
  }

  void recordVerseListened() {
    state = state.copyWith(versesListened: state.versesListened + 1);
    _save();
  }

  void addListeningTime(int seconds) {
    if (seconds <= 0) return;
    state = state.copyWith(
      totalSecondsListened: state.totalSecondsListened + seconds,
    );
    _save();
  }

  void addListeningMillis(int millis) {
    if (millis <= 0) return;
    _listeningRemainderMs += millis;
    final wholeSeconds = _listeningRemainderMs ~/ 1000;
    if (wholeSeconds <= 0) return;

    _listeningRemainderMs -= wholeSeconds * 1000;
    addListeningTime(wholeSeconds);
  }
}
