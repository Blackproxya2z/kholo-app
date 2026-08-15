import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/colors.dart';
import '../../core/models/baby_profile.dart';
import '../../core/providers/providers.dart';

/// Baby care screen with profile selector and quick-log tabs.
class BabyScreen extends ConsumerStatefulWidget {
  const BabyScreen({super.key});

  @override
  ConsumerState<BabyScreen> createState() => _BabyScreenState();
}

class _BabyScreenState extends ConsumerState<BabyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final babies = ref.watch(babiesProvider);
    final selectedBabyId = ref.watch(selectedBabyIdProvider);
    final selectedBaby = babies.isEmpty
        ? null
        : babies.firstWhere(
            (b) => b.id == selectedBabyId,
            orElse: () => babies.first,
          );

    return Scaffold(
      backgroundColor: KholoColors.canvas,
      appBar: AppBar(
        title: const Text('Baby care'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddBabySheet(context),
            tooltip: 'Add baby profile',
          ),
        ],
      ),
      body: babies.isEmpty
          ? _NoBabyState(onAdd: () => _showAddBabySheet(context))
          : Column(
              children: [
                // Baby selector
                if (babies.length > 1)
                  _BabySelector(
                    babies: babies,
                    selectedId: selectedBaby?.id,
                    onSelect: (id) =>
                        ref.read(selectedBabyIdProvider.notifier).state = id,
                  ),

                // Selected baby header
                if (selectedBaby != null) _BabyHeader(baby: selectedBaby),

                // Tab bar
                Container(
                  color: KholoColors.canvas,
                  child: TabBar(
                    controller: _tabCtrl,
                    labelColor: KholoColors.plum,
                    unselectedLabelColor: KholoColors.inkMuted,
                    indicatorColor: KholoColors.plum,
                    indicatorWeight: 2,
                    labelStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(icon: Icon(Icons.local_drink_outlined, size: 20), text: 'Feed'),
                      Tab(icon: Icon(Icons.nights_stay_outlined, size: 20), text: 'Sleep'),
                      Tab(icon: Icon(Icons.straighten_outlined, size: 20), text: 'Growth'),
                      Tab(icon: Icon(Icons.star_outline_rounded, size: 20), text: 'Milestones'),
                    ],
                  ),
                ),

                // Tab views
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: selectedBaby == null
                        ? List.generate(4, (_) => const SizedBox.shrink())
                        : [
                            _FeedTab(baby: selectedBaby),
                            _SleepTab(baby: selectedBaby),
                            _GrowthTab(baby: selectedBaby),
                            _MilestoneTab(baby: selectedBaby),
                          ],
                  ),
                ),
              ],
            ),
    );
  }

  void _showAddBabySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddBabySheet(
        onSave: (baby) => ref.read(babiesProvider.notifier).add(baby),
      ),
    );
  }
}

class _NoBabyState extends StatelessWidget {
  const _NoBabyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: KholoColors.sageLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.child_care_rounded,
                  color: KholoColors.sage, size: 40),
            ),
            const SizedBox(height: 24),
            Text('Baby care', style: tt.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Add a baby profile to start logging feeding, sleep, growth, and milestones. Each profile is private to your account.',
              style: tt.bodyMedium?.copyWith(color: KholoColors.inkMuted, height: 1.55),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add baby profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BabySelector extends StatelessWidget {
  const _BabySelector({
    required this.babies,
    required this.selectedId,
    required this.onSelect,
  });
  final List<BabyProfile> babies;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: babies.map((b) {
          final isSelected = b.id == selectedId;
          return GestureDetector(
            onTap: () => onSelect(b.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? KholoColors.plum : KholoColors.cream,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? KholoColors.plum : KholoColors.divider,
                ),
              ),
              child: Center(
                child: Text(
                  b.nickname,
                  style: TextStyle(
                    color: isSelected ? Colors.white : KholoColors.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BabyHeader extends StatelessWidget {
  const _BabyHeader({required this.baby});
  final BabyProfile baby;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: KholoColors.sageLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                baby.nickname.substring(0, 1).toUpperCase(),
                style: tt.headlineSmall?.copyWith(color: KholoColors.sageDark),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(baby.nickname, style: tt.titleLarge),
              Text(baby.ageDisplay,
                  style: tt.bodySmall?.copyWith(color: KholoColors.inkMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tab views ─────────────────────────────────────────────────────────────────

class _FeedTab extends ConsumerWidget {
  const _FeedTab({required this.baby});
  final BabyProfile baby;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(babyLogsProvider)
        .where((l) => l.babyId == baby.id && l.logType == BabyLogType.feeding)
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    return _LogTab(
      baby: baby,
      logs: logs,
      logType: BabyLogType.feeding,
      emptyMessage: 'Tap + to log a feeding.',
    );
  }
}

class _SleepTab extends ConsumerWidget {
  const _SleepTab({required this.baby});
  final BabyProfile baby;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(babyLogsProvider)
        .where((l) => l.babyId == baby.id && l.logType == BabyLogType.sleep)
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    return _LogTab(
      baby: baby,
      logs: logs,
      logType: BabyLogType.sleep,
      emptyMessage: 'Tap + to log a sleep session.',
    );
  }
}

class _GrowthTab extends ConsumerWidget {
  const _GrowthTab({required this.baby});
  final BabyProfile baby;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(babyLogsProvider)
        .where((l) => l.babyId == baby.id && l.logType == BabyLogType.growth)
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    return _LogTab(
      baby: baby,
      logs: logs,
      logType: BabyLogType.growth,
      emptyMessage: 'Tap + to log a measurement.',
    );
  }
}

class _MilestoneTab extends ConsumerWidget {
  const _MilestoneTab({required this.baby});
  final BabyProfile baby;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(babyLogsProvider)
        .where((l) => l.babyId == baby.id && l.logType == BabyLogType.milestone)
        .toList()
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

    return _LogTab(
      baby: baby,
      logs: logs,
      logType: BabyLogType.milestone,
      emptyMessage: 'Tap + to record a milestone.',
    );
  }
}

class _LogTab extends ConsumerWidget {
  const _LogTab({
    required this.baby,
    required this.logs,
    required this.logType,
    required this.emptyMessage,
  });

  final BabyProfile baby;
  final List<BabyLog> logs;
  final BabyLogType logType;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            if (logs.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: KholoColors.cream,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(emptyMessage,
                    style: tt.bodyMedium?.copyWith(color: KholoColors.inkMuted)),
              )
            else
              ...logs.map((log) => _BabyLogCard(log: log)),
          ],
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: () => _showQuickLog(context, ref),
            backgroundColor: KholoColors.sage,
            tooltip: 'Quick log',
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _showQuickLog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickLogSheet(
        baby: baby,
        logType: logType,
        onSave: (log) => ref.read(babyLogsProvider.notifier).add(log),
      ),
    );
  }
}

class _BabyLogCard extends StatelessWidget {
  const _BabyLogCard({required this.log});
  final BabyLog log;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final time = _fmtTime(log.occurredAt);

    String subtitle = '';
    if (log.logType == BabyLogType.feeding) {
      subtitle = log.feedingMethod?.name ?? '';
      if (log.amountMl != null) subtitle += ' · ${log.amountMl!.toInt()} ml';
    } else if (log.logType == BabyLogType.sleep) {
      if (log.sleepMinutes != null) {
        final h = log.sleepMinutes! ~/ 60;
        final m = log.sleepMinutes! % 60;
        subtitle = h > 0 ? '${h}h ${m}m' : '${m}m';
      }
    } else if (log.logType == BabyLogType.growth) {
      final parts = <String>[];
      if (log.weightKg != null) parts.add('${log.weightKg!.toStringAsFixed(2)} kg');
      if (log.heightCm != null) parts.add('${log.heightCm!.toInt()} cm');
      subtitle = parts.join(' · ');
    } else if (log.logType == BabyLogType.milestone) {
      subtitle = log.milestoneLabel ?? '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KholoColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KholoColors.divider),
      ),
      child: Row(
        children: [
          Text(log.logType.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.logType.displayName, style: tt.titleSmall),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      style: tt.bodySmall?.copyWith(color: KholoColors.inkMuted)),
                if (log.note != null && log.note!.isNotEmpty)
                  Text(log.note!,
                      style: tt.bodySmall?.copyWith(color: KholoColors.inkMuted)),
              ],
            ),
          ),
          Text(time, style: tt.labelSmall),
        ],
      ),
    );
  }

  String _fmtTime(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _QuickLogSheet extends StatefulWidget {
  const _QuickLogSheet({
    required this.baby,
    required this.logType,
    required this.onSave,
  });
  final BabyProfile baby;
  final BabyLogType logType;
  final Function(BabyLog) onSave;

  @override
  State<_QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends State<_QuickLogSheet> {
  final _noteCtrl = TextEditingController();
  // Feeding
  FeedingMethod _feedMethod = FeedingMethod.breast;
  double _amountMl = 100;
  // Sleep
  int _sleepMinutes = 60;
  // Growth
  double _weightKg = 3.5;
  double _heightCm = 50;
  // Milestone
  String _milestone = kMilestoneLabels.first;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final now = DateTime.now();
    BabyLog log;
    switch (widget.logType) {
      case BabyLogType.feeding:
        log = BabyLog(
          babyId: widget.baby.id,
          logType: BabyLogType.feeding,
          occurredAt: now,
          feedingMethod: _feedMethod,
          amountMl: _feedMethod == FeedingMethod.bottle ? _amountMl : null,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        );
        break;
      case BabyLogType.sleep:
        log = BabyLog(
          babyId: widget.baby.id,
          logType: BabyLogType.sleep,
          occurredAt: now.subtract(Duration(minutes: _sleepMinutes)),
          sleepEnd: now,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        );
        break;
      case BabyLogType.growth:
        log = BabyLog(
          babyId: widget.baby.id,
          logType: BabyLogType.growth,
          occurredAt: now,
          weightKg: _weightKg,
          heightCm: _heightCm,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        );
        break;
      case BabyLogType.milestone:
        log = BabyLog(
          babyId: widget.baby.id,
          logType: BabyLogType.milestone,
          occurredAt: now,
          milestoneLabel: _milestone,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        );
        break;
    }
    widget.onSave(log);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text('Saved'),
        ]),
        backgroundColor: KholoColors.sage,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: KholoColors.canvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: ctrl,
          padding: EdgeInsets.fromLTRB(24, 12, 24, bottom + 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: KholoColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(widget.logType.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text('Log ${widget.logType.displayName.toLowerCase()}',
                    style: tt.headlineSmall),
              ],
            ),
            const SizedBox(height: 20),
            _buildFields(tt),
            const SizedBox(height: 16),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Optional note…'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }

  Widget _buildFields(TextTheme tt) {
    switch (widget.logType) {
      case BabyLogType.feeding:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Method', style: tt.titleSmall?.copyWith(color: KholoColors.inkMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: FeedingMethod.values.map((m) {
              final sel = _feedMethod == m;
              return ChoiceChip(
                label: Text(m.name),
                selected: sel,
                onSelected: (_) => setState(() => _feedMethod = m),
                selectedColor: KholoColors.sage,
                labelStyle: TextStyle(color: sel ? Colors.white : KholoColors.ink),
              );
            }).toList(),
          ),
          if (_feedMethod == FeedingMethod.bottle) ...[
            const SizedBox(height: 12),
            Text('Amount: ${_amountMl.toInt()} ml', style: tt.titleSmall),
            Slider(
              value: _amountMl,
              min: 10,
              max: 300,
              divisions: 29,
              activeColor: KholoColors.sage,
              onChanged: (v) => setState(() => _amountMl = v),
            ),
          ],
        ]);

      case BabyLogType.sleep:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Duration: ${_sleepMinutes ~/ 60}h ${_sleepMinutes % 60}m',
              style: tt.titleSmall),
          Slider(
            value: _sleepMinutes.toDouble(),
            min: 5,
            max: 720,
            divisions: 143,
            activeColor: KholoColors.lavender,
            onChanged: (v) => setState(() => _sleepMinutes = v.round()),
          ),
        ]);

      case BabyLogType.growth:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Weight: ${_weightKg.toStringAsFixed(2)} kg', style: tt.titleSmall),
          Slider(
            value: _weightKg,
            min: 0.5,
            max: 30,
            divisions: 295,
            activeColor: KholoColors.plum,
            onChanged: (v) => setState(() => _weightKg = v),
          ),
          const SizedBox(height: 8),
          Text('Height: ${_heightCm.toInt()} cm', style: tt.titleSmall),
          Slider(
            value: _heightCm,
            min: 30,
            max: 130,
            divisions: 100,
            activeColor: KholoColors.plum,
            onChanged: (v) => setState(() => _heightCm = v),
          ),
        ]);

      case BabyLogType.milestone:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Milestone', style: tt.titleSmall?.copyWith(color: KholoColors.inkMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: kMilestoneLabels.map((m) {
              final sel = _milestone == m;
              return ChoiceChip(
                label: Text(m),
                selected: sel,
                onSelected: (_) => setState(() => _milestone = m),
                selectedColor: KholoColors.sageLight,
                labelStyle: TextStyle(
                    fontSize: 12,
                    color: sel ? KholoColors.sageDark : KholoColors.ink),
              );
            }).toList(),
          ),
        ]);
    }
  }
}

class _AddBabySheet extends StatefulWidget {
  const _AddBabySheet({required this.onSave});
  final Function(BabyProfile) onSave;

  @override
  State<_AddBabySheet> createState() => _AddBabySheetState();
}

class _AddBabySheetState extends State<_AddBabySheet> {
  final _nameCtrl = TextEditingController();
  DateTime? _birthDate;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottom + 24),
      decoration: const BoxDecoration(
        color: KholoColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KholoColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Add a baby profile', style: tt.headlineSmall),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Baby\'s name or nickname',
              prefixIcon: Icon(Icons.child_care_outlined, color: KholoColors.inkSubtle),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 1095)),
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => _birthDate = d);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KholoColors.cream,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _birthDate != null ? KholoColors.sage : KholoColors.divider,
                  width: _birthDate != null ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cake_outlined, color: KholoColors.inkSubtle),
                  const SizedBox(width: 12),
                  Text(
                    _birthDate != null ? _fmtDate(_birthDate!) : 'Birthday',
                    style: tt.bodyMedium?.copyWith(
                      color: _birthDate != null ? KholoColors.ink : KholoColors.inkSubtle,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: KholoColors.inkSubtle),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_nameCtrl.text.trim().isNotEmpty && _birthDate != null) {
                  widget.onSave(BabyProfile(
                    nickname: _nameCtrl.text.trim(),
                    birthDate: _birthDate!,
                  ));
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save profile'),
            ),
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
