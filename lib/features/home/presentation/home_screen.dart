import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/arabic_utils.dart';
import '../../../core/navigation/app_route.dart';
import '../../memorization/providers/memorization_provider.dart';
import '../../reader/presentation/reader_screen.dart';
import '../../reader/providers/tuhfa_providers.dart';
import '../../search/presentation/search_screen.dart';
import '../../settings/presentation/settings_screen.dart';
// TODO: re-enable test feature
// import '../../test/presentation/test_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const double _tabletLandscapeBreakpoint = 900;

  bool _useTabletLayout(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;
    return isLandscape &&
        size.width >= _tabletLandscapeBreakpoint &&
        size.shortestSide >= 600;
  }

  void _openSearch(BuildContext context) {
    Navigator.push(
      context,
      AppRoute(page: const SearchScreen()),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      AppRoute(page: const SettingsScreen()),
    );
  }

  void _showMemorizationBottomSheet(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _MemorizationBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (_useTabletLayout(context)) {
      final colors = Theme.of(context).extension<AppColors>()!;
      final sideWidth = (MediaQuery.sizeOf(context).width * 0.28)
          .clamp(280.0, 360.0)
          .toDouble();

      return Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Row(
            children: [
              SizedBox(
                width: sideWidth,
                child: _TabletSidebar(
                  onMemorizationPressed: () =>
                      _showMemorizationBottomSheet(context),
                  onSearchPressed: () => _openSearch(context),
                  onSettingsPressed: () => _openSettings(context),
                ),
              ),
              Container(
                width: 1,
                color: colors.accent.withValues(alpha: 0.14),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: colors.accent.withValues(alpha: 0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(22)),
                      child: ReaderScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('التُّحْفَة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.school_rounded),
            tooltip: 'مستوى الحفظ',
            onPressed: () => _showMemorizationBottomSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => _openSearch(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => _openSettings(context),
          ),
        ],
      ),
      body: const ReaderScreen(),
    );
  }
}

class _TabletSidebar extends ConsumerWidget {
  final VoidCallback onMemorizationPressed;
  final VoidCallback onSearchPressed;
  final VoidCallback onSettingsPressed;

  const _TabletSidebar({
    required this.onMemorizationPressed,
    required this.onSearchPressed,
    required this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.surface,
            colors.card,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.accent.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'التُّحْفَة',
                    style: GoogleFonts.amiri(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: colors.accent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'واجهة مخصصة للأجهزة اللوحية',
                    style: GoogleFonts.amiri(
                      fontSize: 15,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _TabletActionCard(
              icon: Icons.school_rounded,
              title: 'مستوى الحفظ',
              subtitle: 'عرض النسبة والتقدم',
              colors: colors,
              onTap: onMemorizationPressed,
            ),
            const SizedBox(height: 10),
            _TabletActionCard(
              icon: Icons.search_rounded,
              title: 'البحث',
              subtitle: 'ابحث داخل الأبيات',
              colors: colors,
              onTap: onSearchPressed,
            ),
            const SizedBox(height: 10),
            _TabletActionCard(
              icon: Icons.settings_rounded,
              title: 'الإعدادات',
              subtitle: 'تخصيص اللون والقارئ',
              colors: colors,
              onTap: onSettingsPressed,
            ),
            const SizedBox(height: 14),
            const _TabletMemorizationCard(),
          ],
        ),
      ),
    );
  }
}

class _TabletActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final AppColors colors;
  final VoidCallback onTap;

  const _TabletActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.accent.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Icon(icon, color: colors.accent, size: 23),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.amiri(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.amiri(
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textSecondary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabletMemorizationCard extends ConsumerWidget {
  const _TabletMemorizationCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final memorization = ref.watch(memorizationProvider);
    final versesAsync = ref.watch(versesProvider);
    final sectionsAsync = ref.watch(sectionsProvider);
    final useArabicNumerals =
        ref.watch(themeProvider.select((s) => s.useArabicNumerals));

    if (!memorization.isLoaded) {
      return _TabletMemorizationCardContainer(
        colors: colors,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2.6)),
        ),
      );
    }

    return versesAsync.when(
      loading: () => _TabletMemorizationCardContainer(
        colors: colors,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2.6)),
        ),
      ),
      error: (_, __) => _TabletMemorizationCardContainer(
        colors: colors,
        child: Text(
          'تعذر تحميل إحصائيات الحفظ',
          style: GoogleFonts.amiri(
            fontSize: 15,
            color: colors.textSecondary,
          ),
        ),
      ),
      data: (verses) => sectionsAsync.when(
        loading: () => _TabletMemorizationCardContainer(
          colors: colors,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.6)),
          ),
        ),
        error: (_, __) => _TabletMemorizationCardContainer(
          colors: colors,
          child: Text(
            'تعذر تحميل إحصائيات الحفظ',
            style: GoogleFonts.amiri(
              fontSize: 15,
              color: colors.textSecondary,
            ),
          ),
        ),
        data: (sections) {
          final ratio = memorization
              .memorizationRatio(verses.length)
              .clamp(0.0, 1.0)
              .toDouble();
          final percent = (ratio * 100).round();
          final memorizedCount = memorization.memorizedCount;
          final completedSections =
              memorization.completedSectionsCount(sections);

          final percentText =
              '${formatNumeral(percent, arabic: useArabicNumerals)}%';
          final versesText =
              '${formatNumeral(memorizedCount, arabic: useArabicNumerals)} / ${formatNumeral(verses.length, arabic: useArabicNumerals)}';
          final sectionsText =
              '${formatNumeral(completedSections, arabic: useArabicNumerals)} / ${formatNumeral(sections.length, arabic: useArabicNumerals)}';

          return _TabletMemorizationCardContainer(
            colors: colors,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.insights_rounded,
                        color: colors.accent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تقدم الحفظ',
                        style: GoogleFonts.amiri(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.text,
                        ),
                      ),
                    ),
                    Text(
                      percentText,
                      style: GoogleFonts.amiri(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 10,
                    color: colors.accent,
                    backgroundColor: colors.accent.withValues(alpha: 0.16),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'الأبيات: $versesText',
                  style: GoogleFonts.amiri(
                    fontSize: 15,
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  'الأبواب: $sectionsText',
                  style: GoogleFonts.amiri(
                    fontSize: 15,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TabletMemorizationCardContainer extends StatelessWidget {
  final AppColors colors;
  final Widget child;

  const _TabletMemorizationCardContainer({
    required this.colors,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.accent.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }
}

class _MemorizationBottomSheet extends ConsumerWidget {
  const _MemorizationBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final memorization = ref.watch(memorizationProvider);
    final versesAsync = ref.watch(versesProvider);
    final sectionsAsync = ref.watch(sectionsProvider);
    final useArabicNumerals =
        ref.watch(themeProvider.select((s) => s.useArabicNumerals));

    Widget content;

    if (!memorization.isLoaded) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    } else {
      content = versesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Text(
            'تعذر تحميل نسبة الحفظ',
            style: GoogleFonts.amiri(
              fontSize: 16,
              color: colors.textSecondary,
            ),
          ),
        ),
        data: (verses) => sectionsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text(
              'تعذر تحميل نسبة الحفظ',
              style: GoogleFonts.amiri(
                fontSize: 16,
                color: colors.textSecondary,
              ),
            ),
          ),
          data: (sections) {
            final totalVerses = verses.length;
            final memorizedCount = memorization.memorizedCount;
            final ratio = memorization
                .memorizationRatio(totalVerses)
                .clamp(0.0, 1.0)
                .toDouble();
            final percent = (ratio * 100).round();
            final completedSections =
                memorization.completedSectionsCount(sections);

            final percentText =
                '${formatNumeral(percent, arabic: useArabicNumerals)}%';
            final versesText =
                '${formatNumeral(memorizedCount, arabic: useArabicNumerals)} / ${formatNumeral(totalVerses, arabic: useArabicNumerals)}';
            final sectionsText =
                '${formatNumeral(completedSections, arabic: useArabicNumerals)} / ${formatNumeral(sections.length, arabic: useArabicNumerals)}';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.school_rounded, color: colors.accent, size: 25),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'مستوى الحفظ',
                        style: GoogleFonts.amiri(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colors.text,
                        ),
                      ),
                    ),
                    Text(
                      percentText,
                      style: GoogleFonts.amiri(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: colors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 11,
                    color: colors.accent,
                    backgroundColor: colors.accent.withValues(alpha: 0.14),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _SheetInfoItem(
                        title: 'الأبيات المحفوظة',
                        value: versesText,
                        colors: colors,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SheetInfoItem(
                        title: 'الأبواب المكتملة',
                        value: sectionsText,
                        colors: colors,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          16 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: content,
      ),
    );
  }
}

class _SheetInfoItem extends StatelessWidget {
  final String title;
  final String value;
  final AppColors colors;

  const _SheetInfoItem({
    required this.title,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accent.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.amiri(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.amiri(
              fontSize: 14,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
