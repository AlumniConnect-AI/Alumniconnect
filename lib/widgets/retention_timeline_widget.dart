import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/theme.dart';
import '../models/outcome_tracking_model.dart';

/// Shared retention timeline widget — used in both Student Home and Alumni Home.
/// Reads outcome_tracking/{uid}.status in real-time and renders 5 stage-dots.
class RetentionTimelineWidget extends StatelessWidget {
  final String uid;

  const RetentionTimelineWidget({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('outcome_tracking')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        String status = 'trained';
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          status = data?['status'] ?? 'trained';
        }

        final model = OutcomeTrackingModel(uid: uid, status: status);
        final stageIdx = model.stageIndex; // -1 if dropped_off
        final isDropped = model.isDroppedOff;

        final stages = [
          _StageInfo('Trained', Icons.school_outlined),
          _StageInfo('Placed', Icons.work_outline),
          _StageInfo('3 Months', Icons.timelapse),
          _StageInfo('6 Months', Icons.trending_up),
          _StageInfo('12 Months', Icons.verified_outlined),
        ];

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.cardDark
                : theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? AppColors.primaryNeon.withOpacity(0.15)
                  : theme.dividerColor,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppGradients.emeraldCyan,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.timeline, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "My Career Journey",
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  _statusBadge(status, isDropped),
                ],
              ),

              const SizedBox(height: 20),

              // ── Stage dots row ──────────────────────────────────────
              Row(
                children: List.generate(stages.length * 2 - 1, (i) {
                  if (i.isOdd) {
                    // Connector line
                    final stageBeforeConnector = i ~/ 2;
                    final completed = !isDropped && stageBeforeConnector < stageIdx;
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: completed
                              ? AppGradients.emeraldCyan
                              : null,
                          color: completed
                              ? null
                              : theme.dividerColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }

                  final dotIdx = i ~/ 2;
                  final isDone = !isDropped && dotIdx <= stageIdx;
                  final isCurrent = !isDropped && dotIdx == stageIdx;
                  // Last completed dot in dropped_off case
                  final isDroppedDot = isDropped && dotIdx == stageIdx;

                  Color dotColor;
                  if (isDropped && isDroppedDot) {
                    dotColor = AppColors.warning;
                  } else if (isDone) {
                    dotColor = AppColors.accentEmerald;
                  } else {
                    dotColor = theme.dividerColor;
                  }

                  return _StageDot(
                    stage: stages[dotIdx],
                    isDone: isDone,
                    isCurrent: isCurrent,
                    isDropped: isDropped && isDroppedDot,
                    dotColor: dotColor,
                  );
                }),
              ),

              const SizedBox(height: 14),

              // ── Stage labels ────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: stages.asMap().entries.map((e) {
                  final labelIdx = e.key;
                  final isDone = !isDropped && labelIdx <= stageIdx;
                  return Expanded(
                    child: Text(
                      e.value.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight:
                            isDone ? FontWeight.bold : FontWeight.normal,
                        color: isDone
                            ? AppColors.accentEmerald
                            : theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.5),
                      ),
                    ),
                  );
                }).toList(),
              ),

              if (isDropped) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.warning, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Progress paused. Update your status to continue your journey.",
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _statusBadge(String status, bool isDropped) {
    Color bg;
    String label;

    if (isDropped) {
      bg = AppColors.warning;
      label = 'Paused';
    } else {
      switch (status) {
        case 'placed':
          bg = AppColors.accentEmerald;
          label = 'Placed ✓';
          break;
        case 'retained_3mo':
          bg = AppColors.accentBlue;
          label = '3mo Retained';
          break;
        case 'retained_6mo':
          bg = AppColors.accentPurple;
          label = '6mo Retained';
          break;
        case 'retained_12mo':
          bg = AppColors.primaryNeon;
          label = '12mo Retained';
          break;
        default:
          bg = AppColors.primary;
          label = 'Trained';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bg.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: bg,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StageInfo {
  final String label;
  final IconData icon;
  _StageInfo(this.label, this.icon);
}

class _StageDot extends StatelessWidget {
  final _StageInfo stage;
  final bool isDone;
  final bool isCurrent;
  final bool isDropped;
  final Color dotColor;

  const _StageDot({
    required this.stage,
    required this.isDone,
    required this.isCurrent,
    required this.isDropped,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: isCurrent ? 34 : 26,
          height: isCurrent ? 34 : 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone || isDropped ? dotColor : Colors.transparent,
            border: Border.all(
              color: dotColor,
              width: isCurrent ? 2.5 : 1.5,
            ),
            boxShadow: isDone
                ? [
                    BoxShadow(
                      color: dotColor.withOpacity(0.4),
                      blurRadius: isCurrent ? 12 : 6,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              isDone ? Icons.check : stage.icon,
              size: isCurrent ? 16 : 12,
              color: isDone || isDropped ? Colors.white : dotColor,
            ),
          ),
        ),
      ],
    );
  }
}
