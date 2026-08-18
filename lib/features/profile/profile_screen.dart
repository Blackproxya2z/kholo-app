import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/colors.dart';
import '../../core/models/health_profile.dart';
import '../../core/providers/providers.dart';
import '../../core/providers/app_settings_provider.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/export_service.dart';
import '../../core/providers/sync_provider.dart';
import '../../core/services/sync_engine_service.dart';
import '../../core/services/update_service.dart';
import '../../core/services/notification_service.dart';
import '../../shared/widgets/update_dialog.dart';
import '../../shared/widgets/kholo_animated_loader.dart';
import 'widgets/health_baseline_sheet.dart';

/// Profile and privacy settings screen.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final profile = ref.watch(healthProfileProvider);
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: context.kCanvas,
      appBar: AppBar(
        title: Text('Profile & privacy', style: TextStyle(color: context.kInk)),
        actions: [
          TextButton(
            onPressed: () => ref.read(authProvider.notifier).signOut(),
            child: const Text('Sign out', style: TextStyle(color: KholoColors.error)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // Avatar & name
          _ProfileHeader(email: user ?? ''),
          const SizedBox(height: 24),

          // Health baseline
          const _SectionTitle('Health baseline'),
          const SizedBox(height: 12),
          _ProfileCard(
            children: [
              _EditableRow(
                label: 'Cycle length',
                value: '${profile.safeCycleLength} days',
                icon: Icons.cached_rounded,
                onEdit: () => _editCycleLength(context, ref, profile),
              ),
              _EditableRow(
                label: 'Period length',
                value: '${profile.safePeriodLength} days',
                icon: Icons.water_drop_outlined,
                onEdit: () => _editPeriodLength(context, ref, profile),
              ),
              _EditableRow(
                label: 'Last period start',
                value: profile.lastPeriodDate != null
                    ? _fmtDate(profile.lastPeriodDate!)
                    : 'Not set',
                icon: Icons.calendar_today_outlined,
                onEdit: () => _editLastPeriod(context, ref, profile),
              ),
              _EditableRow(
                label: 'Age range',
                value: profile.ageRange ?? 'Not set',
                icon: Icons.person_outline_rounded,
                onEdit: () => _editAgeRange(context, ref, profile),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Wellness & Cycle Metrics
          const _SectionTitle('Cycle wellness & metrics'),
          const SizedBox(height: 12),
          _ProfileCard(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: KholoColors.divider)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: KholoColors.blush.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.medical_services_outlined,
                          color: KholoColors.wine, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PCOS / PCOD support mode', style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          Text('Adapts algorithms for irregular cycle lengths',
                              style: tt.bodySmall?.copyWith(color: KholoColors.inkMuted)),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: profile.hasPcosPcod,
                      activeTrackColor: KholoColors.wine,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        ref.read(healthProfileProvider.notifier).update(
                              (p) => p.copyWith(hasPcosPcod: val),
                            );
                      },
                    ),
                  ],
                ),
              ),
              _EditableRow(
                label: 'Daily water goal',
                value: '${profile.dailyWaterGoalMl} ml',
                icon: Icons.local_drink_outlined,
                onEdit: () => _editWaterGoal(context, ref, profile),
              ),
              _EditableRow(
                label: 'Target sleep',
                value: '${profile.targetSleepHours.toStringAsFixed(1)} hrs',
                icon: Icons.bedtime_outlined,
                onEdit: () => _editSleepGoal(context, ref, profile),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const SizedBox(height: 20),

          // Life stage
          const _SectionTitle('Life stage'),
          const SizedBox(height: 12),
          _ProfileCard(
            children: LifeStage.values.map((s) {
              final isSelected = profile.lifeStage == s;
              return GestureDetector(
                onTap: () => ref.read(healthProfileProvider.notifier).update(
                      (p) => p.copyWith(lifeStage: s),
                    ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: KholoColors.divider),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(s.displayName, style: tt.bodyMedium)),
                      if (isSelected)
                        const Icon(Icons.check_rounded,
                            color: KholoColors.plum, size: 18),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // ── App Settings & Theme ─────────────────────────────────────
          const _SectionTitle('Appearance & theme'),
          const SizedBox(height: 12),
          const _ThemeSelectorCard(),

          const SizedBox(height: 20),

          const _SectionTitle('Security & updates'),
          const SizedBox(height: 12),
          _ProfileCard(
            children: [
              _BiometricToggleRow(
                value: ref.watch(appSettingsProvider).biometricLock,
                onChanged: (v) async {
                  if (v) {
                    // Verify biometric before enabling
                    final ok = await BiometricService.authenticate(
                        reason: 'Confirm your identity to enable app lock');
                    if (!ok) return;
                  }
                  HapticFeedback.selectionClick();
                  await ref.read(appSettingsProvider.notifier).setBiometricLock(v);
                },
              ),
              const Divider(height: 1, indent: 44),
              _ActionRow(
                icon: Icons.system_update_rounded,
                label: 'Check for updates',
                color: KholoColors.wine,
                onTap: () async {
                  HapticFeedback.lightImpact();
                  KholoAnimatedLoader.show(context, message: 'Checking for updates...');
                  final code = await UpdateService.currentVersionCode();
                  final update = await UpdateService.checkForUpdate();
                  if (context.mounted) {
                    KholoAnimatedLoader.hide(context);
                    if (update != null) {
                      UpdateDialog.show(context, update, currentVersionCode: code);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🌸 You\'re on the latest version of KHOLO!'),
                          backgroundColor: KholoColors.wine,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Real-Time Cloud Sync & Security ──────────────────────────
          const _SectionTitle('Cloud sync & security'),
          const SizedBox(height: 12),
          const _SyncStatusCard(),

          const SizedBox(height: 20),

          // Data and privacy
          const _SectionTitle('Your data & privacy'),
          const SizedBox(height: 12),
          _ProfileCard(
            children: [
              const _StaticRow(
                icon: Icons.lock_outline_rounded,
                label: 'Your data stays on your device',
                subtitle: 'Health info is not shared with payment systems or advertisers.',
              ),
              _ActionRow(
                icon: Icons.download_outlined,
                label: 'Export cycle data as CSV',
                color: KholoColors.plum,
                onTap: () {
                  final logs = ref.read(cycleLogsProvider);
                  ExportService.exportCycleLogs(context, logs);
                },
              ),
              _ActionRow(
                icon: Icons.delete_outline_rounded,
                label: 'Delete my account and data',
                color: KholoColors.error,
                onTap: () => _showDeleteDialog(context, ref),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Pregnancy & baby modules
          const _SectionTitle('Modules'),
          const SizedBox(height: 12),
          _ProfileCard(
            children: [
              _ActionRow(
                icon: Icons.child_friendly_outlined,
                label: 'Pregnancy settings',
                color: KholoColors.rose,
                onTap: () => context.go('/pregnancy'),
              ),
              _ActionRow(
                icon: Icons.child_care_outlined,
                label: 'Baby profiles',
                color: KholoColors.sage,
                onTap: () => context.go('/baby'),
              ),
              _ActionRow(
                icon: Icons.insights_outlined,
                label: 'View insights',
                color: KholoColors.lavender,
                onTap: () => context.go('/insights'),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // App Updates & Version
          const _SectionTitle('App version & updates'),
          const SizedBox(height: 12),
          _ProfileCard(
            children: [
              _ActionRow(
                icon: Icons.system_update_rounded,
                label: 'Check for updates & send alert',
                color: KholoColors.wine,
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  final currentCode = await UpdateService.currentVersionCode();
                  final currentName = await UpdateService.currentVersionName();
                  final update = await UpdateService.checkForUpdate();
                  if (update != null && update.isNewerThan(currentCode, currentName)) {
                    await NotificationService.showUpdateNotification(
                      version: update.latestVersion,
                      versionCode: update.versionCode,
                      releaseNotes: update.releaseNotes,
                      force: true,
                    );
                    if (context.mounted) {
                      context.go('/update', extra: {
                        'update': update,
                        'currentVersionCode': currentCode,
                        'currentVersionName': currentName,
                      });
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'You are on the latest version of KHOLO (v$currentName build $currentCode).'),
                          backgroundColor: KholoColors.wine,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.isDark
                  ? context.kCardElevated
                  : KholoColors.lavenderLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: (context.isDark
                          ? KholoColors.magenta
                          : KholoColors.lavender)
                      .withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        color: context.isDark
                            ? KholoColors.magenta
                            : KholoColors.plum,
                        size: 18),
                    const SizedBox(width: 8),
                    Text('Health disclaimer',
                        style: tt.titleSmall?.copyWith(
                            color: context.isDark
                                ? KholoColors.blush
                                : KholoColors.plum)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'KHOLO provides self-tracking tools and educational content. It does not diagnose conditions, replace contraception, or substitute for clinical care. All cycle and fertility estimates are based on your input data.\n\nFor any health concerns, please contact a qualified healthcare provider.',
                  style: tt.bodySmall
                      ?.copyWith(color: context.kInkMuted, height: 1.6),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
            child: Center(
              child: Text(
                'Developed by Azmain',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5) ?? Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Edit dialogs ──────────────────────────────────────────────────────────

  void _editCycleLength(BuildContext ctx, WidgetRef ref, HealthProfile p) {
    HealthBaselineSheet.show(
      ctx,
      title: 'Cycle length',
      description: 'Average days from one period start to the next.',
      initialValue: p.safeCycleLength.toDouble(),
      min: 20,
      max: 45,
      unit: 'days',
      icon: Icons.cached_rounded,
      tooltipText:
          'A typical cycle lasts between 21 and 35 days. Tracking this accurately helps predict your fertile window and next period with higher precision.',
      onSave: (val) => ref
          .read(healthProfileProvider.notifier)
          .update((p) => p.copyWith(cycleLength: val)),
    );
  }

  void _editPeriodLength(BuildContext ctx, WidgetRef ref, HealthProfile p) {
    HealthBaselineSheet.show(
      ctx,
      title: 'Period length',
      description: 'Number of active bleeding days each cycle.',
      initialValue: p.safePeriodLength.toDouble(),
      min: 2,
      max: 10,
      unit: 'days',
      icon: Icons.water_drop_outlined,
      tooltipText:
          'Bleeding typically lasts 3 to 7 days. Knowing your duration lets the app estimate when your follicular phase begins.',
      onSave: (val) => ref
          .read(healthProfileProvider.notifier)
          .update((p) => p.copyWith(periodLength: val)),
    );
  }

  void _editWaterGoal(BuildContext ctx, WidgetRef ref, HealthProfile p) {
    HealthBaselineSheet.show(
      ctx,
      title: 'Daily water goal',
      description: 'Target daily hydration to support hormonal balance.',
      initialValue: p.dailyWaterGoalMl.toDouble(),
      min: 1000,
      max: 4000,
      unit: 'ml',
      icon: Icons.local_drink_outlined,
      tooltipText:
          'Adequate hydration helps reduce bloating, eases menstrual cramps, and supports optimal energy during luteal phase.',
      onSave: (val) => ref
          .read(healthProfileProvider.notifier)
          .update((p) => p.copyWith(dailyWaterGoalMl: val)),
    );
  }

  void _editSleepGoal(BuildContext ctx, WidgetRef ref, HealthProfile p) {
    HealthBaselineSheet.show(
      ctx,
      title: 'Target sleep',
      description: 'Target nightly rest hours for hormonal recovery.',
      initialValue: p.targetSleepHours,
      min: 5,
      max: 12,
      unit: 'hours',
      icon: Icons.bedtime_outlined,
      tooltipText:
          'Consistent quality sleep regulates melatonin and cortisol, essential for stable estrogen and progesterone rhythms.',
      onSave: (val) => ref
          .read(healthProfileProvider.notifier)
          .update((p) => p.copyWith(targetSleepHours: val.toDouble())),
    );
  }

  void _editLastPeriod(BuildContext ctx, WidgetRef ref, HealthProfile p) async {
    final d = await showDatePicker(
      context: ctx,
      initialDate: p.lastPeriodDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      ref
          .read(healthProfileProvider.notifier)
          .update((p) => p.copyWith(lastPeriodDate: d));
    }
  }

  void _editAgeRange(BuildContext ctx, WidgetRef ref, HealthProfile p) {
    const ranges = ['Under 18', '18–24', '25–34', '35–44', '45–54', '55+'];
    showDialog(
      context: ctx,
      builder: (dialogCtx) => SimpleDialog(
        title: const Text('Age range'),
        children: ranges.map((r) {
          final isSelected = p.ageRange == r;
          return SimpleDialogOption(
            onPressed: () {
              ref.read(healthProfileProvider.notifier).update(
                    (p) => p.copyWith(ageRange: r),
                  );
              Navigator.of(dialogCtx).pop();
            },
            child: Row(
              children: [
                Expanded(child: Text(r)),
                if (isSelected)
                  const Icon(Icons.check_rounded, color: KholoColors.plum, size: 16),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }



  void _showDeleteDialog(BuildContext ctx, WidgetRef ref) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Delete account and data?'),
        content: const Text(
          'This will erase all your health logs, baby profiles, and account information. This action cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: KholoColors.error),
            onPressed: () async {
              await ref.read(localStorageProvider).clearAllData();
              await ref.read(authProvider.notifier).signOut();
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ── Shared profile widgets ────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final initials =
        email.isNotEmpty ? email.substring(0, 1).toUpperCase() : 'K';

    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: context.isDark
                ? context.kCardElevated
                : KholoColors.lavenderLight,
            shape: BoxShape.circle,
            border: Border.all(color: context.kDivider),
          ),
          child: Center(
            child: Text(
              initials,
              style: GoogleFonts.playfairDisplay(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: context.isDark ? KholoColors.blush : KholoColors.plum,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your private space',
                  style: tt.titleLarge?.copyWith(color: context.kInk)),
              Text(email,
                  style: tt.bodySmall?.copyWith(color: context.kInkMuted),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: context.kInkSubtle,
              fontWeight: FontWeight.w700,
            ),
      );
}

class _ThemeSelectorCard extends ConsumerWidget {
  const _ThemeSelectorCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPref = ref.watch(appSettingsProvider).themePreference;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.kDivider),
        boxShadow: [
          BoxShadow(
            color: context.isDark
                ? Colors.black.withValues(alpha: 0.3)
                : KholoColors.wine.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.kTint(KholoColors.magenta),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.palette_outlined,
                    color: KholoColors.magenta, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Theme',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.kInk,
                      ),
                    ),
                    Text(
                      switch (currentPref) {
                        AppThemePreference.light => 'Light porcelain ambiance',
                        AppThemePreference.dark => 'Deep velvet night wellness',
                        AppThemePreference.system => 'Automatically sync with device',
                      },
                      style: TextStyle(
                        fontSize: 12,
                        color: context.kInkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 3-Way Segmented Selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: context.kSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.kDivider),
            ),
            child: Row(
              children: [
                _ThemeOptionButton(
                  title: 'Light',
                  icon: Icons.light_mode_rounded,
                  selected: currentPref == AppThemePreference.light,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref
                        .read(appSettingsProvider.notifier)
                        .setThemePreference(AppThemePreference.light);
                  },
                ),
                _ThemeOptionButton(
                  title: 'Dark',
                  icon: Icons.dark_mode_rounded,
                  selected: currentPref == AppThemePreference.dark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref
                        .read(appSettingsProvider.notifier)
                        .setThemePreference(AppThemePreference.dark);
                  },
                ),
                _ThemeOptionButton(
                  title: 'System',
                  icon: Icons.brightness_auto_rounded,
                  selected: currentPref == AppThemePreference.system,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref
                        .read(appSettingsProvider.notifier)
                        .setThemePreference(AppThemePreference.system);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionButton extends StatelessWidget {
  const _ThemeOptionButton({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? KholoColors.wine : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: KholoColors.wine.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? Colors.white
                    : context.kInkMuted,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : context.kInkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.kDivider),
        boxShadow: [
          BoxShadow(
            color: context.isDark
                ? Colors.black.withValues(alpha: 0.25)
                : KholoColors.wine.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _EditableRow extends StatelessWidget {
  const _EditableRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.onEdit,
  });
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.kDivider)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.kInkSubtle),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: tt.bodyMedium?.copyWith(color: context.kInk),
            ),
          ),
          Text(
            value,
            style: tt.bodyMedium?.copyWith(
              color: KholoColors.magenta,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onEdit,
            child: Icon(Icons.edit_outlined,
                size: 16, color: context.kInkSubtle),
          ),
        ],
      ),
    );
  }
}

class _StaticRow extends StatelessWidget {
  const _StaticRow(
      {required this.icon, required this.label, required this.subtitle});
  final IconData icon;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.kDivider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: KholoColors.magenta),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.kInk,
                  ),
                ),
                Text(
                  subtitle,
                  style: tt.bodySmall?.copyWith(
                    color: context.kInkMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.kDivider)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: tt.bodyMedium?.copyWith(color: color)),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: color),
          ],
        ),
      ),
    );
  }
}

class _BiometricToggleRow extends StatefulWidget {
  const _BiometricToggleRow({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  State<_BiometricToggleRow> createState() => _BiometricToggleRowState();
}

class _BiometricToggleRowState extends State<_BiometricToggleRow> {
  bool _available = false;

  @override
  void initState() {
    super.initState();
    BiometricService.isAvailable().then((v) {
      if (mounted) setState(() => _available = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.kTint(KholoColors.rose),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fingerprint_rounded,
                color: KholoColors.rose, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Biometric lock',
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.kInk,
                  ),
                ),
                Text(
                  _available
                      ? 'Require fingerprint/face to open app'
                      : 'Not available on this device',
                  style: tt.bodySmall?.copyWith(color: context.kInkMuted),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: widget.value,
            activeTrackColor: KholoColors.wine,
            onChanged: _available ? widget.onChanged : null,
          ),
        ],
      ),
    );
  }
}

class _SyncStatusCard extends ConsumerWidget {
  const _SyncStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.kDivider),
        boxShadow: [
          BoxShadow(
            color: context.isDark
                ? Colors.black.withValues(alpha: 0.25)
                : KholoColors.wine.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _statusColor(syncState.status).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _statusIcon(syncState.status),
                  color: _statusColor(syncState.status),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      syncState.statusDisplay,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.kInk,
                      ),
                    ),
                    Text(
                      syncState.lastSyncedAt != null
                          ? 'Last synced ${_formatSyncTime(syncState.lastSyncedAt!)}'
                          : 'Local changes are preserved offline',
                      style: tt.bodySmall?.copyWith(color: context.kInkMuted),
                    ),
                  ],
                ),
              ),
              if (syncState.status == SyncStatus.syncing)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.isDark ? KholoColors.magenta : KholoColors.wine,
                  ),
                )
              else
                IconButton(
                  icon: Icon(Icons.sync_rounded,
                      color: context.isDark ? KholoColors.magenta : KholoColors.wine),
                  tooltip: 'Sync now',
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ref.read(syncProvider.notifier).triggerSync();
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: context.isDark
                  ? context.kCardElevated
                  : KholoColors.lavenderLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_outlined,
                    size: 14,
                    color: context.isDark ? KholoColors.blush : KholoColors.plum),
                const SizedBox(width: 6),
                Text(
                  'End-to-end device storage integrity',
                  style: tt.labelSmall?.copyWith(
                    color: context.isDark ? KholoColors.blush : KholoColors.plum,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _statusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
      case SyncStatus.idle:
        return const Color(0xFF2E7D32);
      case SyncStatus.syncing:
        return KholoColors.wine;
      case SyncStatus.offline:
        return const Color(0xFFE65100);
      case SyncStatus.error:
        return KholoColors.error;
    }
  }

  static IconData _statusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
      case SyncStatus.idle:
        return Icons.cloud_done_outlined;
      case SyncStatus.syncing:
        return Icons.cloud_sync_outlined;
      case SyncStatus.offline:
        return Icons.cloud_off_outlined;
      case SyncStatus.error:
        return Icons.error_outline_rounded;
    }
  }

  static String _formatSyncTime(DateTime dt) {
    final diff = DateTime.now().toUtc().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

