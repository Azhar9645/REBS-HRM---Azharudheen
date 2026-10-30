import 'package:flutter/material.dart';

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 10,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E4E9),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Static placeholder layout mimicking the dashboard while data loads.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const SkeletonBox(width: 44, height: 44, borderRadius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: 140, height: 16),
                  const SizedBox(height: 8),
                  SkeletonBox(
                    width: MediaQuery.sizeOf(context).width * 0.3,
                    height: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const SkeletonBox(height: 220, borderRadius: 20),
        const SizedBox(height: 16),
        const SkeletonBox(height: 110, borderRadius: 18),
        const SizedBox(height: 16),
        const SkeletonBox(height: 180, borderRadius: 18),
      ],
    );
  }
}
