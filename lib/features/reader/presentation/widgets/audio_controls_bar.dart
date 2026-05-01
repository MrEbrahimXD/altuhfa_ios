import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/arabic_utils.dart';
import '../../providers/audio_player_provider.dart';

class AudioControlsBar extends ConsumerWidget {
  final int totalVerses;

  const AudioControlsBar({super.key, required this.totalVerses});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioPlayerProvider);
    final audioNotifier = ref.read(audioPlayerProvider.notifier);
    final useArabic = ref.watch(themeProvider).useArabicNumerals;
    final colors = Theme.of(context).extension<AppColors>()!;
    final accent = colors.accent;
    final bgColor = colors.surface;

    final currentVerse = (audioState.currentVerseIndex ?? 0) + 1;

    // When repeat is active, clamp slider to repeat range
    final isRepeating = audioState.repeatEnabled;
    final sliderMin = isRepeating ? audioState.repeatStart : 0;
    final sliderMax = isRepeating ? audioState.repeatEnd : totalVerses - 1;
    final sliderValue = (audioState.currentVerseIndex ?? 0)
        .clamp(sliderMin, sliderMax)
        .toDouble();

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Verse indicator
              Text(
                isRepeating
                    ? _buildRepeatLabel(audioState, currentVerse, useArabic)
                    : 'البيت ${formatNumeral(currentVerse, arabic: useArabic)} من ${formatNumeral(totalVerses, arabic: useArabic)}',
                style: GoogleFonts.amiri(
                  fontSize: 14,
                  color: accent,
                ),
              ),
              const SizedBox(height: 4),
              // Progress bar
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: accent,
                  inactiveTrackColor: accent.withValues(alpha: 0.15),
                  thumbColor: accent,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  trackHeight: 3,
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 14),
                ),
                child: Slider(
                  value: sliderValue,
                  min: sliderMin.toDouble(),
                  max: sliderMax.toDouble(),
                  onChanged: (value) {
                    audioNotifier.seekToVerse(value.round());
                  },
                ),
              ),
              const SizedBox(height: 4),
              // Controls row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Speed button
                  _SpeedButton(
                    speed: audioState.speed,
                    accent: accent,
                    onTap: () => _showSpeedPicker(context, ref),
                  ),
                  // Previous
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, size: 32),
                    color: accent,
                    onPressed: () => audioNotifier.previousVerse(),
                  ),
                  // Play/Pause
                  GestureDetector(
                    onTap: () => audioNotifier.togglePlayPause(),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                      ),
                      child: Icon(
                        audioState.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 32,
                      ),
                    ),
                  ),
                  // Next
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded, size: 32),
                    color: accent,
                    onPressed: () => audioNotifier.nextVerse(),
                  ),
                  // Repeat button
                  _RepeatButton(
                    isActive: audioState.repeatEnabled,
                    accent: accent,
                    onTap: () => _showRepeatPicker(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Reciter row
              _ReciterBar(
                accent: accent,
                onTap: () => _showReciterPicker(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildRepeatLabel(
      AudioPlayerState s, int currentVerse, bool useArabic) {
    final range =
        'تكرار ${formatNumeral(s.repeatStart + 1, arabic: useArabic)}-${formatNumeral(s.repeatEnd + 1, arabic: useArabic)}';
    final round = s.currentRepeatRound + 1; // 1-based for display
    final roundLabel = s.repeatCount == 0
        ? 'المرة ${formatNumeral(round, arabic: useArabic)} (∞)'
        : 'المرة ${formatNumeral(round, arabic: useArabic)} من ${formatNumeral(s.repeatCount, arabic: useArabic)}';
    return 'البيت ${formatNumeral(currentVerse, arabic: useArabic)} | $range | $roundLabel';
  }

  void _showSpeedPicker(BuildContext context, WidgetRef ref) {
    final audioNotifier = ref.read(audioPlayerProvider.notifier);
    final currentSpeed = ref.read(audioPlayerProvider).speed;
    final colors = Theme.of(context).extension<AppColors>()!;
    final accent = colors.accent;
    final bgColor = colors.card;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'سرعة التشغيل',
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
                children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
                  final isSelected = (currentSpeed - speed).abs() < 0.01;
                  return GestureDetector(
                    onTap: () {
                      audioNotifier.setSpeed(speed);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 70,
                      height: 44,
                      decoration: BoxDecoration(
                        color:
                            isSelected ? accent : accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? accent
                              : accent.withValues(alpha: 0.2),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${speed}x',
                        style: GoogleFonts.amiri(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : accent,
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

  void _showReciterPicker(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final accent = colors.accent;
    final bgColor = colors.card;
    final textColor = colors.text;
    final themeNotifier = ref.read(themeProvider.notifier);
    final currentReciter = ref.read(themeProvider).reciter;

    const reciters = [
      (4, 'الشيخ ياسر سلامة'),
      (1, 'الشيخ عبدالقادر العثمان'),
      (2, 'الشيخ سعد الغامدي'),
      (3, 'الشيخ أحمد النفيس'),
    ];

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'اختر القارئ',
                style: GoogleFonts.amiri(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
              const SizedBox(height: 20),
              ...reciters.map((r) {
                final isSelected = currentReciter == r.$1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () {
                      themeNotifier.setReciter(r.$1);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accent
                            : accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? accent
                              : accent.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        r.$2,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : textColor,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showRepeatPicker(BuildContext context, WidgetRef ref) {
    final audioNotifier = ref.read(audioPlayerProvider.notifier);
    final colors = Theme.of(context).extension<AppColors>()!;
    final accent = colors.accent;
    final bgColor = colors.card;
    final textColor = colors.text;

    int startVerse = audioNotifier.repeatStart + 1;
    int endVerse = audioNotifier.repeatEnd + 1;
    int repeatCount = audioNotifier.repeatCount;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'التكرار',
                  style: GoogleFonts.amiri(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 24),
                // Start verse
                Row(
                  children: [
                    Text('من البيت:',
                        style:
                            GoogleFonts.amiri(fontSize: 16, color: textColor)),
                    const Spacer(),
                    _NumberStepper(
                      value: startVerse,
                      min: 1,
                      max: endVerse,
                      accent: accent,
                      textColor: textColor,
                      onChanged: (v) => setState(() => startVerse = v),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // End verse
                Row(
                  children: [
                    Text('إلى البيت:',
                        style:
                            GoogleFonts.amiri(fontSize: 16, color: textColor)),
                    const Spacer(),
                    _NumberStepper(
                      value: endVerse,
                      min: startVerse,
                      max: totalVerses,
                      accent: accent,
                      textColor: textColor,
                      onChanged: (v) => setState(() => endVerse = v),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Repeat count
                Text('عدد مرات التكرار',
                    style: GoogleFonts.amiri(fontSize: 16, color: textColor)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  children: [1, 2, 3, 5, 10, 0].map((count) {
                    final isSelected = repeatCount == count;
                    final label = count == 0 ? '∞' : '$count';
                    return GestureDetector(
                      onTap: () => setState(() => repeatCount = count),
                      child: Container(
                        width: 48,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accent
                              : accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : accent,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await audioNotifier.setRepeatRange(
                            startVerse - 1,
                            endVerse - 1,
                            repeatCount,
                          );
                          audioNotifier.play();
                          if (context.mounted) Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('بدء التكرار',
                            style: GoogleFonts.amiri(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    if (audioNotifier.repeatEnabled) ...[
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () async {
                          await audioNotifier.disableRepeat();
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Text('إيقاف',
                            style: GoogleFonts.amiri(
                                fontSize: 16, color: Colors.red)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  final double speed;
  final Color accent;
  final VoidCallback onTap;

  const _SpeedButton(
      {required this.speed, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: accent.withValues(alpha: 0.1),
        ),
        child: Text(
          '${speed}x',
          style: TextStyle(
            color: accent,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ReciterBar extends ConsumerWidget {
  final Color accent;
  final VoidCallback onTap;

  const _ReciterBar({required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reciter = ref.watch(themeProvider).reciter;
    const names = {
      1: 'الشيخ عبدالقادر العثمان',
      2: 'الشيخ سعد الغامدي',
      3: 'الشيخ أحمد النفيس',
      4: 'الشيخ ياسر سلامة',
    };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: accent.withValues(alpha: 0.1),
          border: Border.all(color: accent.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.record_voice_over_rounded, size: 16, color: accent),
            const SizedBox(width: 6),
            Text(
              names[reciter] ?? '',
              style: GoogleFonts.amiri(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down_rounded, size: 18, color: accent),
          ],
        ),
      ),
    );
  }
}

class _RepeatButton extends StatelessWidget {
  final bool isActive;
  final Color accent;
  final VoidCallback onTap;

  const _RepeatButton(
      {required this.isActive, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.repeat_rounded,
        size: 26,
        color: isActive ? accent : accent.withValues(alpha: 0.5),
      ),
      onPressed: onTap,
    );
  }
}

class _NumberStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final Color accent;
  final Color textColor;
  final ValueChanged<int> onChanged;

  const _NumberStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.accent,
    required this.textColor,
    required this.onChanged,
  });

  void _showNumberInput(BuildContext context) {
    final controller = TextEditingController(text: '$value');
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('أدخل رقم البيت',
              style: GoogleFonts.amiri(fontSize: 18, color: accent)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(fontSize: 22, color: textColor),
            decoration: InputDecoration(
              hintText: '$min - $max',
              hintStyle: TextStyle(color: textColor.withValues(alpha: 0.3)),
            ),
            onSubmitted: (text) {
              final n = int.tryParse(text);
              if (n != null && n >= min && n <= max) {
                onChanged(n);
              }
              Navigator.pop(ctx);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                final n = int.tryParse(controller.text);
                if (n != null && n >= min && n <= max) {
                  onChanged(n);
                }
                Navigator.pop(ctx);
              },
              child: Text('تم', style: GoogleFonts.amiri(color: accent)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.remove_circle_outline, color: accent, size: 28),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        GestureDetector(
          onTap: () => _showNumberInput(context),
          child: Container(
            width: 50,
            alignment: Alignment.center,
            child: Text(
              toArabicNumeral(value),
              style: GoogleFonts.amiri(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
                decoration: TextDecoration.underline,
                decorationColor: accent.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.add_circle_outline, color: accent, size: 28),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}
