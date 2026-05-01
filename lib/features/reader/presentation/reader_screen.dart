import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/arabic_utils.dart';
import '../../../data/models/sharh_note.dart';
import '../../../data/models/verse.dart';
import '../../../data/models/section.dart';
import '../../../features/memorization/providers/memorization_provider.dart';
import '../providers/tuhfa_providers.dart';
import '../providers/audio_player_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../features/stats/providers/session_stats_provider.dart';
import 'widgets/section_header.dart';
import 'widgets/verse_tile.dart';
import 'widgets/audio_controls_bar.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _positionsListener =
      ItemPositionsListener.create();
  int? _lastScrolledVerse;
  late final SessionStatsNotifier _statsNotifier;

  @override
  void initState() {
    super.initState();
    _statsNotifier = ref.read(sessionStatsProvider.notifier);
  }

  @override
  void dispose() {
    _statsNotifier.recordPlaybackStopped();
    super.dispose();
  }

  void _scrollToVerse(int verseIndex) {
    if (_lastScrolledVerse == verseIndex) return;
    _lastScrolledVerse = verseIndex;

    if (_scrollController.isAttached) {
      _scrollController.scrollTo(
        index: verseIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final versesAsync = ref.watch(versesProvider);
    final sectionsAsync = ref.watch(sectionsProvider);
    final sharhAsync = ref.watch(sharhNotesProvider);

    // Auto-scroll when verse changes during playback + track stats
    ref.listen<AudioPlayerState>(audioPlayerProvider, (prev, next) {
      final wasPlaying = prev?.isPlaying ?? false;

      if (!wasPlaying && next.isPlaying) {
        _statsNotifier.recordPlaybackStarted();
      } else if (wasPlaying && !next.isPlaying) {
        _statsNotifier.recordPlaybackStopped();
      }

      if (wasPlaying && next.isPlaying) {
        final deltaMs =
            next.position.inMilliseconds - prev!.position.inMilliseconds;
        // Skip large jumps from manual seeks to avoid inflated listening time.
        if (deltaMs > 0 && deltaMs <= 4000) {
          _statsNotifier.addListeningMillis(deltaMs);
        }
      }

      if (next.isPlaying && next.currentVerseIndex != null) {
        // Track verse listened
        if (prev?.currentVerseIndex != next.currentVerseIndex) {
          _statsNotifier.recordVerseListened();
        }
        // We need to find the item index in the list, accounting for section headers
        final sections = ref.read(sectionsProvider).valueOrNull;
        if (sections != null) {
          final listIndex = _getListIndexForVerse(
            next.currentVerseIndex!,
            sections,
          );
          _scrollToVerse(listIndex);
        }
      }
    });

    return versesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (verses) => sectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (sections) => sharhAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('خطأ: $e')),
          data: (sharhNotes) {
            final wordTimingsMap = ref.watch(wordTimingsProvider).valueOrNull;
            final themeSettings = ref.watch(themeProvider.select(
              (s) => (
                playSectionTitles: s.playSectionTitles,
                reciter: s.reciter,
              ),
            ));

            // Initialize audio player
            _initAudio(
              ref,
              verses.length,
              sections,
              themeSettings.playSectionTitles,
              themeSettings.reciter,
            );

            // Build flat list: section headers + verses
            final items = _buildItemList(sections, verses);
            final sharhByVerse = _buildSharhMap(sharhNotes);

            final verseList = Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: ScrollablePositionedList.builder(
                  itemCount: items.length,
                  itemScrollController: _scrollController,
                  itemPositionsListener: _positionsListener,
                  padding: const EdgeInsets.only(bottom: 16, top: 8),
                  minCacheExtent: 800,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (item is _SectionItem) {
                      return SectionHeader(
                        title: item.section.title,
                        sectionNumber: item.section.id,
                        firstVerseIndex: item.section.verseStart - 1,
                      );
                    } else if (item is _VerseItem) {
                      final verse = item.verse;
                      final notesList = sharhByVerse[verse.id] ?? const [];
                      final isMemorized = ref.watch(
                        memorizationProvider.select(
                          (s) => s.isVerseMemorized(verse.number),
                        ),
                      );

                      return VerseTile(
                        verse: verse,
                        sharhNotes: notesList,
                        wordTimings: wordTimingsMap?[verse.number],
                        isMemorized: isMemorized,
                        onTap: () {
                          ref
                              .read(audioPlayerProvider.notifier)
                              .playFromVerse(verse.number - 1);
                        },
                        onToggleMemorized: () {
                          _toggleVerseMemorization(
                            context,
                            ref,
                            verse: verse,
                            sections: sections,
                          );
                        },
                        onLongPress: () {
                          _showQuickRepeat(context, ref, verse.number - 1);
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            );

            final audioControls = AudioControlsBar(totalVerses: verses.length);

            return Column(
              children: [
                verseList,
                audioControls,
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _toggleVerseMemorization(
    BuildContext context,
    WidgetRef ref, {
    required Verse verse,
    required List<Section> sections,
  }) async {
    final result = await ref.read(memorizationProvider.notifier).toggleVerse(
          verseNumber: verse.number,
          sections: sections,
        );

    if (!context.mounted) return;

    final useArabic = ref.read(themeProvider).useArabicNumerals;
    final verseLabel = formatNumeral(verse.number, arabic: useArabic);

    if (result.isMemorized) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }

    final message = result.isMemorized
        ? 'تم حفظ البيت $verseLabel'
        : 'تم إلغاء علامة الحفظ للبيت $verseLabel';

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          content: Text(
            message,
            style: GoogleFonts.amiri(fontSize: 16),
          ),
        ),
      );

    final completedSection = result.completedSection;
    if (completedSection != null) {
      await _showSectionCelebration(
        context,
        completedSection,
      );
    }
  }

  Future<void> _showSectionCelebration(
    BuildContext context,
    Section section,
  ) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'celebration',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, _, __) {
        return _SectionCompletionDialog(
          section: section,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  Map<int, List<SharhNote>> _buildSharhMap(List<SharhNote> sharhNotes) {
    final map = <int, List<SharhNote>>{};
    for (final note in sharhNotes) {
      for (final verseId in note.verseIds) {
        map.putIfAbsent(verseId, () => []).add(note);
      }
    }
    return map;
  }

  bool _audioInitialized = false;
  bool _lastSectionTitlesSetting = false;
  int _lastReciter = 1;

  void _initAudio(WidgetRef ref, int verseCount, List<Section> sections,
      bool playSectionTitles, int reciter) {
    if (!_audioInitialized ||
        _lastSectionTitlesSetting != playSectionTitles ||
        _lastReciter != reciter) {
      _audioInitialized = true;
      _lastSectionTitlesSetting = playSectionTitles;
      _lastReciter = reciter;
      Future.microtask(() {
        ref.read(audioPlayerProvider.notifier).loadPlaylist(
              verseCount,
              sections: sections,
              includeSectionTitles: playSectionTitles,
              reciter: reciter,
            );
      });
    }
  }

  int _getListIndexForVerse(int verseIndex, List<Section> sections) {
    // The list interleaves section headers with verses
    int listIndex = 0;
    for (final section in sections) {
      listIndex++; // section header
      for (int v = section.verseStart; v <= section.verseEnd; v++) {
        if (v - 1 == verseIndex) return listIndex;
        listIndex++;
      }
    }
    return 0;
  }

  List<_ListItem> _buildItemList(List<Section> sections, List<Verse> verses) {
    final items = <_ListItem>[];
    final verseMap = {for (var v in verses) v.number: v};

    for (final section in sections) {
      items.add(_SectionItem(section));
      for (int n = section.verseStart; n <= section.verseEnd; n++) {
        final verse = verseMap[n];
        if (verse != null) items.add(_VerseItem(verse));
      }
    }
    return items;
  }

  void _showQuickRepeat(BuildContext context, WidgetRef ref, int verseIndex) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final accent = colors.accent;
    final bgColor = colors.card;
    final audioNotifier = ref.read(audioPlayerProvider.notifier);

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'تكرار البيت ${verseIndex + 1}',
                style: GoogleFonts.amiri(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [2, 3, 5, 10, 0].map((count) {
                  final label = count == 0 ? '∞' : '$count';
                  return GestureDetector(
                    onTap: () async {
                      Navigator.pop(ctx);
                      await audioNotifier.setRepeatRange(
                          verseIndex, verseIndex, count);
                      audioNotifier.play();
                    },
                    child: Container(
                      width: 56,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: accent.withValues(alpha: 0.2)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// List item types
abstract class _ListItem {}

class _SectionItem extends _ListItem {
  final Section section;
  _SectionItem(this.section);
}

class _VerseItem extends _ListItem {
  final Verse verse;
  _VerseItem(this.verse);
}

class _SectionCompletionDialog extends StatefulWidget {
  final Section section;

  const _SectionCompletionDialog({
    required this.section,
  });

  @override
  State<_SectionCompletionDialog> createState() =>
      _SectionCompletionDialogState();
}

class _SectionCompletionDialogState extends State<_SectionCompletionDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiPiece> _backPieces;
  late final List<_ConfettiPiece> _frontPieces;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..forward();
    _backPieces = _buildConfettiPieces(
      count: 92,
      seedOffset: 1,
      minSize: 3.2,
      maxSize: 6.8,
      minSpeed: 0.85,
      maxSpeed: 1.25,
      minOpacity: 0.45,
      maxOpacity: 0.75,
    );
    _frontPieces = _buildConfettiPieces(
      count: 132,
      seedOffset: 7,
      minSize: 4.8,
      maxSize: 10.2,
      minSpeed: 1.0,
      maxSpeed: 1.55,
      minOpacity: 0.7,
      maxOpacity: 1.0,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_ConfettiPiece> _buildConfettiPieces({
    required int count,
    required int seedOffset,
    required double minSize,
    required double maxSize,
    required double minSpeed,
    required double maxSpeed,
    required double minOpacity,
    required double maxOpacity,
  }) {
    final random = math.Random(
      (widget.section.id * 10007) +
          (widget.section.verseEnd * 113) +
          (seedOffset * 97),
    );
    return List.generate(count, (_) {
      return _ConfettiPiece(
        x: random.nextDouble(),
        phase: random.nextDouble() * 2 * math.pi,
        startY: (-1.2 * random.nextDouble()) + (0.1 * random.nextDouble()),
        fallSpeed: minSpeed + (random.nextDouble() * (maxSpeed - minSpeed)),
        size: minSize + (random.nextDouble() * (maxSize - minSize)),
        sway: 10 + (random.nextDouble() * 30),
        swayFrequency: 0.55 + (random.nextDouble() * 2.4),
        spin: -2.8 + (random.nextDouble() * 5.6),
        opacity: minOpacity + (random.nextDouble() * (maxOpacity - minOpacity)),
        colorIndex: random.nextInt(6),
        isCircle: random.nextBool(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final accent = colors.accent;

    return Material(
      color: Colors.transparent,
      child: IgnorePointer(
        ignoring: true,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final rawT = _controller.value;
            final t = Curves.easeOut.transform(rawT);
            final fadeOut = rawT < 0.84 ? 1.0 : 1.0 - ((rawT - 0.84) / 0.16);
            final flashOpacity = (1 - rawT).clamp(0.0, 1.0) * 0.2;

            return Opacity(
              opacity: fadeOut.clamp(0.0, 1.0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.1),
                        radius: 1.25,
                        colors: [
                          accent.withValues(alpha: flashOpacity),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: _ConfettiPainter(
                        progress: t,
                        accent: accent,
                        pieces: _backPieces,
                        globalOpacity: 0.6,
                      ),
                    ),
                  ),
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: _ConfettiPainter(
                        progress: t,
                        accent: accent,
                        pieces: _frontPieces,
                        globalOpacity: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ConfettiPiece {
  final double x;
  final double phase;
  final double startY;
  final double fallSpeed;
  final double size;
  final double sway;
  final double swayFrequency;
  final double spin;
  final double opacity;
  final int colorIndex;
  final bool isCircle;

  const _ConfettiPiece({
    required this.x,
    required this.phase,
    required this.startY,
    required this.fallSpeed,
    required this.size,
    required this.sway,
    required this.swayFrequency,
    required this.spin,
    required this.opacity,
    required this.colorIndex,
    required this.isCircle,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final Color accent;
  final List<_ConfettiPiece> pieces;
  final double globalOpacity;

  const _ConfettiPainter({
    required this.progress,
    required this.accent,
    required this.pieces,
    required this.globalOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final palette = <Color>[
      accent,
      const Color(0xFFFFC107),
      const Color(0xFFE91E63),
      const Color(0xFF4FC3F7),
      const Color(0xFF66BB6A),
      const Color(0xFFFF7043),
    ];

    for (final piece in pieces) {
      final y =
          ((piece.startY + (progress * piece.fallSpeed * 1.6)) * size.height) +
              12;
      final swayOffset = math.sin(
              (progress * piece.swayFrequency * 2 * math.pi) + piece.phase) *
          piece.sway;
      final x = (piece.x * size.width) + swayOffset;
      final rotation = (progress * piece.spin * 2 * math.pi) + piece.phase;
      final color = palette[piece.colorIndex % palette.length].withValues(
        alpha: (piece.opacity * globalOpacity).clamp(0.0, 1.0),
      );

      if (x < -30 || x > size.width + 30 || y < -40 || y > size.height + 40) {
        continue;
      }

      final paint = Paint()..color = color;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      if (piece.isCircle) {
        canvas.drawCircle(Offset.zero, piece.size * 0.52, paint);
      } else {
        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: piece.size * 1.15,
          height: piece.size * 2.0,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect,
            Radius.circular(piece.size * 0.28),
          ),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accent != accent ||
        oldDelegate.globalOpacity != globalOpacity ||
        oldDelegate.pieces != pieces;
  }
}
