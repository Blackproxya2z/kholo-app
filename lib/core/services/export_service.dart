import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/models/cycle_log.dart';

/// Exports health/cycle data as a CSV file and triggers the system share sheet.
class ExportService {
  ExportService._();

  /// Builds a CSV from [logs] and opens the system share sheet.
  static Future<void> exportCycleLogs(
    BuildContext context,
    List<CycleLog> logs,
  ) async {
    try {
      final buffer = StringBuffer();
      // Header
      buffer.writeln('Date,EventType,Flow,Mood,Symptoms,Notes');

      for (final log in logs) {
        final date =
            '${log.eventDate.year}-${log.eventDate.month.toString().padLeft(2, '0')}-${log.eventDate.day.toString().padLeft(2, '0')}';
        final eventType = log.eventType.displayName;
        final flow = log.flow?.displayName ?? '';
        final mood = log.mood?.displayName ?? '';
        final symptoms = log.symptoms.join('; ');
        final notes = (log.notes ?? '').replaceAll(',', ' ');
        buffer.writeln('$date,$eventType,$flow,$mood,"$symptoms",$notes');
      }

      // Write to temp file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/kholo_cycle_export.csv');
      await file.writeAsString(buffer.toString());

      if (!context.mounted) return;

      // Share sheet
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: 'KHOLO Cycle Log Export',
        text: 'My cycle log exported from KHOLO app.',
      );
    } catch (e) {
      debugPrint('[ExportService] error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export failed. Please try again.')),
        );
      }
    }
  }
}
