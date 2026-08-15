import 'package:flutter/material.dart';
import '../../app/theme/colors.dart';
import '../../core/models/app_update.dart';
import 'update_dialog.dart';

/// A dismissible in-app banner that appears at the top of the dashboard
/// when a new app version is available.
///
/// Usage in TodayScreen (add near the top of the ListView):
///   if (_update != null) UpdateBanner(update: _update!, onDismiss: () => setState(() => _update = null)),
class UpdateBanner extends StatefulWidget {
  const UpdateBanner({
    super.key,
    required this.update,
    required this.onDismiss,
  });

  final AppUpdate update;
  final VoidCallback onDismiss;

  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return FadeTransition(
      opacity: _fade,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF92003A), Color(0xFFF62477)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: KholoColors.wine.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => UpdateDialog.show(context, widget.update),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                children: [
                  // Icon pulse container
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.system_update_alt_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update available — v${widget.update.latestVersion}',
                          style: tt.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap to download and install',
                          style: tt.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Dismiss button (only if not forced)
                  if (!widget.update.forceUpdate)
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 18),
                      onPressed: _dismiss,
                      tooltip: 'Dismiss',
                    ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
