import 'package:flutter/material.dart';

enum MainPanelSection {
  dashboard,
  ventas,
  inventario,
  reportes,
  ajustes,
}

extension MainPanelSectionX on MainPanelSection {
  String get label {
    switch (this) {
      case MainPanelSection.dashboard:
        return 'Dashboard';
      case MainPanelSection.ventas:
        return 'Ventas';
      case MainPanelSection.inventario:
        return 'Inventario';
      case MainPanelSection.reportes:
        return 'Reportes';
      case MainPanelSection.ajustes:
        return 'Ajustes';
    }
  }

  IconData get icon {
    switch (this) {
      case MainPanelSection.dashboard:
        return Icons.space_dashboard_outlined;
      case MainPanelSection.ventas:
        return Icons.point_of_sale_outlined;
      case MainPanelSection.inventario:
        return Icons.inventory_2_outlined;
      case MainPanelSection.reportes:
        return Icons.bar_chart_outlined;
      case MainPanelSection.ajustes:
        return Icons.settings_outlined;
    }
  }
}
