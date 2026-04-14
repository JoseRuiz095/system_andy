import 'package:flutter/material.dart';
import 'package:system_andy/core/theme/app_theme.dart';

class MainFooter extends StatelessWidget {
  const MainFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    final isCompact = MediaQuery.sizeOf(context).width < 860;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The Tactile Barista POS',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                ),
                const SizedBox(height: 8),
                const Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _StatusChip(icon: Icons.wifi, label: 'Online'),
                    _StatusChip(icon: Icons.point_of_sale, label: 'Caja activa'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Andy\'s Cafe POS - $year',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            )
          : Row(
              children: [
                Text(
                  'The Tactile Barista POS',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                ),
                const SizedBox(width: 10),
                const _StatusChip(icon: Icons.wifi, label: 'Online'),
                const SizedBox(width: 8),
                const _StatusChip(icon: Icons.point_of_sale, label: 'Caja activa'),
                const Spacer(),
                Text(
                  'Andy\'s Cafe POS - $year',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.secondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.secondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
