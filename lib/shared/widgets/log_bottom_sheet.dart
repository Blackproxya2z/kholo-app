import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/colors.dart';
import '../../core/models/cycle_log.dart';
import '../../core/providers/providers.dart';
import '../../core/services/brand_emotional_state_service.dart';

/// ─── ONE-TAP QUICK CYCLE & BODY EVENT LOGGING SHEET ────────────────────────
///
/// Features:
/// 1. Period flow intensity (Spotting, Light, Medium, Heavy).
/// 2. Mood states (Happy, Calm, Okay, Low, Irritated).
/// 3. Symptoms (Cramps, Headache, Bloating, Fatigue, etc.).
/// 4. Body metrics: Cervical Mucus & Intimacy.
/// 5. Tactile haptic feedback & instant local storage save.
/// ────────────────────────────────────────────────────────────────────────────
class LogBottomSheet extends ConsumerStatefulWidget {
  const LogBottomSheet({super.key, this.initialDate});
  final DateTime? initialDate;

  static Future<void> show(BuildContext context, {DateTime? initialDate}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LogBottomSheet(initialDate: initialDate),
    );
  }

  @override
  ConsumerState<LogBottomSheet> createState() => _LogBottomSheetState();
}

class _LogBottomSheetState extends ConsumerState<LogBottomSheet> {
  late DateTime _date;
  CycleEventType _eventType = CycleEventType.checkIn;
  FlowIntensity? _flow;
  Mood? _mood;
  final Set<String> _symptoms = {};
  String? _cervicalMucus;
  String? _intimacy;
  final _notesController = TextEditingController();
  bool _saving = false;

  static const _mucusOptions = ['Dry', 'Sticky', 'Creamy', 'Egg white', 'Watery'];
  static const _intimacyOptions = ['Protected', 'Unprotected', 'None'];

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    final log = CycleLog(
      eventDate: _utcDate(_date),
      eventType: _eventType,
      flow: _flow,
      mood: _mood,
      symptoms: _symptoms.toList(),
      cervicalMucus: _cervicalMucus,
      intimacy: _intimacy,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    await ref.read(cycleLogsProvider.notifier).addOrUpdate(log);
    await BrandEmotionalStateService.recordHealthLog();

    if (mounted) {
      Navigator.of(context).pop();
      _showSaveToast(context);
    }
  }

  void _showSaveToast(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Health check-in saved privately'),
          ],
        ),
        backgroundColor: KholoColors.wine,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.kSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          shrinkWrap: true,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.kDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Check-in',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: context.kInk,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: context.kInkSubtle),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Date
            const _SectionLabel('Date'),
            const SizedBox(height: 8),
            _DateSelector(
              date: _date,
              onDateChanged: (d) => setState(() => _date = d),
            ),
            const SizedBox(height: 20),

            // Event type
            const _SectionLabel('Event Category'),
            const SizedBox(height: 8),
            _EventTypeSelector(
              selected: _eventType,
              onSelected: (t) => setState(() => _eventType = t),
            ),
            const SizedBox(height: 20),

            // Flow (show for period and general check-in)
            if (_eventType == CycleEventType.periodStart ||
                _eventType == CycleEventType.checkIn) ...[
              const _SectionLabel('Menstrual Flow'),
              const SizedBox(height: 8),
              _FlowSelector(
                selected: _flow,
                onSelected: (f) => setState(() => _flow = f),
              ),
              const SizedBox(height: 20),
            ],

            // Mood
            const _SectionLabel('Mood & Energy'),
            const SizedBox(height: 8),
            _MoodSelector(
              selected: _mood,
              onSelected: (m) => setState(() => _mood = m),
            ),
            const SizedBox(height: 20),

            // Symptoms
            const _SectionLabel('Physical Symptoms'),
            const SizedBox(height: 8),
            _SymptomChips(
              selected: _symptoms,
              onToggle: (s) => setState(() {
                if (_symptoms.contains(s)) {
                  _symptoms.remove(s);
                } else {
                  _symptoms.add(s);
                }
              }),
            ),
            const SizedBox(height: 20),

            // Cervical Mucus
            const _SectionLabel('Cervical Mucus'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _mucusOptions.map((m) {
                final isSel = _cervicalMucus == m;
                return ChoiceChip(
                  label: Text(m),
                  selected: isSel,
                  selectedColor: KholoColors.plum,
                  labelStyle: TextStyle(
                    color: isSel ? Colors.white : context.kInk,
                    fontSize: 12,
                  ),
                  backgroundColor: context.kCard,
                  onSelected: (_) =>
                      setState(() => _cervicalMucus = isSel ? null : m),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Intimacy
            const _SectionLabel('Intimacy'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _intimacyOptions.map((opt) {
                final isSel = _intimacy == opt;
                return ChoiceChip(
                  label: Text(opt),
                  selected: isSel,
                  selectedColor: KholoColors.rose,
                  labelStyle: TextStyle(
                    color: isSel ? Colors.white : context.kInk,
                    fontSize: 12,
                  ),
                  backgroundColor: context.kCard,
                  onSelected: (_) =>
                      setState(() => _intimacy = isSel ? null : opt),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Notes
            const _SectionLabel('Private Reflection (Optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              maxLength: 1000,
              decoration: const InputDecoration(
                hintText: 'Anything else on your mind today…',
                counterText: '',
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KholoColors.plum,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Check-in',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

DateTime _utcDate(DateTime d) => DateTime.utc(d.year, d.month, d.day);

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: context.kInkMuted,
              letterSpacing: 0.8,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
      );
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({required this.date, required this.onDateChanged});
  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now(),
        );
        if (picked != null) onDateChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.kDivider),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: KholoColors.plum),
            const SizedBox(width: 10),
            Text(
              _formatDate(date),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: context.kInk),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: context.kInkSubtle),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _EventTypeSelector extends StatelessWidget {
  const _EventTypeSelector({required this.selected, required this.onSelected});
  final CycleEventType selected;
  final ValueChanged<CycleEventType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: CycleEventType.values.map((t) {
        final isSelected = selected == t;
        return ChoiceChip(
          label: Text(t.displayName),
          selected: isSelected,
          onSelected: (_) => onSelected(t),
          selectedColor: KholoColors.plum,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : context.kInk,
            fontWeight: FontWeight.w500,
          ),
          backgroundColor: context.kTint(KholoColors.lavender),
        );
      }).toList(),
    );
  }
}

class _FlowSelector extends StatelessWidget {
  const _FlowSelector({required this.selected, required this.onSelected});
  final FlowIntensity? selected;
  final ValueChanged<FlowIntensity?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('None'),
          selected: selected == null,
          onSelected: (_) => onSelected(null),
          selectedColor: KholoColors.plum,
          labelStyle: TextStyle(
            color: selected == null ? Colors.white : context.kInk,
          ),
          backgroundColor: context.kCard,
        ),
        ...FlowIntensity.values.map((f) {
          final isSelected = selected == f;
          return ChoiceChip(
            label: Text(f.displayName),
            selected: isSelected,
            onSelected: (_) => onSelected(f),
            selectedColor: KholoColors.rose,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : context.kInk,
            ),
            backgroundColor: context.kTint(KholoColors.rose),
          );
        }),
      ],
    );
  }
}

class _MoodSelector extends StatelessWidget {
  const _MoodSelector({required this.selected, required this.onSelected});
  final Mood? selected;
  final ValueChanged<Mood?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: Mood.values.map((m) {
        final isSelected = selected == m;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onSelected(isSelected ? null : m),
            child: Semantics(
              label: m.displayName,
              selected: isSelected,
              button: true,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.kTint(KholoColors.magenta, lightAlpha: 0.18, darkAlpha: 0.3)
                      : context.kCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? KholoColors.magenta : context.kDivider,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(m.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 2),
                    Text(
                      m.displayName,
                      style: TextStyle(
                        fontSize: 9,
                        color: isSelected
                            ? (context.isDark ? KholoColors.magenta : KholoColors.plum)
                            : context.kInkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SymptomChips extends StatelessWidget {
  const _SymptomChips({required this.selected, required this.onToggle});
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: kSymptomOptions.map((s) {
        final isSelected = selected.contains(s);
        return FilterChip(
          label: Text(s),
          selected: isSelected,
          onSelected: (_) => onToggle(s),
          selectedColor: context.kTint(KholoColors.lavender),
          checkmarkColor: KholoColors.plum,
          labelStyle: TextStyle(
            fontSize: 12,
            color: isSelected
                ? (context.isDark ? KholoColors.blush : KholoColors.plum)
                : context.kInkMuted,
          ),
          backgroundColor: context.kCard,
          side: BorderSide(
            color: isSelected ? KholoColors.lavender : context.kDivider,
          ),
        );
      }).toList(),
    );
  }
}
