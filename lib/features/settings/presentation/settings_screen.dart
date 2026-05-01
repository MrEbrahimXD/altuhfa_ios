import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/accent_palette.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../features/stats/providers/session_stats_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final colors = Theme.of(context).extension<AppColors>()!;
    final accent = colors.accent;
    final textColor = colors.text;
    final secondaryColor = colors.textSecondary;
    final cardColor = colors.card;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإعدادات'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 20),
            children: [
              // Theme section
              _SettingsSection(
                title: 'المظهر',
                accent: accent,
                children: [
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.palette_rounded, color: accent, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'السمة',
                            style: GoogleFonts.amiri(
                                fontSize: 16, color: textColor),
                          ),
                        ),
                        _ThemeModeSelector(
                          themeMode: themeSettings.themeMode,
                          accent: accent,
                          onChanged: (mode) => themeNotifier.setThemeMode(mode),
                        ),
                      ],
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.color_lens_rounded,
                    title: 'لون التطبيق',
                    accent: accent,
                    textColor: textColor,
                    cardColor: cardColor,
                    trailing: _AccentPreviewButton(
                      accent: themeSettings.accentColor,
                      onTap: () => _showAccentPicker(
                        context,
                        current: themeSettings.accentColor,
                        colors: colors,
                        onChanged: themeNotifier.setAccentColor,
                        onReset: themeNotifier.resetAccentColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Audio section
              _SettingsSection(
                title: 'الصوت',
                accent: accent,
                children: [
                  _SettingsTile(
                    icon: Icons.queue_music_rounded,
                    title: 'تشغيل عناوين الأبواب',
                    accent: accent,
                    textColor: textColor,
                    cardColor: cardColor,
                    trailing: Switch(
                      value: themeSettings.playSectionTitles,
                      onChanged: (_) => themeNotifier.setPlaySectionTitles(
                          !themeSettings.playSectionTitles),
                      activeColor: accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Reminder section
              _SettingsSection(
                title: 'التذكير',
                accent: accent,
                children: [
                  _ReminderTile(
                    accent: accent,
                    textColor: textColor,
                    cardColor: cardColor,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Display section
              _SettingsSection(
                title: 'العرض',
                accent: accent,
                children: [
                  _SettingsTile(
                    icon: Icons.code_rounded,
                    title: 'إزالة الأقواس من الأبيات',
                    accent: accent,
                    textColor: textColor,
                    cardColor: cardColor,
                    trailing: Switch(
                      value: themeSettings.removeParentheses,
                      onChanged: (_) => themeNotifier.setRemoveParentheses(
                          !themeSettings.removeParentheses),
                      activeColor: accent,
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.tag_rounded,
                    title: 'شكل الأرقام',
                    accent: accent,
                    textColor: textColor,
                    cardColor: cardColor,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _NumeralChoiceButton(
                          label: '١٢٣',
                          isSelected: themeSettings.useArabicNumerals,
                          accent: accent,
                          onTap: () => themeNotifier.setUseArabicNumerals(true),
                        ),
                        const SizedBox(width: 8),
                        _NumeralChoiceButton(
                          label: '123',
                          isSelected: !themeSettings.useArabicNumerals,
                          accent: accent,
                          onTap: () =>
                              themeNotifier.setUseArabicNumerals(false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Verse layout section
              _SettingsSection(
                title: 'تنسيق الأبيات',
                accent: accent,
                children: [
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<VerseLayout>(
                          value: VerseLayout.poetic,
                          groupValue: themeSettings.verseLayout,
                          onChanged: (v) => themeNotifier.setVerseLayout(v!),
                          activeColor: accent,
                          title: Text(
                            'شعري (صدر يمين، عجز يسار)',
                            style: GoogleFonts.amiri(
                                fontSize: 15, color: textColor),
                          ),
                          subtitle: Text(
                            'يحاكي تنسيق الكتب المطبوعة',
                            style: GoogleFonts.amiri(
                                fontSize: 12, color: secondaryColor),
                          ),
                        ),
                        RadioListTile<VerseLayout>(
                          value: VerseLayout.centered,
                          groupValue: themeSettings.verseLayout,
                          onChanged: (v) => themeNotifier.setVerseLayout(v!),
                          activeColor: accent,
                          title: Text(
                            'وسطي (الشطران في المنتصف)',
                            style: GoogleFonts.amiri(
                                fontSize: 15, color: textColor),
                          ),
                          subtitle: Text(
                            'تنسيق بسيط ومريح',
                            style: GoogleFonts.amiri(
                                fontSize: 12, color: secondaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Font size section
              _SettingsSection(
                title: 'حجم الخط',
                accent: accent,
                children: [
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Preview
                        Text(
                          'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.amiri(
                            fontSize: 22 * themeSettings.fontScale,
                            color: textColor,
                            height: 2.0,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Slider
                        Row(
                          children: [
                            Text('ص',
                                style: GoogleFonts.amiri(
                                    fontSize: 14, color: secondaryColor)),
                            Expanded(
                              child: SliderTheme(
                                data: SliderThemeData(
                                  activeTrackColor: accent,
                                  inactiveTrackColor:
                                      accent.withValues(alpha: 0.15),
                                  thumbColor: accent,
                                ),
                                child: Slider(
                                  value: themeSettings.fontScale,
                                  min: 0.7,
                                  max: 1.5,
                                  divisions: 8,
                                  onChanged: (v) =>
                                      themeNotifier.setFontScale(v),
                                ),
                              ),
                            ),
                            Text('ك',
                                style: GoogleFonts.amiri(
                                    fontSize: 22, color: secondaryColor)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Stats section
              _SettingsSection(
                title: 'الإحصائيات',
                accent: accent,
                children: [
                  _StatsTile(
                    accent: accent,
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                    cardColor: cardColor,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // About section
              _SettingsSection(
                title: 'حول التطبيق',
                accent: accent,
                children: [
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // App icon
                        Builder(builder: (context) {
                          final onAccent =
                              ThemeData.estimateBrightnessForColor(accent) ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black;
                          return Container(
                            width: 72,
                            height: 72,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: accent,
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.32),
                                  blurRadius: 14,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ColorFiltered(
                              colorFilter:
                                  ColorFilter.mode(onAccent, BlendMode.srcIn),
                              child: Image.asset(
                                'assets/images/app_icon_foreground.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                        Text(
                          'التُّحْفَة',
                          style: GoogleFonts.amiri(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'في متن تحفة الأطفال',
                          style: GoogleFonts.amiri(
                            fontSize: 18,
                            color: secondaryColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _AboutRow(
                          label: 'النظم',
                          value: 'الشيخ سليمان بن حسين الجمزوري',
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                        ),
                        const SizedBox(height: 8),
                        _AboutRow(
                          label: 'الشرح',
                          value: 'الشيخ علي محمد الضباع',
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                        ),
                        const SizedBox(height: 8),
                        _AboutRow(
                          label: 'الإصدار',
                          value: '١.٠.٠',
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAccentPicker(
    BuildContext context, {
    required Color current,
    required AppColors colors,
    required ValueChanged<Color> onChanged,
    required VoidCallback onReset,
  }) async {
    Color selected = current;

    final picked = await showModalBottomSheet<Color>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final preview = selected;
            final previewTextColor =
                ThemeData.estimateBrightnessForColor(preview) == Brightness.dark
                    ? Colors.white
                    : Colors.black;
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                color: colors.surface,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'اختيار لون التطبيق',
                      style: GoogleFonts.amiri(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 170),
                      curve: Curves.easeOutCubic,
                      height: 58,
                      decoration: BoxDecoration(
                        color: preview,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'معاينة اللون',
                        style: GoogleFonts.amiri(
                          fontSize: 16,
                          color: previewTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: AccentPalette.options
                          .map(
                            (option) => _AccentSwatch(
                              color: option.color,
                              isSelected: AccentPalette.encodeColor(selected) ==
                                  AccentPalette.encodeColor(option.color),
                              onTap: () =>
                                  setState(() => selected = option.color),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => setState(
                              () => selected = AccentPalette.defaultAccent),
                          child: Text(
                            'الافتراضي',
                            style: GoogleFonts.amiri(color: colors.accent),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'إلغاء',
                            style:
                                GoogleFonts.amiri(color: colors.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, preview),
                          child: const Text('تطبيق'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      if (AccentPalette.encodeColor(picked) ==
          AccentPalette.encodeColor(AccentPalette.defaultAccent)) {
        onReset();
      } else {
        onChanged(picked);
      }
    }
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final Color accent;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.accent,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.amiri(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _AccentPreviewButton extends StatelessWidget {
  final Color accent;
  final VoidCallback onTap;

  const _AccentPreviewButton({required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: accent.withValues(alpha: 0.12),
            border: Border.all(color: accent.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'اختيار',
                style: GoogleFonts.amiri(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _AccentSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : Colors.black;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutCubic,
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.onSurface
                  : color.withValues(alpha: 0.45),
              width: isSelected ? 3 : 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isSelected ? 0.45 : 0.2),
                blurRadius: isSelected ? 14 : 7,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child:
              isSelected ? Icon(Icons.check_rounded, color: iconColor) : null,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accent;
  final Color textColor;
  final Color cardColor;
  final Widget trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.accent,
    required this.textColor,
    required this.cardColor,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.amiri(fontSize: 16, color: textColor),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  final Color secondaryColor;

  const _AboutRow({
    required this.label,
    required this.value,
    required this.textColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.amiri(
            fontSize: 15,
            color: secondaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.amiri(fontSize: 15, color: textColor),
          ),
        ),
      ],
    );
  }
}

class _NumeralChoiceButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  const _NumeralChoiceButton({
    required this.label,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? accent : accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? accent : accent.withValues(alpha: 0.2),
            ),
          ),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOutCubic,
            scale: isSelected ? 1.0 : 0.96,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsTile extends ConsumerWidget {
  final Color accent;
  final Color textColor;
  final Color secondaryColor;
  final Color cardColor;

  const _StatsTile({
    required this.accent,
    required this.textColor,
    required this.secondaryColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(sessionStatsProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        runAlignment: WrapAlignment.center,
        spacing: 24,
        runSpacing: 14,
        children: [
          _StatItem(
            icon: Icons.headphones_rounded,
            value: '${stats.versesListened}',
            label: 'بيت مسموع',
            accent: accent,
            textColor: textColor,
            secondaryColor: secondaryColor,
          ),
          _StatItem(
            icon: Icons.timer_rounded,
            value: stats.formattedTime,
            label: 'وقت الاستماع',
            accent: accent,
            textColor: textColor,
            secondaryColor: secondaryColor,
          ),
          _StatItem(
            icon: Icons.calendar_today_rounded,
            value: '${stats.totalSessions}',
            label: 'جلسة',
            accent: accent,
            textColor: textColor,
            secondaryColor: secondaryColor,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accent;
  final Color textColor;
  final Color secondaryColor;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
    required this.textColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: accent, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.amiri(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.amiri(
            fontSize: 12,
            color: secondaryColor,
          ),
        ),
      ],
    );
  }
}

class _ReminderTile extends StatefulWidget {
  final Color accent;
  final Color textColor;
  final Color cardColor;

  const _ReminderTile({
    required this.accent,
    required this.textColor,
    required this.cardColor,
  });

  @override
  State<_ReminderTile> createState() => _ReminderTileState();
}

class _ReminderTileState extends State<_ReminderTile> {
  bool _enabled = false;
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);
  final _notifService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final enabled = await _notifService.isEnabled;
    final time = await _notifService.savedTime;
    if (mounted) {
      setState(() {
        _enabled = enabled;
        if (time != null) _time = time;
      });
    }
  }

  Future<void> _toggle(bool value) async {
    if (value) {
      await _notifService.scheduleDailyReminder(_time);
    } else {
      await _notifService.cancelReminder();
    }
    setState(() => _enabled = value);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _time = picked);
      if (_enabled) {
        await _notifService.scheduleDailyReminder(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.notifications_rounded, color: widget.accent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'تذكير يومي',
                  style:
                      GoogleFonts.amiri(fontSize: 16, color: widget.textColor),
                ),
              ),
              Switch(
                value: _enabled,
                onChanged: _toggle,
                activeColor: widget.accent,
              ),
            ],
          ),
          if (_enabled)
            GestureDetector(
              onTap: _pickTime,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 34),
                    Icon(Icons.access_time_rounded,
                        color: widget.accent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      timeStr,
                      style: GoogleFonts.amiri(
                        fontSize: 16,
                        color: widget.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'اضغط لتغيير الوقت',
                      style: GoogleFonts.amiri(
                        fontSize: 13,
                        color: widget.textColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  final ThemeMode themeMode;
  final Color accent;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeModeSelector({
    required this.themeMode,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThemeChip(
            label: 'نظام',
            icon: Icons.settings_suggest_rounded,
            isSelected: themeMode == ThemeMode.system,
            accent: accent,
            onTap: () => onChanged(ThemeMode.system),
          ),
          const SizedBox(width: 6),
          _ThemeChip(
            label: 'فاتح',
            icon: Icons.light_mode_rounded,
            isSelected: themeMode == ThemeMode.light,
            accent: accent,
            onTap: () => onChanged(ThemeMode.light),
          ),
          const SizedBox(width: 6),
          _ThemeChip(
            label: 'داكن',
            icon: Icons.dark_mode_rounded,
            isSelected: themeMode == ThemeMode.dark,
            accent: accent,
            onTap: () => onChanged(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  const _ThemeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? accent : accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? accent : accent.withValues(alpha: 0.2),
            ),
          ),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOutCubic,
            scale: isSelected ? 1.0 : 0.96,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : accent,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: GoogleFonts.amiri(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
