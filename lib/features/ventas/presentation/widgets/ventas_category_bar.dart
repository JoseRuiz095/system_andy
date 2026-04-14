import 'package:flutter/material.dart';
import 'package:system_andy/core/theme/app_theme.dart';

class VentasCategoryBar extends StatelessWidget {
  const VentasCategoryBar({super.key});

  @override
  Widget build(BuildContext context) {
    const categories = [
      'Todo',
      'Cafes',
      'Tea & Botanical',
      'Panaderia',
      'Sandwiches',
      'Retail Beans',
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final selected = index == 0;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              color: selected ? AppTheme.primary : AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              categories[index],
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? AppTheme.onPrimary : AppTheme.secondary,
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: categories.length,
      ),
    );
  }
}
