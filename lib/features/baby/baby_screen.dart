import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/colors.dart';
import '../../core/models/baby_profile.dart';
import '../../core/providers/providers.dart';

/// ─── LUXURY BABY & POSTPARTUM CARE TRACKER ─────────────────────────────────
///
/// Features:
/// 1. Baby profile management with age in months/weeks.
/// 2. Interactive Feed log (Left/Right Breast, Formula, Solids, ml amount).
/// 3. Live Nap/Sleep Stopwatch with quick duration calculation.
/// 4. Diaper tracker (Wet, Dirty, Mixed, Dry) with instant one-tap logging.
/// 5. Weight & Length growth metrics tracker.
/// 6. Developmental milestones checklist.
/// 7. Full Dark & Light luxury theme tokens.
/// ────────────────────────────────────────────────────────────────────────────
class BabyScreen extends ConsumerStatefulWidget {
  const BabyScreen({super.key});

  @override
  ConsumerState<BabyScreen> createState() => _BabyScreenState();
}

class _BabyScreenState extends ConsumerState<BabyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedBabyId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final babies = ref.watch(babyProfilesProvider);

    if (babies.isNotEmpty && _selectedBabyId == null) {
      _selectedBabyId = babies.first.id;
    }

    final activeBaby = babies.where((b) => b.id == _selectedBabyId).firstOrNull ??
        babies.firstOrNull;

    return Scaffold(
      backgroundColor: context.kCanvas,
      appBar: AppBar(
        title: Text(
          activeBaby != null ? '${activeBaby.name}’s Care' : 'Baby Care',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            color: context.kInk,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: context.kInk),
            tooltip: 'Add Baby Profile',
            onPressed: () => _openAddBabySheet(context),
          ),
        ],
        bottom: activeBaby == null
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: context.isDark ? KholoColors.magenta : KholoColors.plum,
                labelColor: context.isDark ? KholoColors.magenta : KholoColors.plum,
                unselectedLabelColor: context.kInkMuted,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.local_drink_outlined, size: 18), text: 'Feeding'),
                  Tab(icon: Icon(Icons.bedtime_outlined, size: 18), text: 'Sleep'),
                  Tab(icon: Icon(Icons.baby_changing_station_rounded, size: 18), text: 'Diaper'),
                  Tab(icon: Icon(Icons.show_chart_rounded, size: 18), text: 'Growth'),
                  Tab(icon: Icon(Icons.stars_rounded, size: 18), text: 'Milestones'),
                ],
              ),
      ),
      body: activeBaby == null
          ? _NoBabyState(onAdd: () => _openAddBabySheet(context))
          : Column(
              children: [
                if (babies.length > 1)
                  _BabySelector(
                    babies: babies,
                    selectedId: _selectedBabyId,
                    onSelect: (id) => setState(() => _selectedBabyId = id),
                  ),
                _BabyHeroHeader(baby: activeBaby),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _FeedTab(baby: activeBaby),
                      _SleepTab(baby: activeBaby),
                      _DiaperTab(baby: activeBaby),
                      _GrowthTab(baby: activeBaby),
                      _MilestoneTab(baby: activeBaby),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _openAddBabySheet(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _AddBabySheet(
        onSave: (baby) {
          ref.read(babyProfilesProvider.notifier).add(baby);
          setState(() => _selectedBabyId = baby.id);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ── BABY HERO HEADER ─────────────────────────────────────────────────────────
class _BabyHeroHeader extends StatelessWidget {
  final BabyProfile baby;
  const _BabyHeroHeader({required this.baby});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: context.kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.kDivider),
        boxShadow: [
          BoxShadow(
            color: KholoColors.wine.withValues(alpha: context.isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.isDark
                  ? KholoColors.magenta.withValues(alpha: 0.2)
                  : KholoColors.lavenderLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.child_care_rounded,
              color: context.isDark ? KholoColors.magenta : KholoColors.plum,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baby.name,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.kInk,
                  ),
                ),
                Text(
                  baby.ageDisplay,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: context.kInkMuted,
                    fontWeight: FontWeight.w500,
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

// ── BABY SELECTOR ────────────────────────────────────────────────────────────
class _BabySelector extends StatelessWidget {
  final List<BabyProfile> babies;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _BabySelector({
    required this.babies,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: babies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final b = babies[index];
          final isSel = b.id == selectedId;
          return ChoiceChip(
            label: Text(b.name),
            selected: isSel,
            selectedColor: context.isDark ? KholoColors.magenta : KholoColors.plum,
            labelStyle: TextStyle(
              color: isSel ? Colors.white : context.kInk,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            backgroundColor: context.kCard,
            onSelected: (_) {
              HapticFeedback.selectionClick();
              onSelect(b.id);
            },
          );
        },
      ),
    );
  }
}

// ── 1. FEED TAB ──────────────────────────────────────────────────────────────
class _FeedTab extends ConsumerStatefulWidget {
  final BabyProfile baby;
  const _FeedTab({required this.baby});

  @override
  ConsumerState<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends ConsumerState<_FeedTab> {
  String _feedType = 'Breast (Left)';
  final _amountCtrl = TextEditingController();

  final List<String> _feedTypes = [
    'Breast (Left)',
    'Breast (Right)',
    'Bottle (Formula)',
    'Bottle (Milk)',
    'Solids / Puree',
  ];

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _logFeed() {
    HapticFeedback.lightImpact();
    final log = BabyFeedLog(
      babyId: widget.baby.id,
      timestamp: DateTime.now(),
      feedType: _feedType,
      amountMl: int.tryParse(_amountCtrl.text),
    );
    ref.read(babyLogsProvider.notifier).addFeed(log);
    _amountCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final allLogs = ref.watch(babyLogsProvider);
    final feedLogs = allLogs.feedLogs.where((l) => l.babyId == widget.baby.id).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Quick Feed Entry Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.kCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.kDivider),
            boxShadow: [
              BoxShadow(
                color: KholoColors.wine.withValues(alpha: context.isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Log Feeding Session',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.kInk,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _feedTypes.map((t) {
                  final isSel = _feedType == t;
                  return ChoiceChip(
                    label: Text(
                      t,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSel ? Colors.white : context.kInk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: isSel,
                    selectedColor: context.isDark ? KholoColors.magenta : KholoColors.plum,
                    backgroundColor: context.kCardElevated,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _feedType = t);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (Optional ml/oz or minutes)',
                  labelStyle: TextStyle(fontSize: 12, color: context.kInkMuted),
                  filled: true,
                  fillColor: context.kCardElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.kDivider),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _logFeed,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Save Feed Entry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.isDark ? KholoColors.magenta : KholoColors.plum,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Text(
          'Today\'s Feeds',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.kInk,
          ),
        ),
        const SizedBox(height: 12),

        if (feedLogs.isEmpty)
          _buildEmptyLog(context, 'No feeding logs recorded today.')
        else
          ...feedLogs.reversed.map((f) => _buildFeedItem(context, f)),
      ],
    );
  }

  Widget _buildFeedItem(BuildContext context, BabyLog f) {
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
          Row(
            children: [
              const Icon(Icons.local_drink_rounded, color: KholoColors.rose, size: 20),
              const SizedBox(width: 10),
              Text(
                f.feedType ?? 'Feeding',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.kInk),
              ),
            ],
          ),
          Text(
            '${f.timestamp.hour}:${f.timestamp.minute.toString().padLeft(2, '0')} ${f.amountMl != null ? '• ${f.amountMl}ml' : ''}',
            style: TextStyle(color: context.kInkMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── 2. SLEEP TAB ─────────────────────────────────────────────────────────────
class _SleepTab extends ConsumerStatefulWidget {
  final BabyProfile baby;
  const _SleepTab({required this.baby});

  @override
  ConsumerState<_SleepTab> createState() => _SleepTabState();
}

class _SleepTabState extends ConsumerState<_SleepTab> {
  bool _isSleeping = false;
  DateTime? _sleepStart;

  void _toggleSleep() {
    HapticFeedback.mediumImpact();
    if (!_isSleeping) {
      setState(() {
        _isSleeping = true;
        _sleepStart = DateTime.now();
      });
    } else {
      final end = DateTime.now();
      final durMinutes = end.difference(_sleepStart!).inMinutes;
      final log = BabySleepLog(
        babyId: widget.baby.id,
        startTime: _sleepStart!,
        endTime: end,
        durationMinutes: durMinutes > 0 ? durMinutes : 1,
      );
      ref.read(babyLogsProvider.notifier).addSleep(log);
      setState(() {
        _isSleeping = false;
        _sleepStart = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final allLogs = ref.watch(babyLogsProvider);
    final sleepLogs = allLogs.sleepLogs.where((l) => l.babyId == widget.baby.id).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Sleep Timer Hero Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2C243B), Color(0xFF1E172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              const Icon(Icons.nightlight_round, color: KholoColors.warmGold, size: 36),
              const SizedBox(height: 8),
              Text(
                _isSleeping ? 'Baby is currently asleep...' : 'Ready for nap time?',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _toggleSleep,
                icon: Icon(_isSleeping ? Icons.wb_sunny_outlined : Icons.bedtime_outlined),
                label: Text(_isSleeping ? 'Baby Woke Up (Save Sleep)' : 'Start Sleep Timer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSleeping
                      ? Colors.amber
                      : (context.isDark ? KholoColors.magenta : KholoColors.plum),
                  foregroundColor: _isSleeping ? Colors.black87 : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Text(
          'Sleep History',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.kInk,
          ),
        ),
        const SizedBox(height: 12),

        if (sleepLogs.isEmpty)
          _buildEmptyLog(context, 'No recorded sleep sessions yet.')
        else
          ...sleepLogs.reversed.map((s) => Container(
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
                    Row(
                      children: [
                        const Icon(Icons.nightlight_outlined, color: KholoColors.lavender, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          '${s.durationMinutes} mins nap',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: context.kInk,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${s.startTime.hour}:${s.startTime.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(color: context.kInkMuted, fontSize: 12),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}

// ── 3. DIAPER TAB ────────────────────────────────────────────────────────────
class _DiaperTab extends ConsumerStatefulWidget {
  final BabyProfile baby;
  const _DiaperTab({required this.baby});

  @override
  ConsumerState<_DiaperTab> createState() => _DiaperTabState();
}

class _DiaperTabState extends ConsumerState<_DiaperTab> {
  String _diaperType = 'Wet';
  final List<String> _types = ['Wet', 'Dirty', 'Both', 'Dry / Clean'];

  void _logDiaper() {
    HapticFeedback.lightImpact();
    final log = BabyDiaperLog(
      babyId: widget.baby.id,
      timestamp: DateTime.now(),
      status: _diaperType,
    );
    ref.read(babyLogsProvider.notifier).addDiaper(log);
  }

  @override
  Widget build(BuildContext context) {
    final allLogs = ref.watch(babyLogsProvider);
    final diaperLogs = allLogs.diaperLogs.where((l) => l.babyId == widget.baby.id).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Quick Diaper Tap Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.kCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.kDivider),
            boxShadow: [
              BoxShadow(
                color: KholoColors.wine.withValues(alpha: context.isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Diaper Log',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.kInk,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _types.map((t) {
                  final isSel = _diaperType == t;
                  return ChoiceChip(
                    label: Text(
                      t,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSel ? Colors.white : context.kInk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: isSel,
                    selectedColor: context.isDark ? KholoColors.magenta : KholoColors.plum,
                    backgroundColor: context.kCardElevated,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _diaperType = t);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _logDiaper,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Record Diaper Change'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.isDark ? KholoColors.magenta : KholoColors.plum,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Text(
          'Diaper History',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.kInk,
          ),
        ),
        const SizedBox(height: 12),

        if (diaperLogs.isEmpty)
          _buildEmptyLog(context, 'No diaper changes logged yet.')
        else
          ...diaperLogs.reversed.map((d) => Container(
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
                    Row(
                      children: [
                        const Icon(Icons.baby_changing_station_rounded, color: KholoColors.sage, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          d.status,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: context.kInk,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${d.timestamp.hour}:${d.timestamp.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(color: context.kInkMuted, fontSize: 12),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}

// ── 4. GROWTH TAB ────────────────────────────────────────────────────────────
class _GrowthTab extends ConsumerWidget {
  final BabyProfile baby;
  const _GrowthTab({required this.baby});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.kCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.kDivider),
            boxShadow: [
              BoxShadow(
                color: KholoColors.wine.withValues(alpha: context.isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Latest Measurements',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.kInk,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMetric(context, 'Weight', '${baby.weightKg ?? 4.2} kg', Icons.monitor_weight_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetric(context, 'Length', '${baby.lengthCm ?? 54} cm', Icons.straighten_outlined),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(BuildContext context, String label, String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.kCardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.isDark ? KholoColors.magenta : KholoColors.plum, size: 20),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: context.kInkMuted, fontSize: 11)),
          Text(
            val,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: context.kInk,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 5. MILESTONE TAB ─────────────────────────────────────────────────────────
class _MilestoneTab extends StatefulWidget {
  final BabyProfile baby;
  const _MilestoneTab({required this.baby});

  @override
  State<_MilestoneTab> createState() => _MilestoneTabState();
}

class _MilestoneTabState extends State<_MilestoneTab> {
  final Set<String> _achieved = {'First social smile', 'Follows moving objects'};

  static const _milestones = [
    'First social smile',
    'Follows moving objects with eyes',
    'Lifts head during tummy time',
    'Rolls from tummy to back',
    'Sits without support',
    'Babbles consonants (ba-ba, ma-ma)',
    'First tooth appearance',
    'First independent steps',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Developmental Milestones',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.kInk,
          ),
        ),
        const SizedBox(height: 12),
        ..._milestones.map((m) {
          final isDone = _achieved.contains(m);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: context.kCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.kDivider),
            ),
            child: CheckboxListTile(
              title: Text(
                m,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  color: isDone ? context.kInkMuted : context.kInk,
                ),
              ),
              value: isDone,
              activeColor: context.isDark ? KholoColors.magenta : KholoColors.plum,
              onChanged: (val) {
                HapticFeedback.selectionClick();
                setState(() {
                  if (val == true) {
                    _achieved.add(m);
                  } else {
                    _achieved.remove(m);
                  }
                });
              },
            ),
          );
        }),
      ],
    );
  }
}

Widget _buildEmptyLog(BuildContext context, String message) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: context.kCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.kDivider),
    ),
    child: Center(
      child: Text(
        message,
        style: TextStyle(color: context.kInkMuted, fontSize: 13),
      ),
    ),
  );
}

// ── ADD BABY SHEET ───────────────────────────────────────────────────────────
class _AddBabySheet extends StatefulWidget {
  final ValueChanged<BabyProfile> onSave;
  const _AddBabySheet({required this.onSave});

  @override
  State<_AddBabySheet> createState() => _AddBabySheetState();
}

class _AddBabySheetState extends State<_AddBabySheet> {
  final _nameCtrl = TextEditingController();
  DateTime _birthDate = DateTime.now();
  String _gender = 'girl';

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: context.kCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Baby Profile',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: context.kInk,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: "Baby's Name",
              labelStyle: TextStyle(color: context.kInkMuted),
              filled: true,
              fillColor: context.kCardElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.kDivider),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Birth Date Selector
          GestureDetector(
            onTap: () async {
              HapticFeedback.mediumImpact();
              final picked = await showDatePicker(
                context: context,
                initialDate: _birthDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _birthDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: context.kCardElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.kDivider),
              ),
              child: Row(
                children: [
                  Icon(Icons.cake_outlined,
                      color: context.isDark ? KholoColors.magenta : KholoColors.plum,
                      size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'Birth date: ${_birthDate.day}/${_birthDate.month}/${_birthDate.year}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.kInk,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.edit_calendar_rounded,
                      size: 16, color: context.kInkSubtle),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Gender: ',
                style: TextStyle(fontWeight: FontWeight.w600, color: context.kInk),
              ),
              ChoiceChip(
                label: const Text('Girl'),
                selected: _gender == 'girl',
                selectedColor: KholoColors.rose,
                labelStyle: TextStyle(
                  color: _gender == 'girl' ? Colors.white : context.kInk,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: context.kCardElevated,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  setState(() => _gender = 'girl');
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Boy'),
                selected: _gender == 'boy',
                selectedColor: context.isDark ? KholoColors.magenta : KholoColors.plum,
                labelStyle: TextStyle(
                  color: _gender == 'boy' ? Colors.white : context.kInk,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: context.kCardElevated,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  setState(() => _gender = 'boy');
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_nameCtrl.text.trim().isEmpty) return;
                HapticFeedback.mediumImpact();
                final baby = BabyProfile(
                  nickname: _nameCtrl.text.trim(),
                  birthDate: _birthDate,
                  gender: _gender,
                );
                widget.onSave(baby);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.isDark ? KholoColors.magenta : KholoColors.plum,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Create Profile'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoBabyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _NoBabyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.child_care_rounded,
              size: 64,
              color: context.isDark ? KholoColors.magenta : KholoColors.plum,
            ),
            const SizedBox(height: 16),
            Text(
              'Baby & Postpartum Care',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: context.kInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track feeding, naps, diaper changes, and developmental milestones effortlessly.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: context.kInkMuted, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                onAdd();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Baby Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.isDark ? KholoColors.magenta : KholoColors.plum,
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
