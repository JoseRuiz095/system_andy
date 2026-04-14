import 'package:flutter/material.dart';
import 'package:system_andy/core/theme/app_theme.dart';

class MainHeader extends StatelessWidget {
  const MainHeader({
    super.key,
    required this.title,
    required this.userName,
    required this.userRole,
    required this.onLogout,
    this.onOpenMenu,
  });

  final String title;
  final String userName;
  final String userRole;
  final VoidCallback onLogout;
  final VoidCallback? onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 860;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(48, 50, 33, 0.06),
            blurRadius: 24,
            spreadRadius: -8,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (onOpenMenu != null)
                      IconButton(
                        onPressed: onOpenMenu,
                        icon: const Icon(Icons.menu),
                        tooltip: 'Abrir menu',
                      ),
                    if (onOpenMenu != null) const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout),
                      tooltip: 'Cerrar sesion',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const _SearchInput(),
                const SizedBox(height: 10),
                _UserChip(userName: userName, userRole: userRole),
              ],
            )
          : Row(
              children: [
                if (onOpenMenu != null)
                  IconButton(
                    onPressed: onOpenMenu,
                    icon: const Icon(Icons.menu),
                    tooltip: 'Abrir menu',
                  ),
                if (onOpenMenu != null) const SizedBox(width: 6),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const SizedBox(width: 300, child: _SearchInput()),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const _HeaderAction(icon: Icons.wifi_rounded),
                const SizedBox(width: 4),
                const _HeaderAction(icon: Icons.point_of_sale_outlined),
                const SizedBox(width: 4),
                const _HeaderAction(icon: Icons.account_circle_outlined),
                const SizedBox(width: 10),
                _UserChip(userName: userName, userRole: userRole),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout),
                  tooltip: 'Cerrar sesion',
                ),
              ],
            ),
    );
  }
}

class _SearchInput extends StatelessWidget {
  const _SearchInput();

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Buscar productos del menu...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: AppTheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.userName, required this.userRole});

  final String userName;
  final String userRole;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            userName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
          Text(
            userRole,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: AppTheme.secondary),
    );
  }
}
