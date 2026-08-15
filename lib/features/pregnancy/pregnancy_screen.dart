import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/colors.dart';
import '../../core/models/pregnancy_profile.dart';
import '../../core/providers/providers.dart';

/// Pregnancy mode screen with due-date countdown and symptom journal.
class PregnancyScreen extends ConsumerStatefulWidget {
  const PregnancyScreen({super.key});

  @override
  ConsumerState<PregnancyScreen> createState() => _PregnancyScreenState();
}

class _PregnancyScreenState extends ConsumerState<PregnancyScreen> {
  bool _showAddDueDate = false;

  @override
  Widget build(BuildContext context) {
    final pregnancyProfile = ref.watch(pregnancyProfileProvider);
    final logs = ref.watch(pregnancyLogsProvider);
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: KholoColors.canvas,
      appBar: AppBar(
        title: const Text('Pregnancy'),
        actions: [
          if (pregnancyProfile != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _showAddDueDate = true),
              tooltip: 'Edit due date',
            ),
        ],
      ),
      body: pregnancyProfile == null
          ? _NoDueDateState(
              onAddDueDate: () => setState(() => _showAddDueDate = true),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                // Countdown hero
                _CountdownHero(profile: pregnancyProfile),
                const SizedBox(height: 20),

                // Weekly milestone
                _WeeklyMilestone(week: pregnancyProfile.currentWeek),
                const SizedBox(height: 20),

                // Symptom journal
                const _SectionLabel('Symptom journal'),
                const SizedBox(height: 12),
                _AddJournalEntry(
                  week: pregnancyProfile.currentWeek,
                  onSave: (log) =>
                      ref.read(pregnancyLogsProvider.notifier).add(log),
                ),
                const SizedBox(height: 12),

                if (logs.isEmpty)
                  const _EmptyJournal()
                else
                  ...logs.reversed.map((log) => _JournalEntry(log: log)),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: KholoColors.cream,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: KholoColors.divider),
                  ),
                  child: Text(
                    'KHOLO provides educational context only. For pregnancy health concerns, always contact a qualified midwife or obstetrician.',
                    style: tt.bodySmall
                        ?.copyWith(color: KholoColors.inkSubtle, height: 1.5),
                  ),
                ),
              ],
            ),
      // Due date dialog overlay
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
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: KholoColors.inkSubtle,
            ),
      );
}

class _NoDueDateState extends StatelessWidget {
  const _NoDueDateState({required this.onAddDueDate});
  final VoidCallback onAddDueDate;

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
                color: KholoColors.roseLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.child_friendly_outlined,
                  color: KholoColors.rose, size: 40),
            ),
            const SizedBox(height: 24),
            Text('Pregnancy companion', style: tt.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Add your due date to see a week-by-week companion, countdown, and a private symptom journal.',
              style: tt.bodyMedium?.copyWith(color: KholoColors.inkMuted, height: 1.55),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onAddDueDate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add due date'),
            ),
            const SizedBox(height: 12),
            Text(
              'Your due date is stored privately on your device.',
              style: tt.bodySmall?.copyWith(color: KholoColors.inkSubtle),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownHero extends StatelessWidget {
  const _CountdownHero({required this.profile});
  final PregnancyProfile profile;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final progress = (profile.currentWeek / 40).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [KholoColors.roseLight, KholoColors.tertiaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: KholoColors.magenta.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Week ${profile.currentWeek}',
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 36, fontWeight: FontWeight.w700, color: KholoColors.ink)),
                    Text('of your pregnancy',
                        style: tt.bodyMedium?.copyWith(color: KholoColors.inkMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${profile.daysRemaining}',
                    style: tt.headlineLarge?.copyWith(
                        color: KholoColors.wine, fontWeight: FontWeight.w800),
                  ),
                  Text('days to go',
                      style: tt.bodySmall?.copyWith(color: KholoColors.inkMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Horizon progress
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: KholoColors.magenta.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(KholoColors.magenta),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Due: ${_fmtDate(profile.dueDate)}',
            style: tt.bodySmall?.copyWith(color: KholoColors.inkMuted),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _WeeklyMilestone extends StatelessWidget {
  const _WeeklyMilestone({required this.week});
  final int week;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final milestone = getMilestoneForWeek(week);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KholoColors.cream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KholoColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_outlined, color: KholoColors.plum, size: 20),
              const SizedBox(width: 8),
              Text('This week', style: tt.titleMedium?.copyWith(color: KholoColors.plum)),
            ],
          ),
          const SizedBox(height: 12),
          if (milestone != null) ...[
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: KholoColors.roseLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.spa_outlined, color: KholoColors.rose, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('About the size of a ${milestone['size']!.toLowerCase()}',
                          style: tt.titleMedium),
                      Text(milestone['detail']!,
                          style: tt.bodySmall?.copyWith(
                              color: KholoColors.inkMuted, height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          ] else
            Text(
              'Keep logging to unlock weekly context.',
              style: tt.bodyMedium?.copyWith(color: KholoColors.inkMuted),
            ),
          const SizedBox(height: 8),
          Text(
            'Educational context only — not a medical assessment.',
            style: tt.labelSmall?.copyWith(color: KholoColors.inkSubtle),
          ),
        ],
      ),
    );
  }
}

class _AddJournalEntry extends StatefulWidget {
  const _AddJournalEntry({required this.week, required this.onSave});
  final int week;
  final Function(PregnancyLog) onSave;

  @override
  State<_AddJournalEntry> createState() => _AddJournalEntryState();
}

class _AddJournalEntryState extends State<_AddJournalEntry> {
  bool _expanded = false;
  final Set<String> _symptoms = {};
  final _noteCtrl = TextEditingController();

  static const _symptomOptions = [
    'Nausea', 'Fatigue', 'Heartburn', 'Back pain',
    'Swelling', 'Insomnia', 'Headache', 'Mood changes',
    'Round ligament pain', 'Braxton Hicks', 'Food aversion', 'Cravings',
  ];

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave(PregnancyLog(
      pregnancyWeek: widget.week,
      eventDate: DateTime.now(),
      symptoms: _symptoms.toList(),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    ));
    setState(() {
      _expanded = false;
      _symptoms.clear();
      _noteCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KholoColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _expanded ? KholoColors.plum : KholoColors.divider,
            width: _expanded ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                const Icon(Icons.add_circle_outline_rounded, color: KholoColors.plum, size: 20),
                const SizedBox(width: 8),
                Text('Add journal entry', style: tt.titleSmall?.copyWith(color: KholoColors.plum)),
                const Spacer(),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: KholoColors.inkSubtle,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 16),
            Text('How are you feeling?', style: tt.bodySmall?.copyWith(color: KholoColors.inkMuted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _symptomOptions.map((s) {
                final sel = _symptoms.contains(s);
                return FilterChip(
                  label: Text(s),
                  selected: sel,
                  onSelected: (_) => setState(() =>
                      sel ? _symptoms.remove(s) : _symptoms.add(s)),
                  selectedColor: KholoColors.lavenderLight,
                  checkmarkColor: KholoColors.plum,
                  labelStyle: TextStyle(fontSize: 12, color: sel ? KholoColors.plum : KholoColors.ink),
                  backgroundColor: KholoColors.canvas,
                  side: BorderSide(color: sel ? KholoColors.lavender : KholoColors.divider),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              maxLength: 1500,
              decoration: const InputDecoration(
                hintText: 'Any notes…',
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save entry'),
            ),
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
        color: KholoColors.cream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Your journal entries will appear here. Everything is private.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: KholoColors.inkMuted),
      ),
    );
  }
}

class _JournalEntry extends StatelessWidget {
  const _JournalEntry({required this.log});
  final PregnancyLog log;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KholoColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KholoColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Week ${log.pregnancyWeek}',
                  style: tt.titleSmall?.copyWith(color: KholoColors.plum, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(_fmtDate(log.eventDate),
                  style: tt.bodySmall?.copyWith(color: KholoColors.inkSubtle)),
            ],
          ),
          if (log.symptoms.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: log.symptoms
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: KholoColors.roseLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(s,
                            style: const TextStyle(fontSize: 11, color: KholoColors.roseDark)),
                      ))
                  .toList(),
            ),
          ],
          if (log.note != null && log.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(log.note!,
                style: tt.bodySmall?.copyWith(color: KholoColors.inkMuted, height: 1.5)),
          ],
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]}';
  }
}

class _DueDatePicker extends StatefulWidget {
  const _DueDatePicker({this.initial, required this.onSave, required this.onCancel});
  final DateTime? initial;
  final Function(DateTime) onSave;
  final VoidCallback onCancel;

  @override
  State<_DueDatePicker> createState() => _DueDatePickerState();
}

class _DueDatePickerState extends State<_DueDatePicker> {
  DateTime? _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: KholoColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Color(0x1A342B3D), blurRadius: 20, offset: Offset(0, -4)),
        ],
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
          Text('Your due date', style: tt.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Stored privately on your device.',
            style: tt.bodySmall?.copyWith(color: KholoColors.inkMuted),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _picked ??
                    DateTime.now().add(const Duration(days: 180)),
                firstDate: DateTime.now(),
                lastDate:
                    DateTime.now().add(const Duration(days: 300)),
              );
              if (d != null) setState(() => _picked = d);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KholoColors.cream,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _picked != null ? KholoColors.plum : KholoColors.divider,
                  width: _picked != null ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_outlined, color: KholoColors.plum),
                  const SizedBox(width: 12),
                  Text(
                    _picked != null ? _fmtDate(_picked!) : 'Select due date',
                    style: tt.bodyMedium?.copyWith(
                      color: _picked != null ? KholoColors.ink : KholoColors.inkSubtle,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: KholoColors.inkSubtle),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _picked != null ? () => widget.onSave(_picked!) : null,
                  child: const Text('Save due date'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
