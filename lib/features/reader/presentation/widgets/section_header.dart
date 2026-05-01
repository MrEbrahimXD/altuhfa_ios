import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/audio_player_provider.dart';

class SectionHeader extends ConsumerWidget {
  final String title;
  final int sectionNumber;
  final int firstVerseIndex; // 0-based index of the first verse in this section

  const SectionHeader({
    super.key,
    required this.title,
    required this.sectionNumber,
    required this.firstVerseIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final accent = colors.accent;

    // Check if section title audio is currently playing for this section
    final isPlayingSectionTitle = ref.watch(audioPlayerProvider.select((s) =>
        s.playingSectionTitle &&
        s.currentVerseIndex == firstVerseIndex &&
        s.isPlaying));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: isPlayingSectionTitle
            ? accent.withValues(alpha: 0.18)
            : accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlayingSectionTitle ? accent : accent.withValues(alpha: 0.2),
          width: isPlayingSectionTitle ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Ornamental top
          Row(
            children: [
              Expanded(
                  child: Divider(
                      color: accent.withValues(alpha: 0.3), thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.auto_awesome, color: accent, size: 16),
              ),
              Expanded(
                  child: Divider(
                      color: accent.withValues(alpha: 0.3), thickness: 1)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$sectionNumber- $title',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.amiri(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: accent,
              height: 1.6,
            ),
          ),
          if (isPlayingSectionTitle) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.volume_up_rounded, size: 16, color: accent),
                const SizedBox(width: 4),
                Text(
                  'جارٍ التشغيل...',
                  style: GoogleFonts.amiri(fontSize: 13, color: accent),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: Divider(
                      color: accent.withValues(alpha: 0.3), thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.auto_awesome, color: accent, size: 16),
              ),
              Expanded(
                  child: Divider(
                      color: accent.withValues(alpha: 0.3), thickness: 1)),
            ],
          ),
        ],
      ),
    );
  }
}
