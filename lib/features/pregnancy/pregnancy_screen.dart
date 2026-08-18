import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/colors.dart';
import '../../core/models/pregnancy_profile.dart';
import '../../core/providers/providers.dart';

/// ─── LUXURY PREGNANCY JOURNEY & FETAL DEVELOPMENT COMPANION ─────────────────
///
/// Features:
/// 1. Due date & Gestational Age calculator (Weeks & Days).
/// 2. Interactive Trimester progress bar with visual milestones.
/// 3. Weekly fetal growth journey with fruit/veggie size comparisons.
/// 4. Interactive Kick Counter with live timer and kick session history.
/// 5. Smart Contraction Timer with frequency, duration, and 5-1-1 labor rule alert.
/// 6. Private pregnancy symptom journal & emotional milestones.
/// 7. 100% on-device private storage.
/// ────────────────────────────────────────────────────────────────────────────
class PregnancyScreen extends ConsumerStatefulWidget {
  const PregnancyScreen({super.key});

  @override
  ConsumerState<PregnancyScreen> createState() => _PregnancyScreenState();
}

class _PregnancyScreenState extends ConsumerState<PregnancyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showAddDueDate = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pregnancyProfile = ref.watch(pregnancyProfileProvider);
    final logs = ref.watch(pregnancyLogsProvider);
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: context.kCanvas,
      appBar: AppBar(
        title: Text(
          'Pregnancy Journey',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: context.kInk,
          ),
        ),
        actions: [
          if (pregnancyProfile != null)
            IconButton(
              icon: Icon(Icons.edit_calendar_outlined, color: context.kInk),
              onPressed: () => setState(() => _showAddDueDate = true),
              tooltip: 'Edit Due Date',
            ),
        ],
        bottom: pregnancyProfile == null
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: context.isDark ? KholoColors.magenta : KholoColors.plum,
                labelColor: context.isDark ? KholoColors.magenta : KholoColors.plum,
                unselectedLabelColor: context.kInkMuted,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.spa_outlined, size: 20), text: 'Development'),
                  Tab(icon: Icon(Icons.touch_app_outlined, size: 20), text: 'Kick Counter'),
                  Tab(icon: Icon(Icons.timer_outlined, size: 20), text: 'Contractions'),
                ],
              ),
      ),
      body: pregnancyProfile == null
          ? _NoDueDateState(
              onAddDueDate: () => setState(() => _showAddDueDate = true),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Development & Symptom Journal
                _buildDevelopmentTab(pregnancyProfile, logs, tt),

                // Tab 2: Interactive Kick Counter
                const _KickCounterView(),

                // Tab 3: Smart Contraction Timer
                const _ContractionTimerView(),
              ],
            ),
      bottomSheet: _showAddDueDate
          ? _DueDatePicker(
              initial: pregnancyProfile?.dueDate,
              onSave: (date) async {
                await ref
                    .read(pregnancyProfileProvider.notifier)
                    .save(PregnancyProfile(dueDate: date));
                setState(() => _showAddDueDate = false);
              },
              onCancel: () => setState(() => _showAddDueDate = false),
            )
          : null,
    );
  }

  Widget _buildDevelopmentTab(
      PregnancyProfile profile, List<PregnancyLog> logs, TextTheme tt) {
    final currentWeek = profile.currentWeek;
    final trimester = currentWeek <= 13 ? 1 : (currentWeek <= 26 ? 2 : 3);
    final milestone = getMilestoneForWeek(currentWeek);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        // 1. Hero Countdown & Trimester Card
        _CountdownHero(profile: profile, trimester: trimester),
        const SizedBox(height: 20),

        // 2. Fetal Growth Milestone Card
        if (milestone != null) ...[
          _WeeklyMilestoneCard(
            week: currentWeek,
            sizeName: milestone['size'] ?? 'Growing fast',
            detail: milestone['detail'] ?? 'Baby is developing quickly.',
          ),
          const SizedBox(height: 20),
        ],

        // 3. Symptom & Emotional Journal
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Symptom & Private Journal',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.kInk,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: context.kTint(KholoColors.lavender, lightAlpha: 0.15, darkAlpha: 0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('🔒 Private',
                  style: TextStyle(
                      fontSize: 11,
                      color: context.isDark ? KholoColors.blush : KholoColors.plum)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _AddJournalEntry(
          week: currentWeek,
          onSave: (log) => ref.read(pregnancyLogsProvider.notifier).add(log),
        ),
        const SizedBox(height: 12),

        if (logs.isEmpty)
          const _EmptyJournal()
        else
          ...logs.reversed.map((log) => _JournalEntryCard(log: log)),

        const SizedBox(height: 24),

        // Medical Educational Disclaimer
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.kDivider),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: context.kInkSubtle, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'KHOLO provides supportive educational tracking. For clinical concerns or labor advice, always reach out to your OB/GYN or certified midwife.',
                  style: tt.bodySmall?.copyWith(color: context.kInkSubtle, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── COUNTDOWN HERO ────────────────────────────────────────────────────────────
class _CountdownHero extends StatelessWidget {
  final PregnancyProfile profile;
  final int trimester;

  const _CountdownHero({required this.profile, required this.trimester});

  @override
  Widget build(BuildContext context) {
    final week = profile.currentWeek;
    final progress = (week / 40.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: context.isDark
              ? [
                  KholoColors.rose.withValues(alpha: 0.22),
                  context.kCard,
                ]
              : const [Color(0xFFF9EAE1), Color(0xFFF0E5EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: KholoColors.rose.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: context.isDark
                ? Colors.black.withValues(alpha: 0.3)
                : KholoColors.rose.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WEEK $week OF 40',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: context.isDark ? KholoColors.blush : KholoColors.plum,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Trimester $trimester',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: context.kInk,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? context.kCardElevated
                      : Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: KholoColors.rose.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${profile.daysRemaining} days left',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: context.isDark ? KholoColors.blush : KholoColors.plum,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Trimester Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: context.isDark
                  ? context.kCardElevated
                  : Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(KholoColors.rose),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1st Trimester', style: GoogleFonts.inter(fontSize: 10, color: context.kInkMuted)),
              Text('2nd Trimester', style: GoogleFonts.inter(fontSize: 10, color: context.kInkMuted)),
              Text('3rd Trimester', style: GoogleFonts.inter(fontSize: 10, color: context.kInkMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── WEEKLY MILESTONE CARD ────────────────────────────────────────────────────
class _WeeklyMilestoneCard extends StatelessWidget {
  final int week;
  final String sizeName;
  final String detail;

  const _WeeklyMilestoneCard({
    required this.week,
    required this.sizeName,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.kCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.kDivider),
        boxShadow: [
          BoxShadow(
            color: context.isDark
                ? Colors.black.withValues(alpha: 0.3)
                : KholoColors.wine.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: context.kTint(KholoColors.sage, lightAlpha: 0.2, darkAlpha: 0.25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('🥑', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Baby is about the size of a $sizeName',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.kInk,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  detail,
                  style: GoogleFonts.inter(
                    fontSize: 13,
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

// ── 2. INTERACTIVE KICK COUNTER VIEW ─────────────────────────────────────────
class _KickCounterView extends StatefulWidget {
  const _KickCounterView();

  @override
  State<_KickCounterView> createState() => _KickCounterViewState();
}

class _KickCounterViewState extends State<_KickCounterView> {
  int _kicks = 0;
  bool _isSessionActive = false;
  Timer? _timer;
  int _secondsElapsed = 0;
  final List<Map<String, dynamic>> _history = [];

  void _startOrKick() {
    HapticFeedback.lightImpact();
    if (!_isSessionActive) {
      _isSessionActive = true;
      _kicks = 1;
      _secondsElapsed = 0;
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (mounted) setState(() => _secondsElapsed++);
      });
    } else {
      setState(() => _kicks++);
      if (_kicks >= 10) {
        _finishSession();
      }
    }
  }

  void _finishSession() {
    HapticFeedback.heavyImpact();
    _timer?.cancel();
    if (_kicks > 0) {
      _history.insert(0, {
        'date': DateTime.now(),
        'kicks': _kicks,
        'durationSeconds': _secondsElapsed,
      });
    }
    setState(() {
      _isSessionActive = false;
      _kicks = 0;
      _secondsElapsed = 0;
    });
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Instructions Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.kTint(KholoColors.lavender, lightAlpha: 0.15, darkAlpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.kDivider),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  color: context.isDark ? KholoColors.warmGold : KholoColors.plum),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Track fetal movement: doctors often recommend counting 10 kicks in 2 hours when baby is active.',
                  style: GoogleFonts.inter(color: context.kInk, fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Central Kick Tap Circle
        Center(
          child: GestureDetector(
            onTap: _startOrKick,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [KholoColors.rose, KholoColors.plum],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: KholoColors.rose.withValues(alpha: 0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('👶', style: TextStyle(fontSize: _isSessionActive ? 36 : 42)),
                    const SizedBox(height: 6),
                    Text(
                      _isSessionActive ? '$_kicks Kicks' : 'Tap to Start',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_isSessionActive)
                      Text(
                        _formatTime(_secondsElapsed),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        if (_isSessionActive)
          Center(
            child: TextButton.icon(
              onPressed: _finishSession,
              icon: Icon(Icons.check_circle_outline,
                  color: context.isDark ? KholoColors.blush : KholoColors.plum),
              label: Text('Save & Finish Session',
                  style: TextStyle(
                      color: context.isDark ? KholoColors.blush : KholoColors.plum,
                      fontWeight: FontWeight.w700)),
            ),
          ),

        const SizedBox(height: 24),

        // Session History
        Text(
          'Recent Kick Sessions',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.kInk,
          ),
        ),
        const SizedBox(height: 12),

        if (_history.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.kCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.kDivider),
            ),
            child: Center(
              child: Text('No recorded kick sessions yet today.',
                  style: TextStyle(color: context.kInkMuted)),
            ),
          )
        else
          ..._history.map((s) {
            final date = s['date'] as DateTime;
            final count = s['kicks'] as int;
            final dur = s['durationSeconds'] as int;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: context.kCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.kDivider),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.favorite_rounded, color: KholoColors.rose, size: 20),
                      const SizedBox(width: 12),
                      Text('$count kicks counted',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.kInk)),
                    ],
                  ),
                  Text('${_formatTime(dur)} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(color: context.kInkMuted, fontSize: 12)),
                ],
              ),
            );
          }),
      ],
    );
  }
}

// ── 3. SMART CONTRACTION TIMER VIEW ──────────────────────────────────────────
class _ContractionTimerView extends StatefulWidget {
  const _ContractionTimerView();

  @override
  State<_ContractionTimerView> createState() => _ContractionTimerViewState();
}

class _ContractionTimerViewState extends State<_ContractionTimerView> {
  bool _isTiming = false;
  Timer? _timer;
  int _currentSeconds = 0;
  DateTime? _startTime;

  final List<Map<String, dynamic>> _contractions = [];

  void _toggleTiming() {
    HapticFeedback.heavyImpact();
    if (!_isTiming) {
      _startTime = DateTime.now();
      _currentSeconds = 0;
      _isTiming = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (mounted) setState(() => _currentSeconds++);
      });
    } else {
      _timer?.cancel();
      final durationSec = _currentSeconds;

      int intervalSec = 0;
      if (_contractions.isNotEmpty) {
        final lastStart = _contractions.first['start'] as DateTime;
        intervalSec = _startTime!.difference(lastStart).inSeconds;
      }

      _contractions.insert(0, {
        'start': _startTime!,
        'durationSec': durationSec,
        'intervalSec': intervalSec,
      });

      setState(() {
        _isTiming = false;
        _currentSeconds = 0;
      });
    }
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 5-1-1 Rule Helper Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.kCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.kDivider),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.health_and_safety_outlined, color: KholoColors.terracotta),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '5-1-1 Labor Rule',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: KholoColors.terracotta),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'If contractions arrive 5 minutes apart, lasting 1 minute each, for over 1 hour, contact your birthing team immediately.',
                      style: GoogleFonts.inter(fontSize: 12, color: context.kInkMuted, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Timer Trigger Button
        Center(
          child: GestureDetector(
            onTap: _toggleTiming,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isTiming ? Colors.redAccent : KholoColors.terracotta,
                boxShadow: [
                  BoxShadow(
                    color: (_isTiming ? Colors.redAccent : KholoColors.terracotta).withValues(alpha: 0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isTiming ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                    Text(
                      _isTiming ? _formatTime(_currentSeconds) : 'Start Contraction',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Contraction Records List
        Text(
          'Contraction History',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.kInk,
          ),
        ),
        const SizedBox(height: 12),

        if (_contractions.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.kCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.kDivider),
            ),
            child: Center(
              child: Text('No contractions recorded yet.', style: TextStyle(color: context.kInkMuted)),
            ),
          )
        else
          ..._contractions.map((c) {
            final dur = c['durationSec'] as int;
            final interval = c['intervalSec'] as int;
            final start = c['start'] as DateTime;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.kCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.kDivider),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Duration: ${_formatTime(dur)}',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: context.kInk),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        interval > 0 ? 'Interval: ${_formatTime(interval)} apart' : 'Initial surge',
                        style: GoogleFonts.inter(color: context.kInkMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  Text(
                    '${start.hour}:${start.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(color: context.kInkSubtle, fontSize: 12),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

// ── SYMPTOM JOURNAL HELPERS ──────────────────────────────────────────────────
class _AddJournalEntry extends StatefulWidget {
  final int week;
  final ValueChanged<PregnancyLog> onSave;

  const _AddJournalEntry({required this.week, required this.onSave});

  @override
  State<_AddJournalEntry> createState() => _AddJournalEntryState();
}

class _AddJournalEntryState extends State<_AddJournalEntry> {
  final _noteCtrl = TextEditingController();
  final List<String> _selectedSymptoms = [];

  static const _availableSymptoms = [
    'Morning sickness',
    'Fatigue',
    'Heartburn',
    'Back pain',
    'Braxton Hicks',
    'Glowing mood',
    'Cravings',
    'Swollen feet',
  ];

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_noteCtrl.text.trim().isEmpty && _selectedSymptoms.isEmpty) return;
    HapticFeedback.lightImpact();
    final log = PregnancyLog(
      pregnancyWeek: widget.week,
      eventDate: DateTime.now(),
      symptoms: List.from(_selectedSymptoms),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
    widget.onSave(log);
    setState(() {
      _noteCtrl.clear();
      _selectedSymptoms.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How are you feeling this week?',
            style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: context.kInk),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableSymptoms.map((s) {
              final isSel = _selectedSymptoms.contains(s);
              return FilterChip(
                label: Text(s,
                    style: TextStyle(
                        fontSize: 12,
                        color: isSel ? Colors.white : context.kInk)),
                selected: isSel,
                selectedColor: KholoColors.plum,
                backgroundColor: context.isDark
                    ? context.kCardElevated
                    : KholoColors.cream,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSymptoms.add(s);
                    } else {
                      _selectedSymptoms.remove(s);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            style: TextStyle(color: context.kInk),
            decoration: InputDecoration(
              hintText: 'Add a private reflection or note...',
              hintStyle: TextStyle(color: context.kInkSubtle, fontSize: 13),
              filled: true,
              fillColor: context.kSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: KholoColors.plum,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Reflection'),
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  final PregnancyLog log;
  const _JournalEntryCard({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Week ${log.pregnancyWeek}',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: context.isDark ? KholoColors.blush : KholoColors.plum),
              ),
              Text(
                '${log.eventDate.day}/${log.eventDate.month}/${log.eventDate.year}',
                style: TextStyle(color: context.kInkSubtle, fontSize: 12),
              ),
            ],
          ),
          if (log.symptoms.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: log.symptoms
                  .map((s) => Chip(
                        label: Text(s,
                            style: TextStyle(
                                fontSize: 10,
                                color: context.isDark ? KholoColors.blush : KholoColors.plum)),
                        backgroundColor: context.kTint(KholoColors.lavender,
                            lightAlpha: 0.15, darkAlpha: 0.25),
                        padding: EdgeInsets.zero,
                      ))
                  .toList(),
            ),
          ],
          if (log.note != null) ...[
            const SizedBox(height: 8),
            Text(log.note!,
                style: GoogleFonts.inter(
                    color: context.kInk, fontSize: 13, height: 1.4)),
          ],
        ],
      ),
    );
  }
}

class _EmptyJournal extends StatelessWidget {
  const _EmptyJournal();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.kDivider),
      ),
      child: Center(
        child: Text('No journal entries yet. Log how your body feels today.',
            style: TextStyle(color: context.kInkMuted, fontSize: 13)),
      ),
    );
  }
}

// ── INITIAL DUE DATE ENTRY STATE ─────────────────────────────────────────────
class _NoDueDateState extends StatelessWidget {
  final VoidCallback onAddDueDate;
  const _NoDueDateState({required this.onAddDueDate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.kTint(KholoColors.rose, lightAlpha: 0.2, darkAlpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.child_friendly_rounded, color: KholoColors.rose, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'Pregnancy Companion',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: context.kInk),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your baby\'s weekly development, count kicks, and time contractions with privacy.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: context.kInkMuted, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddDueDate,
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: const Text('Set Estimated Due Date'),
              style: ElevatedButton.styleFrom(
                backgroundColor: KholoColors.plum,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DueDatePicker extends StatelessWidget {
  final DateTime? initial;
  final ValueChanged<DateTime> onSave;
  final VoidCallback onCancel;

  const _DueDatePicker({
    this.initial,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.kSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select Estimated Due Date',
            style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.kInk),
          ),
          const SizedBox(height: 16),
          CalendarDatePicker(
            initialDate: initial ?? DateTime.now().add(const Duration(days: 200)),
            firstDate: DateTime.now().subtract(const Duration(days: 60)),
            lastDate: DateTime.now().add(const Duration(days: 300)),
            onDateChanged: onSave,
          ),
        ],
      ),
    );
  }
}
