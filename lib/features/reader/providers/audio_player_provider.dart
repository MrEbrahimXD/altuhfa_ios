import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../data/models/section.dart';

final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
  return AudioPlayerNotifier();
});

class AudioPlayerState {
  final bool isPlaying;
  final int? currentVerseIndex;
  final double speed;
  final bool isLoaded;
  final Duration position;
  final Duration? duration;
  final bool repeatEnabled;
  final int repeatStart;
  final int repeatEnd;
  final int repeatCount; // 0 = infinite
  final int currentRepeatRound; // 0-based, increments after each full pass
  final bool playingSectionTitle; // true when a section title clip is playing

  const AudioPlayerState({
    this.isPlaying = false,
    this.currentVerseIndex,
    this.speed = 1.0,
    this.isLoaded = false,
    this.position = Duration.zero,
    this.duration,
    this.repeatEnabled = false,
    this.repeatStart = 0,
    this.repeatEnd = 60,
    this.repeatCount = 0,
    this.currentRepeatRound = 0,
    this.playingSectionTitle = false,
  });

  AudioPlayerState copyWith({
    bool? isPlaying,
    int? currentVerseIndex,
    double? speed,
    bool? isLoaded,
    Duration? position,
    Duration? duration,
    bool? repeatEnabled,
    int? repeatStart,
    int? repeatEnd,
    int? repeatCount,
    int? currentRepeatRound,
    bool? playingSectionTitle,
  }) {
    return AudioPlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      currentVerseIndex: currentVerseIndex ?? this.currentVerseIndex,
      speed: speed ?? this.speed,
      isLoaded: isLoaded ?? this.isLoaded,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      repeatEnabled: repeatEnabled ?? this.repeatEnabled,
      repeatStart: repeatStart ?? this.repeatStart,
      repeatEnd: repeatEnd ?? this.repeatEnd,
      repeatCount: repeatCount ?? this.repeatCount,
      currentRepeatRound: currentRepeatRound ?? this.currentRepeatRound,
      playingSectionTitle: playingSectionTitle ?? this.playingSectionTitle,
    );
  }
}

class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  final AudioPlayer _player = AudioPlayer();
  ConcatenatingAudioSource? _playlist;
  int _totalVerses = 61;

  /// Maps each playlist index to a 0-based verse index, or -1 for section titles.
  List<int> _playlistToVerse = [];

  /// Maps each 0-based verse index to its playlist index.
  Map<int, int> _verseToPlaylist = {};

  bool _includeSectionTitles = false;
  int _reciter = 1;

  // Stored for rebuilding the full playlist after repeat ends
  List<Section>? _sections;

  static const _reciterNames = {
    1: 'الشيخ عبدالقادر العثمان',
    2: 'الشيخ سعد الغامدي',
    3: 'الشيخ أحمد النفيس',
    4: 'الشيخ ياسر سلامة',
  };

  String _sectionTitleForVerse(int verseNumber) {
    if (_sections == null) return '';
    for (final s in _sections!) {
      if (verseNumber >= s.verseStart && verseNumber <= s.verseEnd) {
        return s.title;
      }
    }
    return '';
  }

  MediaItem _mediaItemForVerse(int verseNumber) {
    return MediaItem(
      id: '$verseNumber',
      title: 'البيت $verseNumber',
      album: 'التحفة',
      artist: _reciterNames[_reciter] ?? '',
    );
  }

  MediaItem _mediaItemForSection(int sectionId, String title) {
    return MediaItem(
      id: 'section_$sectionId',
      title: title,
      album: 'التحفة',
      artist: _reciterNames[_reciter] ?? '',
    );
  }

  String _audioDirForReciter(int reciter) {
    return reciter == 4
        ? 'assets/audio/reciter4'
        : reciter == 3
            ? 'assets/audio/reciter3'
            : reciter == 2
                ? 'assets/audio/reciter2'
                : 'assets/audio';
  }

  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String> _resolveVerseAssetPath({
    required String audioDir,
    required int reciter,
    required int verseNumber,
  }) async {
    final mp3Path = '$audioDir/$verseNumber.mp3';
    if (reciter != 4) return mp3Path;

    if (await _assetExists(mp3Path)) return mp3Path;

    final m4aPath = '$audioDir/$verseNumber.m4a';
    if (await _assetExists(m4aPath)) return m4aPath;

    return mp3Path;
  }

  Future<String?> _resolveSectionTitleAssetPath({
    required String audioDir,
    required int reciter,
    required int sectionId,
  }) async {
    final mp3Path = '$audioDir/section_$sectionId.mp3';
    if (await _assetExists(mp3Path)) return mp3Path;

    if (reciter == 4) {
      final m4aPath = '$audioDir/section_$sectionId.m4a';
      if (await _assetExists(m4aPath)) return m4aPath;
    }

    return null;
  }

  AudioPlayerNotifier() : super(const AudioPlayerState()) {
    _init();
  }

  void _init() {
    _player.currentIndexStream.listen((index) {
      if (index != null && mounted) {
        if (_repeatEnabled) {
          final mappedVerse = _repeatStart + index;
          state = state.copyWith(
              currentVerseIndex: mappedVerse, playingSectionTitle: false);
          return;
        }

        final verseIdx =
            (index < _playlistToVerse.length) ? _playlistToVerse[index] : index;
        if (verseIdx >= 0) {
          state = state.copyWith(
              currentVerseIndex: verseIdx, playingSectionTitle: false);
        } else {
          // Section title is playing — find the next verse to highlight
          int nextVerse = -1;
          for (int i = index + 1; i < _playlistToVerse.length; i++) {
            if (_playlistToVerse[i] >= 0) {
              nextVerse = _playlistToVerse[i];
              break;
            }
          }
          if (nextVerse >= 0) {
            state = state.copyWith(
                currentVerseIndex: nextVerse, playingSectionTitle: true);
          }
        }
      }
    });

    _player.playerStateStream.listen((playerState) {
      if (!mounted) return;
      state = state.copyWith(isPlaying: playerState.playing);
      if (playerState.processingState == ProcessingState.completed) {
        if (_repeatEnabled) {
          _onRepeatRoundComplete();
        } else {
          state = state.copyWith(isPlaying: false);
        }
      }
    });

    _player.positionStream.listen((pos) {
      if (mounted) {
        state = state.copyWith(position: pos);
      }
    });

    _player.durationStream.listen((dur) {
      if (mounted && dur != null) {
        state = state.copyWith(duration: dur);
      }
    });
  }

  // Repeat state
  bool _repeatEnabled = false;
  int _repeatStart = 0;
  int _repeatEnd = 60;
  int _repeatCount = 0; // 0 = infinite
  int _currentRepeatRound = 0;

  bool get repeatEnabled => _repeatEnabled;
  int get repeatStart => _repeatStart;
  int get repeatEnd => _repeatEnd;
  int get repeatCount => _repeatCount;
  int get currentRepeatRound => _currentRepeatRound;

  void _onRepeatRoundComplete() {
    _currentRepeatRound++;
    if (_repeatCount > 0 && _currentRepeatRound >= _repeatCount) {
      // All rounds done — schedule restore outside the stream callback
      state = state.copyWith(
        isPlaying: false,
        currentRepeatRound: _currentRepeatRound,
      );
      Future.microtask(() => _restoreFullPlaylist());
    } else {
      // More rounds — restart the mini playlist from the beginning
      state = state.copyWith(currentRepeatRound: _currentRepeatRound);
      Future.microtask(() async {
        try {
          await _player.seek(Duration.zero, index: 0);
          _player.play().catchError((e) {
            debugPrint('Repeat restart error: $e');
          });
        } catch (e) {
          debugPrint('Repeat seek error: $e');
        }
      });
    }
  }

  Future<void> loadPlaylist(int verseCount,
      {List<Section>? sections,
      bool includeSectionTitles = false,
      int reciter = 1}) async {
    // Remember current verse so we can resume after a reload (reciter switch, repeat end)
    final savedVerseIndex = state.isLoaded ? state.currentVerseIndex : null;

    _totalVerses = verseCount;
    _includeSectionTitles = includeSectionTitles;
    _sections = sections;
    _reciter = reciter;
    _playlistToVerse = [];
    _verseToPlaylist = {};

    final audioDir = _audioDirForReciter(reciter);
    final sources = <AudioSource>[];

    if (includeSectionTitles && sections != null) {
      for (final section in sections) {
        if (section.id >= 2) {
          final titlePath = await _resolveSectionTitleAssetPath(
            audioDir: audioDir,
            reciter: reciter,
            sectionId: section.id,
          );
          if (titlePath != null) {
            sources.add(AudioSource.asset(
              titlePath,
              tag: _mediaItemForSection(section.id, section.title),
            ));
            _playlistToVerse.add(-1);
          }
        }
        for (int n = section.verseStart; n <= section.verseEnd; n++) {
          final verseIdx = n - 1;
          _verseToPlaylist[verseIdx] = sources.length;
          final versePath = await _resolveVerseAssetPath(
            audioDir: audioDir,
            reciter: reciter,
            verseNumber: n,
          );
          sources.add(AudioSource.asset(
            versePath,
            tag: _mediaItemForVerse(n),
          ));
          _playlistToVerse.add(verseIdx);
        }
      }
    } else {
      for (int i = 0; i < verseCount; i++) {
        _verseToPlaylist[i] = i;
        final versePath = await _resolveVerseAssetPath(
          audioDir: audioDir,
          reciter: reciter,
          verseNumber: i + 1,
        );
        sources.add(AudioSource.asset(
          versePath,
          tag: _mediaItemForVerse(i + 1),
        ));
        _playlistToVerse.add(i);
      }
    }

    _playlist = ConcatenatingAudioSource(children: sources);
    try {
      // Determine which playlist index to start at
      int startPlaylistIdx = 0;
      int startVerseIdx =
          _playlistToVerse.isNotEmpty && _playlistToVerse[0] >= 0
              ? _playlistToVerse[0]
              : 0;
      if (savedVerseIndex != null && savedVerseIndex > 0) {
        final pi = _verseToPlaylist[savedVerseIndex];
        if (pi != null) {
          startPlaylistIdx = pi;
          startVerseIdx = savedVerseIndex;
        }
      }

      await _player.setAudioSource(_playlist!, initialIndex: startPlaylistIdx);
      await _player.setLoopMode(LoopMode.off);
      await _player.setSpeed(state.speed);
      state = state.copyWith(isLoaded: true, currentVerseIndex: startVerseIdx);
    } catch (e) {
      debugPrint('Audio load error (expected if files missing): $e');
      state = state.copyWith(isLoaded: false, currentVerseIndex: 0);
    }
  }

  Future<void> play() async {
    try {
      await _player.play();
    } catch (e) {
      debugPrint('Play error: $e');
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seekToVerse(int index) async {
    if (index < 0 || index >= _totalVerses) return;

    // During repeat, seek within the mini-playlist
    if (_repeatEnabled) {
      final miniIdx = index - _repeatStart;
      if (miniIdx < 0 || miniIdx > _repeatEnd - _repeatStart) return;
      try {
        await _player.seek(Duration.zero, index: miniIdx);
        state = state.copyWith(currentVerseIndex: index);
      } catch (e) {
        debugPrint('Seek error: $e');
      }
      return;
    }

    var playlistIdx = _verseToPlaylist[index] ?? index;
    try {
      await _player.seek(Duration.zero, index: playlistIdx);
      state =
          state.copyWith(currentVerseIndex: index, playingSectionTitle: false);
    } catch (e) {
      debugPrint('Seek error: $e');
    }
  }

  Future<void> nextVerse() async {
    final current = state.currentVerseIndex ?? 0;
    if (current < _totalVerses - 1) {
      await seekToVerse(current + 1);
    }
  }

  Future<void> previousVerse() async {
    final current = state.currentVerseIndex ?? 0;
    if (current > 0) {
      await seekToVerse(current - 1);
    }
  }

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    state = state.copyWith(speed: speed);
  }

  /// Builds a mini-playlist with only the repeat-range verses.
  /// Uses LoopMode.off; round completion detected via ProcessingState.completed.
  Future<void> setRepeatRange(int start, int end, int count) async {
    _repeatStart = start;
    _repeatEnd = end;
    _repeatCount = count;
    _currentRepeatRound = 0;
    _repeatEnabled = true;

    final audioDir = _audioDirForReciter(_reciter);
    final sources = <AudioSource>[];
    for (int i = start; i <= end; i++) {
      final versePath = await _resolveVerseAssetPath(
        audioDir: audioDir,
        reciter: _reciter,
        verseNumber: i + 1,
      );
      sources.add(AudioSource.asset(
        versePath,
        tag: _mediaItemForVerse(i + 1),
      ));
    }

    final miniPlaylist = ConcatenatingAudioSource(children: sources);
    try {
      await _player.setAudioSource(miniPlaylist, initialIndex: 0);
      await _player.setLoopMode(LoopMode.off);
      await _player.setSpeed(state.speed);
      state = state.copyWith(
        repeatEnabled: true,
        repeatStart: start,
        repeatEnd: end,
        repeatCount: count,
        currentRepeatRound: 0,
        currentVerseIndex: start,
      );
    } catch (e) {
      debugPrint('Repeat playlist error: $e');
    }
  }

  Future<void> disableRepeat() async {
    _repeatEnabled = false;
    _currentRepeatRound = 0;
    state = state.copyWith(
        repeatEnabled: false, currentRepeatRound: 0, repeatCount: 0);
    await _restoreFullPlaylist();
  }

  Future<void> _restoreFullPlaylist() async {
    _repeatEnabled = false;
    _currentRepeatRound = 0;
    state = state.copyWith(
        repeatEnabled: false, currentRepeatRound: 0, repeatCount: 0);
    await loadPlaylist(
      _totalVerses,
      sections: _sections,
      includeSectionTitles: _includeSectionTitles,
      reciter: _reciter,
    );
  }

  Future<void> playFromVerse(int index) async {
    await seekToVerse(index);
    await play();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
