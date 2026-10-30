import 'package:flutter/material.dart';

class SyncStatCard extends StatelessWidget {
  const SyncStatCard({
    super.key,
    required this.count,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final int count;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: foreground,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
