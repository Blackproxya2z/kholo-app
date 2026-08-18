import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../app/theme/colors.dart'; // also provides KholoThemeExtension
import '../../core/models/health_profile.dart';
import '../../core/models/cycle_log.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/cycle_engine.dart';
import '../../shared/widgets/log_bottom_sheet.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cycle calendar with phase ribbons, date detail, and log action.
class CycleScreen extends ConsumerStatefulWidget {
  const CycleScreen({super.key});

  @override
  ConsumerState<CycleScreen> createState() => _CycleScreenState();
}

class _CycleScreenState extends ConsumerState<CycleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(healthProfileProvider);
    final logs = ref.watch(cycleLogsProvider);

    // Build a map of date → list of logs
    final logMap = <DateTime, List<CycleLog>>{};
    for (final log in logs) {
      final key = CycleEngine.utcDate(log.eventDate);
      logMap[key] = [...(logMap[key] ?? []), log];
    }

    return Scaffold(
      backgroundColor: context.kCanvas,
      appBar: AppBar(
        title: Text('Your cycle', style: TextStyle(color: context.kInk)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: context.kInk),
            onPressed: () => LogBottomSheet.show(context),
            tooltip: 'Add log',
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar
          _KholoCalendar(
            focusedDay: _focusedDay,
            selectedDay: _selectedDay,
            profile: profile,
            logMap: logMap,
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onPageChanged: (focused) {
              setState(() => _focusedDay = focused);
            },
          ),

          // Phase legend
          const _PhaseLegend(),

          // Selected day detail
          Expanded(
            child: _selectedDay != null
                ? _DayDetail(
                    date: _selectedDay!,
                    logs: logMap[CycleEngine.utcDate(_selectedDay!)] ?? [],
                    profile: profile,
                  )
                : _UpcomingDates(profile: profile),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => LogBottomSheet.show(context, initialDate: _selectedDay),
        backgroundColor: context.isDark ? KholoColors.magenta : KholoColors.wine,
        tooltip: 'Log today',
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

class _KholoCalendar extends StatelessWidget {
  const _KholoCalendar({
    required this.focusedDay,
    required this.selectedDay,
    required this.profile,
    required this.logMap,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  final DateTime focusedDay;
  final DateTime? selectedDay;
  final HealthProfile profile;
  final Map<DateTime, List<CycleLog>> logMap;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;

  Color? _phaseColor(DateTime day) {
    if (profile.lastPeriodDate == null) return null;
    try {
      final phase = CycleEngine.phaseForDate(
        lastPeriodStart: profile.lastPeriodDate!,
        cycleLength: profile.cycleLength,
        periodLength: profile.periodLength,
        date: day,
      );
      return KholoColors.phaseColor(phase.phaseKey).withValues(alpha: 0.35);
    } catch (_) {
      return null;
    }
  }

  bool _isFertile(DateTime day) {
    if (profile.lastPeriodDate == null) return false;
    return CycleEngine.isInFertileWindow(
      lastPeriodStart: profile.lastPeriodDate!,
      cycleLength: profile.cycleLength,
      date: day,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: focusedDay,
      selectedDayPredicate: (d) =>
          selectedDay != null && isSameDay(d, selectedDay!),
      onDaySelected: onDaySelected,
      onPageChanged: onPageChanged,
      calendarFormat: CalendarFormat.month,
      startingDayOfWeek: StartingDayOfWeek.monday,
      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: context.kInk,
        ),
        leftChevronIcon: Icon(Icons.chevron_left, color: context.isDark ? KholoColors.magenta : KholoColors.wine),
        rightChevronIcon: Icon(Icons.chevron_right, color: context.isDark ? KholoColors.magenta : KholoColors.wine),
        headerPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: (context.isDark ? KholoColors.magenta : KholoColors.wine).withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: context.isDark ? KholoColors.magenta : KholoColors.wine,
          fontWeight: FontWeight.w700,
        ),
        selectedDecoration: BoxDecoration(
          color: context.isDark ? KholoColors.magenta : KholoColors.wine,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        weekendTextStyle: TextStyle(color: context.kInk),
        defaultTextStyle: TextStyle(color: context.kInk),
        outsideTextStyle: TextStyle(color: context.kInkSubtle),
        markerDecoration: BoxDecoration(
          color: context.isDark ? KholoColors.magenta : KholoColors.wine,
          shape: BoxShape.circle,
        ),
        markersMaxCount: 1,
        cellMargin: const EdgeInsets.all(2),
      ),
      calendarBuilders: CalendarBuilders(
        // Phase background
        defaultBuilder: (context, day, focusedDay) =>
            _buildCell(context, day, false),
        todayBuilder: (context, day, focusedDay) =>
            _buildCell(context, day, false, isToday: true),
        selectedBuilder: (context, day, focusedDay) =>
            _buildCell(context, day, true),
        outsideBuilder: (context, day, focusedDay) =>
            _buildCell(context, day, false, isOutside: true),
      ),
      eventLoader: (day) {
        final key = CycleEngine.utcDate(day);
        return logMap[key] ?? [];
      },
    );
  }

  Widget _buildCell(BuildContext context, DateTime day, bool isSelected,
      {bool isToday = false, bool isOutside = false}) {
    final phaseColor = isOutside ? null : _phaseColor(day);
    final fertile = !isOutside && _isFertile(day);
    final logKey = CycleEngine.utcDate(day);
    final hasLog = logMap.containsKey(logKey);

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isSelected
            ? (Theme.of(context).brightness == Brightness.dark ? KholoColors.magenta : KholoColors.plum)
            : (phaseColor ?? Colors.transparent),
        borderRadius: BorderRadius.circular(10),
        border: fertile && !isSelected
            ? Border.all(color: KholoColors.lavender, width: 1.5)
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : isOutside
                      ? context.kInkSubtle
                      : isToday
                          ? (context.isDark ? KholoColors.magenta : KholoColors.plum)
                          : context.kInk,
              fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w400,
              fontSize: 13,
            ),
          ),
          if (hasLog && !isSelected)
            Positioned(
              bottom: 3,
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: KholoColors.rose,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhaseLegend extends StatelessWidget {
  const _PhaseLegend();

  @override
  Widget build(BuildContext context) {
    const phases = [
      (KholoColors.rose, 'Menstrual'),
      (KholoColors.lavender, 'Follicular'),
      (KholoColors.plum, 'Ovulation'),
      (KholoColors.lutealAccent, 'Luteal'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: context.kDivider),
          bottom: BorderSide(color: context.kDivider),
        ),
      ),
      child: Semantics(
        label: 'Phase legend: rose for menstrual, lavender for follicular, plum for ovulation, cream for luteal',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: phases.map((p) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: p.$1,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    p.$2,
                    style: TextStyle(
                      fontSize: 10,
                      color: context.kInkMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _DayDetail extends StatelessWidget {
  const _DayDetail({
    required this.date,
    required this.logs,
    required this.profile,
  });

  final DateTime date;
  final List<CycleLog> logs;
  final HealthProfile profile;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    CyclePhase? phase;
    if (profile.lastPeriodDate != null) {
      phase = CycleEngine.phaseForDate(
        lastPeriodStart: profile.lastPeriodDate!,
        cycleLength: profile.cycleLength,
        periodLength: profile.periodLength,
        date: date,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_fmtDate(date), style: tt.headlineSmall),
                    if (phase != null)
                      Text(
                        '${phase.displayName} · ${phase.description}',
                        style: tt.bodySmall?.copyWith(color: context.kInkMuted),
                      ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => LogBottomSheet.show(context, initialDate: date),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (logs.isEmpty)
            _EmptyDayState()
          else
            ...logs.map((log) => _LogEntry(log: log)),

          if (phase != null)
            Text(
              '* Phase estimates based on your logged settings.',
              style: tt.labelSmall?.copyWith(color: context.kInkSubtle),
            ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }
}

class _EmptyDayState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.kSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.add_circle_outline, color: context.kInkSubtle),
          const SizedBox(width: 12),
          Text(
            'No entries for this day.\nTap + Add to log something.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.kInkMuted,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _LogEntry extends StatelessWidget {
  const _LogEntry({required this.log});
  final CycleLog log;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _eventIcon(log.eventType),
                color: context.isDark ? KholoColors.magenta : KholoColors.plum,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(log.eventType.displayName, style: tt.titleMedium),
              if (log.flow != null) ...[
                const SizedBox(width: 8),
                _Chip(log.flow!.displayName, KholoColors.roseLight, KholoColors.rose),
              ],
              if (log.mood != null) ...[
                const SizedBox(width: 8),
                Text(log.mood!.emoji),
              ],
            ],
          ),
          if (log.symptoms.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: log.symptoms.map((s) =>
                  _Chip(s, KholoColors.lavenderLight, KholoColors.lavenderDark)).toList(),
            ),
          ],
          if (log.notes != null && log.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(log.notes!,
                style: tt.bodySmall?.copyWith(color: context.kInkMuted, height: 1.5)),
          ],
        ],
      ),
    );
  }

  IconData _eventIcon(CycleEventType type) {
    switch (type) {
      case CycleEventType.periodStart:
        return Icons.water_drop_rounded;
      case CycleEventType.periodEnd:
        return Icons.water_drop_outlined;
      case CycleEventType.checkIn:
        return Icons.check_circle_outline_rounded;
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.bg, this.text);
  final String label;
  final Color bg;
  final Color text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, color: text, fontWeight: FontWeight.w500)),
    );
  }
}

class _UpcomingDates extends StatelessWidget {
  const _UpcomingDates({required this.profile});
  final HealthProfile profile;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    if (profile.lastPeriodDate == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Select a day to see details,\nor add your last period to see phase estimates.',
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(color: context.kInkMuted, height: 1.5),
          ),
        ),
      );
    }

    final nextPeriod = CycleEngine.nextPeriodDate(
      lastPeriodStart: profile.lastPeriodDate!,
      cycleLength: profile.cycleLength,
    );
    final window = CycleEngine.getFertilityWindow(
      lastPeriodStart: profile.lastPeriodDate!,
      cycleLength: profile.cycleLength,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upcoming (estimates)', style: tt.titleMedium),
          const SizedBox(height: 4),
          Text('* These are estimates, not medical predictions.',
              style: tt.bodySmall?.copyWith(color: context.kInkSubtle)),
          const SizedBox(height: 16),
          _DateRow(
            label: 'Next period',
            date: nextPeriod,
            color: KholoColors.roseLight,
            accent: KholoColors.rose,
            icon: Icons.water_drop_rounded,
          ),
          const SizedBox(height: 10),
          _DateRow(
            label: 'Fertile window*',
            date: window.start,
            dateEnd: window.end,
            color: KholoColors.lavenderLight,
            accent: KholoColors.lavender,
            icon: Icons.star_outline_rounded,
          ),
          const SizedBox(height: 10),
          _DateRow(
            label: 'Estimated ovulation*',
            date: window.ovulationDate,
            color: KholoColors.lutealTint,
            accent: KholoColors.plum,
            icon: Icons.star_rounded,
          ),
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.date,
    this.dateEnd,
    required this.color,
    required this.accent,
    required this.icon,
  });

  final String label;
  final DateTime date;
  final DateTime? dateEnd;
  final Color color;
  final Color accent;
  final IconData icon;

  String _fmt(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: tt.bodyMedium)),
          Text(
            dateEnd != null ? '${_fmt(date)} – ${_fmt(dateEnd!)}' : _fmt(date),
            style: tt.bodyMedium?.copyWith(
                color: accent, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
