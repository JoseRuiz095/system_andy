import 'package:flutter/material.dart';
import 'package:system_andy/core/theme/app_theme.dart';

class VentasProductBentoGrid extends StatelessWidget {
  const VentasProductBentoGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTight = width < 760;
        final gridColumns = width >= 980
            ? 3
            : width >= 640
                ? 2
                : 1;

        return Column(
          children: [
            if (isTight) ...[
              const _FeaturedItemCard(),
              const SizedBox(height: 12),
              const _QuickMenuCard(
                title: 'Oat Milk Latte',
                subtitle: 'Double shot espresso',
                price: '\$4.20',
                icon: Icons.coffee_outlined,
                highlighted: true,
              ),
              const SizedBox(height: 12),
              const _QuickMenuCard(
                title: 'Butter Croissant',
                subtitle: 'Flaky, 24-hour fermented',
                price: '\$3.75',
                icon: Icons.bakery_dining_outlined,
              ),
            ] else ...[
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _FeaturedItemCard(),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        _QuickMenuCard(
                          title: 'Oat Milk Latte',
                          subtitle: 'Double shot espresso',
                          price: '\$4.20',
                          icon: Icons.coffee_outlined,
                          highlighted: true,
                        ),
                        SizedBox(height: 12),
                        _QuickMenuCard(
                          title: 'Butter Croissant',
                          subtitle: 'Flaky, 24-hour fermented',
                          price: '\$3.75',
                          icon: Icons.bakery_dining_outlined,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: gridColumns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: const [
                _ProductSquareCard(
                  title: 'Flat White',
                  price: '\$4.00',
                  icon: Icons.local_cafe_outlined,
                ),
                _ProductSquareCard(
                  title: 'Double Espresso',
                  price: '\$3.50',
                  icon: Icons.coffee_maker_outlined,
                ),
                _ProductSquareCard(
                  title: 'Avocado Toast',
                  price: '\$12.00',
                  icon: Icons.breakfast_dining_outlined,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _FeaturedItemCard extends StatelessWidget {
  const _FeaturedItemCard();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF5A3E2A),
              Color(0xFF23160F),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primaryFixed,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'STAFF PICK',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const Spacer(),
            const Text(
              'Signature Pour Over',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ethiopian Yirgacheffe de origen unico',
              style: TextStyle(
                color: Color(0xFFE8DFD5),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                '\$6.50',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickMenuCard extends StatelessWidget {
  const _QuickMenuCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.icon,
    this.highlighted = false,
  });

  final String title;
  final String subtitle;
  final String price;
  final IconData icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            highlighted ? AppTheme.primaryFixed : AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: highlighted
                      ? Colors.white.withValues(alpha: 0.28)
                      : AppTheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppTheme.primary),
              ),
              const Spacer(),
              Text(
                price,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductSquareCard extends StatelessWidget {
  const _ProductSquareCard({
    required this.title,
    required this.price,
    required this.icon,
  });

  final String title;
  final String price;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: AppTheme.surfaceContainerHighest,
              ),
              child: Icon(icon, color: AppTheme.secondary, size: 34),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                price,
                style: const TextStyle(
                  color: AppTheme.secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Icon(Icons.add_circle, color: AppTheme.primary, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}
