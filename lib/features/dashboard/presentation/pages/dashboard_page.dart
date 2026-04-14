import 'package:flutter/material.dart';
import 'package:system_andy/core/theme/app_theme.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 980;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AnalyticsHero(),
              const SizedBox(height: 14),
              _KpiGrid(isCompact: isCompact),
              const SizedBox(height: 14),
              if (isCompact) ...[
                const _SalesTrendCard(),
                const SizedBox(height: 12),
                const _ChannelShareCard(),
              ] else
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: _SalesTrendCard()),
                    SizedBox(width: 12),
                    Expanded(flex: 5, child: _ChannelShareCard()),
                  ],
                ),
              const SizedBox(height: 14),
              if (isCompact) ...[
                const _TopProductsCard(),
                const SizedBox(height: 12),
                const _OperationsFeedCard(),
              ] else
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: _TopProductsCard()),
                    SizedBox(width: 12),
                    Expanded(flex: 6, child: _OperationsFeedCard()),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AnalyticsHero extends StatelessWidget {
  const _AnalyticsHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4D342B), Color(0xFF002C06)],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DASHBOARD OPERATIVO',
            style: TextStyle(
              color: Color(0xFFE8E2D7),
              letterSpacing: 1.2,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Panorama de analiticas en tiempo real',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Ventas, rendimiento por canal y señales de operacion de caja.',
            style: TextStyle(
              color: Color(0xFFE8E2D7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    const cards = [
      _KpiCard(
        title: 'Ingresos del dia',
        value: '\$ 48,520',
        delta: '+12.4%',
        positive: true,
        icon: Icons.attach_money,
      ),
      _KpiCard(
        title: 'Tickets emitidos',
        value: '324',
        delta: '+8.1%',
        positive: true,
        icon: Icons.receipt_long_outlined,
      ),
      _KpiCard(
        title: 'Ticket promedio',
        value: '\$ 149.8',
        delta: '-1.3%',
        positive: false,
        icon: Icons.point_of_sale_outlined,
      ),
      _KpiCard(
        title: 'Tiempo de atencion',
        value: '03:24',
        delta: '-11s',
        positive: true,
        icon: Icons.timer_outlined,
      ),
    ];

    if (isCompact) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i != cards.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.65,
      children: cards,
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.delta,
    required this.positive,
    required this.icon,
  });

  final String title;
  final String value;
  final String delta;
  final bool positive;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final deltaColor = positive ? AppTheme.primary : Colors.red.shade700;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(icon, size: 18, color: AppTheme.secondary),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                positive ? Icons.trending_up : Icons.trending_down,
                color: deltaColor,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                delta,
                style: TextStyle(
                  color: deltaColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SalesTrendCard extends StatelessWidget {
  const _SalesTrendCard();

  @override
  Widget build(BuildContext context) {
    const values = [0.28, 0.45, 0.37, 0.62, 0.52, 0.74, 0.66, 0.85, 0.73, 0.9];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tendencia de ventas (hoy)',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Comparativo por bloques de hora.',
            style: TextStyle(
              color: AppTheme.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 170,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final v in values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: v,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.86),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelShareCard extends StatelessWidget {
  const _ChannelShareCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Participacion por canal',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12),
          _ChannelRow(label: 'Mostrador', share: 0.52),
          SizedBox(height: 10),
          _ChannelRow(label: 'Delivery', share: 0.28),
          SizedBox(height: 10),
          _ChannelRow(label: 'Pick-up', share: 0.20),
        ],
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({required this.label, required this.share});

  final String label;
  final double share;

  @override
  Widget build(BuildContext context) {
    final pct = (share * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '$pct%',
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: share,
            backgroundColor: AppTheme.surfaceContainerHighest,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
      ],
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top productos del turno',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12),
          _TopProductItem(name: 'Flat White', units: 64, revenue: '\$ 256.0'),
          SizedBox(height: 10),
          _TopProductItem(name: 'Butter Croissant', units: 51, revenue: '\$ 191.3'),
          SizedBox(height: 10),
          _TopProductItem(name: 'Double Espresso', units: 46, revenue: '\$ 161.0'),
          SizedBox(height: 10),
          _TopProductItem(name: 'Avocado Toast', units: 31, revenue: '\$ 372.0'),
        ],
      ),
    );
  }
}

class _TopProductItem extends StatelessWidget {
  const _TopProductItem({
    required this.name,
    required this.units,
    required this.revenue,
  });

  final String name;
  final int units;
  final String revenue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          '$units u.',
          style: const TextStyle(
            color: AppTheme.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          revenue,
          style: const TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _OperationsFeedCard extends StatelessWidget {
  const _OperationsFeedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Feed operativo',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12),
          _FeedItem(
            title: 'Caja 02 supero 40 tickets/h',
            time: 'Hace 3 min',
            icon: Icons.notifications_active_outlined,
          ),
          SizedBox(height: 10),
          _FeedItem(
            title: 'Merma baja en panaderia (2.1%)',
            time: 'Hace 8 min',
            icon: Icons.trending_up_outlined,
          ),
          SizedBox(height: 10),
          _FeedItem(
            title: 'Espera promedio en cola: 4m 12s',
            time: 'Hace 14 min',
            icon: Icons.schedule_outlined,
          ),
          SizedBox(height: 10),
          _FeedItem(
            title: 'Stock critico: Oat Milk (13 unidades)',
            time: 'Hace 19 min',
            icon: Icons.warning_amber_outlined,
          ),
        ],
      ),
    );
  }
}

class _FeedItem extends StatelessWidget {
  const _FeedItem({
    required this.title,
    required this.time,
    required this.icon,
  });

  final String title;
  final String time;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: AppTheme.secondary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: const TextStyle(
                  color: AppTheme.secondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
