import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_andy/config/routes.dart';
import 'package:system_andy/core/theme/app_theme.dart';
import 'package:system_andy/features/ajustes/presentation/security_settings_page.dart';
import 'package:system_andy/features/auth/application/auth_session_controller.dart';
import 'package:system_andy/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:system_andy/features/layout/components/main_footer.dart';
import 'package:system_andy/features/layout/components/main_header.dart';
import 'package:system_andy/features/layout/components/main_nav.dart';
import 'package:system_andy/features/layout/main/main_panel_section.dart';
import 'package:system_andy/features/ventas/presentation/pages/ventas_page.dart';

class MainPanel extends ConsumerStatefulWidget {
  const MainPanel({
    super.key,
    this.initialSection = MainPanelSection.dashboard,
  });

  final MainPanelSection initialSection;

  @override
  ConsumerState<MainPanel> createState() => _MainPanelState();
}

class _MainPanelState extends ConsumerState<MainPanel> {
  late MainPanelSection _currentSection;

  @override
  void initState() {
    super.initState();
    _currentSection = widget.initialSection;
  }

  void _onSectionSelected(MainPanelSection section) {
    setState(() {
      _currentSection = section;
    });
  }

  void _logout() {
    ref.read(authSessionProvider.notifier).logout();
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authSessionProvider);
    final user = authState.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    final isCompact = MediaQuery.sizeOf(context).width < 900;

    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLow,
      drawer: isCompact
          ? Drawer(
              child: MainNav(
                selectedSection: _currentSection,
                onSectionSelected: _onSectionSelected,
                isDrawer: true,
                onCloseDrawer: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (!isCompact)
                SizedBox(
                  width: 220,
                  child: MainNav(
                    selectedSection: _currentSection,
                    onSectionSelected: _onSectionSelected,
                  ),
                ),
              if (!isCompact) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    Builder(
                      builder: (innerContext) => MainHeader(
                        title: _currentSection == MainPanelSection.ajustes
                            ? 'Seguridad del sistema'
                            : _currentSection.label,
                        userName: user.fullName,
                        userRole: user.role,
                        onLogout: _logout,
                        onOpenMenu: isCompact
                            ? () => Scaffold.of(innerContext).openDrawer()
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _buildSectionContent(_currentSection),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const MainFooter(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContent(MainPanelSection section) {
    switch (section) {
      case MainPanelSection.dashboard:
        return const DashboardPage();
      case MainPanelSection.ventas:
        return const VentasPage();
      case MainPanelSection.inventario:
        return const _ComingSoonView(
          title: 'Inventario',
          subtitle: 'Control de stock y movimientos.',
          icon: Icons.inventory_2_outlined,
        );
      case MainPanelSection.reportes:
        return const _ComingSoonView(
          title: 'Reportes',
          subtitle: 'Indicadores y metricas del negocio.',
          icon: Icons.bar_chart_outlined,
        );
      case MainPanelSection.ajustes:
        return const SecuritySettingsPage();
    }
  }
}

class _ComingSoonView extends StatelessWidget {
  const _ComingSoonView({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: AppTheme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.tertiary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
