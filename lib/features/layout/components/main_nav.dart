import 'package:flutter/material.dart';
import 'package:system_andy/core/theme/app_theme.dart';
import 'package:system_andy/features/layout/main/main_panel_section.dart';

class MainNav extends StatelessWidget {
  const MainNav({
    super.key,
    required this.selectedSection,
    required this.onSectionSelected,
    this.isDrawer = false,
    this.onCloseDrawer,
  });

  final MainPanelSection selectedSection;
  final ValueChanged<MainPanelSection> onSectionSelected;
  final bool isDrawer;
  final VoidCallback? onCloseDrawer;

  @override
  Widget build(BuildContext context) {
    if (isDrawer) {
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 18),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceContainerLow,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The Tactile Barista',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Flagship Store',
                  style: TextStyle(
                    color: AppTheme.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ...MainPanelSection.values.map(
            (section) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              child: _DrawerNavItem(
                section: section,
                selected: section == selectedSection,
                onTap: () {
                  onSectionSelected(section);
                  onCloseDrawer?.call();
                },
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The Tactile Barista',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.tertiary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Flagship Store',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: MainPanelSection.values.length,
              separatorBuilder: (_, __) => const SizedBox(height: 2),
              itemBuilder: (context, index) {
                final section = MainPanelSection.values[index];
                return _RailNavItem(
                  section: section,
                  selected: section == selectedSection,
                  onTap: () => onSectionSelected(section),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => onSectionSelected(MainPanelSection.ventas),
              icon: const Icon(Icons.point_of_sale_outlined),
              label: const Text('Abrir Caja'),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.secondaryContainer,
                  child: Icon(
                    Icons.person,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manager Profile',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Admin Access',
                        style: TextStyle(
                          color: AppTheme.secondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
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

class _RailNavItem extends StatelessWidget {
  const _RailNavItem({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final MainPanelSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.surfaceContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border(
              right: BorderSide(
                color: selected ? AppTheme.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                section.icon,
                size: 20,
                color: selected ? AppTheme.primary : AppTheme.secondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  section.label,
                  style: TextStyle(
                    color: selected ? AppTheme.primary : AppTheme.secondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerNavItem extends StatelessWidget {
  const _DrawerNavItem({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final MainPanelSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: selected ? AppTheme.surfaceContainer : Colors.transparent,
      leading: Icon(
        section.icon,
        color: selected ? AppTheme.primary : AppTheme.secondary,
      ),
      title: Text(
        section.label,
        style: TextStyle(
          color: selected ? AppTheme.primary : AppTheme.secondary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}
