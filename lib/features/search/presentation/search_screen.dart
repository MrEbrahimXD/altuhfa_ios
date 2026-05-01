import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/arabic_utils.dart';
import '../../../data/models/verse.dart';
import '../../reader/providers/tuhfa_providers.dart';
import '../../reader/providers/audio_player_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Verse> _searchVerses(List<Verse> verses, String query) {
    if (query.trim().isEmpty) return [];
    final normalizedQuery = normalizeForSearch(query);
    return verses.where((v) {
      final normalizedSadr = normalizeForSearch(v.sadr);
      final normalizedAjuz = normalizeForSearch(v.ajuz);
      return normalizedSadr.contains(normalizedQuery) ||
          normalizedAjuz.contains(normalizedQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final versesAsync = ref.watch(versesProvider);
    final colors = Theme.of(context).extension<AppColors>()!;
    final accent = colors.accent;
    final textColor = colors.text;
    final secondaryColor = colors.textSecondary;
    final cardColor = colors.card;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final useArabicNumerals =
        ref.watch(themeProvider.select((s) => s.useArabicNumerals));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('البحث'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              // Search bar
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accent.withValues(alpha: 0.2)),
                ),
                child: TextField(
                  controller: _searchController,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.amiri(fontSize: 18, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'ابحث في أبيات التحفة...',
                    hintStyle: GoogleFonts.amiri(
                      fontSize: 16,
                      color: secondaryColor.withValues(alpha: 0.5),
                    ),
                    prefixIcon: Icon(Icons.search, color: accent),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: secondaryColor),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _query = value);
                  },
                ),
              ),
              // Results
              Expanded(
                child: versesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('خطأ: $e')),
                  data: (verses) {
                    if (_query.trim().isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search,
                                size: 64,
                                color: secondaryColor.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            Text(
                              'ابحث عن بيت في المتن',
                              style: GoogleFonts.amiri(
                                fontSize: 18,
                                color: secondaryColor.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final results = _searchVerses(verses, _query);

                    if (results.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off,
                                size: 64,
                                color: secondaryColor.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد نتائج',
                              style: GoogleFonts.amiri(
                                fontSize: 18,
                                color: secondaryColor.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset + 16),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final verse = results[index];
                        return _SearchResultTile(
                          verse: verse,
                          useArabicNumerals: useArabicNumerals,
                          accent: accent,
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                          cardColor: cardColor,
                          onTap: () {
                            ref
                                .read(audioPlayerProvider.notifier)
                                .playFromVerse(verse.number - 1);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final Verse verse;
  final bool useArabicNumerals;
  final Color accent;
  final Color textColor;
  final Color secondaryColor;
  final Color cardColor;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.verse,
    required this.useArabicNumerals,
    required this.accent,
    required this.textColor,
    required this.secondaryColor,
    required this.cardColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Play icon
              Icon(Icons.play_circle_outline, color: accent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Verse number
                    Text(
                      'البيت ${formatNumeral(verse.number, arabic: useArabicNumerals)}',
                      style: GoogleFonts.amiri(
                        fontSize: 13,
                        color: accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      verse.sadr,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.amiri(
                        fontSize: 18,
                        color: textColor,
                        height: 1.8,
                      ),
                    ),
                    Text(
                      verse.ajuz,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.amiri(
                        fontSize: 18,
                        color: secondaryColor,
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
