import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/arabic_utils.dart';
import '../../../../data/models/sharh_note.dart';
import '../../../../data/models/verse.dart';
import '../../../../data/models/word_timing.dart';
import '../../providers/audio_player_provider.dart';

class VerseTile extends ConsumerWidget {
  final Verse verse;
  final List<SharhNote> sharhNotes;
  final VerseWordTimings? wordTimings;
  final bool isMemorized;
  final VoidCallback onTap;
  final VoidCallback onToggleMemorized;
  final VoidCallback? onLongPress;

  const VerseTile({
    super.key,
    required this.verse,
    required this.sharhNotes,
    this.wordTimings,
    required this.isMemorized,
    required this.onTap,
    required this.onToggleMemorized,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final themeSettings = ref.watch(themeProvider.select(
      (settings) => (
        verseLayout: settings.verseLayout,
        removeParentheses: settings.removeParentheses,
        useArabicNumerals: settings.useArabicNumerals,
        fontScale: settings.fontScale,
      ),
    ));
    final playback = ref.watch(audioPlayerProvider.select((s) {
      final isActive =
          !s.playingSectionTitle && s.currentVerseIndex == (verse.number - 1);
      return (
        isActive: isActive,
        positionMs: (isActive && s.isPlaying) ? s.position.inMilliseconds : -1,
      );
    }));

    final isActive = playback.isActive;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color:
            isActive ? colors.activeVerse : colors.card.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? colors.activeVerseBorder
              : colors.accent.withValues(alpha: 0.08),
          width: isActive ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isActive ? 0.08 : 0.03),
            blurRadius: isActive ? 22 : 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    _VerseActionBubble(
                      accent: colors.accent,
                      fill: isActive
                          ? colors.accent.withValues(alpha: 0.18)
                          : colors.accent.withValues(alpha: 0.1),
                      icon: isActive
                          ? Icons.volume_up_rounded
                          : Icons.play_arrow_rounded,
                      onTap: onTap,
                    ),
                    const SizedBox(width: 8),
                    _VerseActionBubble(
                      accent:
                          isMemorized ? Colors.green.shade700 : colors.accent,
                      fill: isMemorized
                          ? Colors.green.withValues(alpha: 0.18)
                          : colors.accent.withValues(alpha: 0.1),
                      icon: isMemorized
                          ? Icons.check_circle_rounded
                          : Icons.add_task_rounded,
                      onTap: onToggleMemorized,
                    ),
                    const SizedBox(width: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeIn,
                      child: isMemorized
                          ? Container(
                              key: ValueKey('memorized_${verse.id}'),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: Colors.green.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                'تم الحفظ',
                                style: GoogleFonts.amiri(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            )
                          : SizedBox(
                              key: ValueKey('not_memorized_${verse.id}'),
                              width: 0,
                              height: 0,
                            ),
                    ),
                    const Spacer(),
                    if (sharhNotes.isNotEmpty)
                      _SharhActionBubble(
                        accent: colors.accent,
                        onTap: () => _showSharhSheet(
                          context,
                          useArabic: themeSettings.useArabicNumerals,
                          colors: colors,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                themeSettings.verseLayout == VerseLayout.poetic
                    ? _buildPoeticLayout(
                        colors: colors,
                        isActive: isActive,
                        fontSize: 24 * themeSettings.fontScale,
                        positionMs: playback.positionMs,
                        removeParens: themeSettings.removeParentheses,
                        useArabic: themeSettings.useArabicNumerals,
                      )
                    : _buildCenteredLayout(
                        colors: colors,
                        isActive: isActive,
                        fontSize: 24 * themeSettings.fontScale,
                        positionMs: playback.positionMs,
                        removeParens: themeSettings.removeParentheses,
                        useArabic: themeSettings.useArabicNumerals,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _activeWordIndex(int positionMs) {
    if (positionMs < 0 || wordTimings == null) return -1;
    final words = wordTimings!.words;
    for (int i = words.length - 1; i >= 0; i--) {
      if (positionMs >= words[i].startMs) return i;
    }
    return -1;
  }

  InlineSpan _buildWordSpans({
    required List<String> words,
    required int startIndex,
    required int activeWordIndex,
    required double fontSize,
    required Color baseColor,
    required Color activeColor,
    required FontWeight baseWeight,
  }) {
    final spans = <InlineSpan>[];
    for (int i = 0; i < words.length; i++) {
      final globalIdx = startIndex + i;
      final isWordActive = globalIdx == activeWordIndex;
      if (i > 0) {
        spans.add(TextSpan(
          text: ' ',
          style: GoogleFonts.amiri(fontSize: fontSize, color: baseColor),
        ));
      }
      spans.add(TextSpan(
        text: words[i],
        style: GoogleFonts.amiri(
          fontSize: fontSize,
          color: isWordActive ? activeColor : baseColor,
          fontWeight: isWordActive ? FontWeight.bold : baseWeight,
          height: 2.0,
          backgroundColor:
              isWordActive ? activeColor.withValues(alpha: 0.14) : null,
        ),
      ));
    }
    return TextSpan(children: spans);
  }

  String _cleanText(String text, bool removeParens) {
    if (!removeParens) return text;
    return text.replaceAll(RegExp(r'[()«»]'), '');
  }

  List<String> _splitLine(String text) {
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  }

  TextSpan _buildNumberPrefix(double fontSize, Color accent, bool useArabic) {
    return TextSpan(
      text: '${formatNumeral(verse.number, arabic: useArabic)} - ',
      style: GoogleFonts.amiri(
        fontSize: fontSize,
        color: accent.withValues(alpha: 0.62),
        fontWeight: FontWeight.bold,
        height: 2.0,
      ),
    );
  }

  Widget _buildPoeticLayout({
    required AppColors colors,
    required bool isActive,
    required double fontSize,
    required int positionMs,
    required bool removeParens,
    required bool useArabic,
  }) {
    final verseColor = isActive ? colors.accent : colors.text;
    final verseWeight = isActive ? FontWeight.bold : FontWeight.normal;
    final sadrText = _cleanText(verse.sadr, removeParens);
    final ajuzText = _cleanText(verse.ajuz, removeParens);
    final activeIdx = _activeWordIndex(positionMs);
    final sadrWords = _splitLine(sadrText);
    final ajuzWords = _splitLine(ajuzText);
    final sadrCount = wordTimings?.sadrWordCount ?? sadrWords.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: RichText(
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            text: TextSpan(
              children: [
                _buildNumberPrefix(fontSize, colors.accent, useArabic),
                if (wordTimings != null && activeIdx >= 0)
                  _buildWordSpans(
                    words: sadrWords,
                    startIndex: 0,
                    activeWordIndex: activeIdx,
                    fontSize: fontSize,
                    baseColor: verseColor,
                    activeColor: colors.accent,
                    baseWeight: verseWeight,
                  )
                else
                  TextSpan(
                    text: sadrText,
                    style: GoogleFonts.amiri(
                      fontSize: fontSize,
                      color: verseColor,
                      height: 2.0,
                      fontWeight: verseWeight,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: RichText(
            textAlign: TextAlign.left,
            textDirection: TextDirection.rtl,
            text: wordTimings != null && activeIdx >= 0
                ? _buildWordSpans(
                    words: ajuzWords,
                    startIndex: sadrCount,
                    activeWordIndex: activeIdx,
                    fontSize: fontSize,
                    baseColor: verseColor,
                    activeColor: colors.accent,
                    baseWeight: verseWeight,
                  ) as TextSpan
                : TextSpan(
                    text: ajuzText,
                    style: GoogleFonts.amiri(
                      fontSize: fontSize,
                      color: verseColor,
                      height: 2.0,
                      fontWeight: verseWeight,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCenteredLayout({
    required AppColors colors,
    required bool isActive,
    required double fontSize,
    required int positionMs,
    required bool removeParens,
    required bool useArabic,
  }) {
    final verseColor = isActive ? colors.accent : colors.text;
    final verseWeight = isActive ? FontWeight.bold : FontWeight.normal;
    final sadrText = _cleanText(verse.sadr, removeParens);
    final ajuzText = _cleanText(verse.ajuz, removeParens);
    final activeIdx = _activeWordIndex(positionMs);
    final sadrWords = _splitLine(sadrText);
    final ajuzWords = _splitLine(ajuzText);
    final sadrCount = wordTimings?.sadrWordCount ?? sadrWords.length;

    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          text: TextSpan(
            children: [
              _buildNumberPrefix(fontSize, colors.accent, useArabic),
              if (wordTimings != null && activeIdx >= 0)
                _buildWordSpans(
                  words: sadrWords,
                  startIndex: 0,
                  activeWordIndex: activeIdx,
                  fontSize: fontSize,
                  baseColor: verseColor,
                  activeColor: colors.accent,
                  baseWeight: verseWeight,
                )
              else
                TextSpan(
                  text: sadrText,
                  style: GoogleFonts.amiri(
                    fontSize: fontSize,
                    color: verseColor,
                    height: 2.0,
                    fontWeight: verseWeight,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          text: wordTimings != null && activeIdx >= 0
              ? _buildWordSpans(
                  words: ajuzWords,
                  startIndex: sadrCount,
                  activeWordIndex: activeIdx,
                  fontSize: fontSize,
                  baseColor: verseColor,
                  activeColor: colors.accent,
                  baseWeight: verseWeight,
                ) as TextSpan
              : TextSpan(
                  text: ajuzText,
                  style: GoogleFonts.amiri(
                    fontSize: fontSize,
                    color: verseColor,
                    height: 2.0,
                    fontWeight: verseWeight,
                  ),
                ),
        ),
      ],
    );
  }

  void _showSharhSheet(
    BuildContext context, {
    required bool useArabic,
    required AppColors colors,
  }) {
    final allText = sharhNotes.map((note) => note.text.trim()).join('\n\n');
    final rootMessenger = ScaffoldMessenger.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.72,
            maxChildSize: 0.94,
            minChildSize: 0.45,
            builder: (context, scrollController) {
              return Container(
                color: colors.surface,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'شرح البيت ${formatNumeral(verse.number, arabic: useArabic)}',
                                      style: GoogleFonts.amiri(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: colors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'شرح الشيخ علي محمد الضباع • ${formatNumeral(sharhNotes.length, arabic: useArabic)} مقطع',
                                      style: GoogleFonts.amiri(
                                        fontSize: 14,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: colors.accent.withValues(alpha: 0.12),
                                ),
                                child: Icon(
                                  Icons.menu_book_rounded,
                                  color: colors.accent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: () async {
                                  final messenger =
                                      ScaffoldMessenger.maybeOf(ctx) ??
                                          rootMessenger;
                                  await Clipboard.setData(
                                    ClipboardData(text: allText),
                                  );
                                  HapticFeedback.selectionClick();
                                  messenger
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 2),
                                        content: Text(
                                          'تم نسخ نص الشرح',
                                          style: GoogleFonts.amiri(),
                                        ),
                                      ),
                                    );
                                },
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                label: const Text('نسخ النص'),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: EdgeInsets.fromLTRB(
                          12,
                          4,
                          12,
                          20 + MediaQuery.of(context).viewPadding.bottom,
                        ),
                        itemCount: sharhNotes.length,
                        itemBuilder: (context, index) {
                          final note = sharhNotes[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: colors.card,
                              border: Border.all(
                                color: colors.accent.withValues(alpha: 0.14),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(14, 12, 14, 10),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(15),
                                    ),
                                    color: colors.surface,
                                  ),
                                  child: Text(
                                    'المقطع ${formatNumeral(index + 1, arabic: useArabic)}',
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.amiri(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: colors.accent,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: colors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: colors.accent
                                            .withValues(alpha: 0.1),
                                      ),
                                    ),
                                    child: SelectableText(
                                      note.text,
                                      textAlign: TextAlign.right,
                                      style: GoogleFonts.amiri(
                                        fontSize: 19,
                                        color: colors.text,
                                        height: 1.8,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _VerseActionBubble extends StatelessWidget {
  final Color accent;
  final Color fill;
  final IconData icon;
  final VoidCallback onTap;

  const _VerseActionBubble({
    required this.accent,
    required this.fill,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
        ),
        child: Icon(icon, color: accent, size: 18),
      ),
    );
  }
}

class _SharhActionBubble extends StatelessWidget {
  final Color accent;
  final VoidCallback onTap;

  const _SharhActionBubble({
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: accent.withValues(alpha: 0.1),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'الشرح',
              style: GoogleFonts.amiri(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.menu_book_rounded, size: 16, color: accent),
          ],
        ),
      ),
    );
  }
}
