import 'package:flutter/material.dart';
import 'package:system_andy/features/ventas/presentation/widgets/ventas_category_bar.dart';
import 'package:system_andy/features/ventas/presentation/widgets/ventas_order_panel.dart';
import 'package:system_andy/features/ventas/presentation/widgets/ventas_product_bento_grid.dart';

class VentasPage extends StatelessWidget {
  const VentasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showOrderPanel = constraints.maxWidth >= 1080;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: showOrderPanel ? 8 : 1,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const VentasCategoryBar(),
                    const SizedBox(height: 16),
                    const VentasProductBentoGrid(),
                    if (!showOrderPanel) ...[
                      const SizedBox(height: 16),
                      const VentasOrderPanel(compact: true),
                    ],
                  ],
                ),
              ),
            ),
            if (showOrderPanel) ...[
              const SizedBox(width: 16),
              const SizedBox(
                width: 360,
                child: VentasOrderPanel(compact: false),
              ),
            ],
          ],
        );
      },
    );
  }
}
