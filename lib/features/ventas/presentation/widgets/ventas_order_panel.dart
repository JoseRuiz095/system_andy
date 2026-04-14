import 'package:flutter/material.dart';
import 'package:system_andy/core/theme/app_theme.dart';

class VentasOrderPanel extends StatelessWidget {
  const VentasOrderPanel({required this.compact, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cartList = ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      children: const [
        _OrderItem(
          name: 'Flat White',
          details: 'Extra hot, Oat milk',
          quantity: 1,
          price: '\$4.00',
        ),
        _OrderItem(
          name: 'Butter Croissant',
          details: 'Warm',
          quantity: 2,
          price: '\$7.50',
        ),
        _OrderItem(
          name: 'Double Espresso',
          details: 'Single origin',
          quantity: 1,
          price: '\$3.50',
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: Row(
              children: [
                const Text(
                  'Orden #248',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Limpiar'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Text(
                        'SHOT EXTRACTION',
                        style: TextStyle(
                          color: AppTheme.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '85% Complete',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: const LinearProgressIndicator(
                      minHeight: 8,
                      value: 0.85,
                      backgroundColor: AppTheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (compact)
            SizedBox(height: 220, child: cartList)
          else
            Expanded(child: cartList),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Text('Subtotal',
                        style: TextStyle(color: AppTheme.secondary)),
                    Spacer(),
                    Text('\$15.00',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Text('Tax (8%)',
                        style: TextStyle(color: AppTheme.secondary)),
                    Spacer(),
                    Text('\$1.20',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '\$16.20',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.confirmation_number_outlined),
                        label: const Text('Descuento'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.print_outlined),
                        label: const Text('Ticket'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: compact ? 54 : 60,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Completar Orden'),
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

class _OrderItem extends StatelessWidget {
  const _OrderItem({
    required this.name,
    required this.details,
    required this.quantity,
    required this.price,
  });

  final String name;
  final String details;
  final int quantity;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child:
                const Icon(Icons.local_cafe_outlined, color: AppTheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                      price,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: const TextStyle(
                    color: AppTheme.secondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const _QtyButton(icon: Icons.remove),
                    const SizedBox(width: 8),
                    Text(
                      '$quantity',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    const _QtyButton(icon: Icons.add),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: AppTheme.secondary),
    );
  }
}
