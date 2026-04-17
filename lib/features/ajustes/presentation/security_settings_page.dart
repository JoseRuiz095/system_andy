import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_andy/core/database/app_database.dart';
import 'package:system_andy/core/theme/app_theme.dart';
import 'package:system_andy/features/ajustes/application/security_management_controller.dart';
import 'package:system_andy/features/auth/application/auth_session_controller.dart';

class SecuritySettingsPage extends ConsumerStatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  ConsumerState<SecuritySettingsPage> createState() =>
      _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends ConsumerState<SecuritySettingsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initialSearch = ref.read(securityManagementProvider).auditSearch;
    _searchController.text = initialSearch;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(securityManagementProvider);
    final authState = ref.watch(authSessionProvider);
    final controller = ref.read(securityManagementProvider.notifier);
    final canConfigure = authState.currentUser != null &&
        ref
            .read(authSessionProvider.notifier)
            .hasPermission('configurar_sistema');

    ref.listen<SecurityManagementState>(securityManagementProvider,
        (previous, next) {
      final previousMessage = previous?.message;
      final previousError = previous?.lastError;

      if (next.message != null && next.message != previousMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message!),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }

      if (next.lastError != null && next.lastError != previousError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.lastError!),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final useDualColumn = constraints.maxWidth >= 1180;
        final showSettingsSidebar = constraints.maxWidth >= 1024;

        return Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SecurityHero(isAdmin: canConfigure),
                  const SizedBox(height: 14),
                  if (showSettingsSidebar)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 220,
                          child: _SettingsSidebar(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildContentGrid(
                            useDualColumn: useDualColumn,
                            canConfigure: canConfigure,
                            state: state,
                            controller: controller,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    const _SecuritySectionTabs(),
                    const SizedBox(height: 12),
                    _buildContentGrid(
                      useDualColumn: false,
                      canConfigure: canConfigure,
                      state: state,
                      controller: controller,
                    ),
                  ],
                ],
              ),
            ),
            if (state.isLoading || state.isSaving)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 3),
              ),
          ],
        );
      },
    );
  }

  Widget _buildContentGrid({
    required bool useDualColumn,
    required bool canConfigure,
    required SecurityManagementState state,
    required SecurityManagementController controller,
  }) {
    final cards = [
      _buildUsersCard(
        canConfigure: canConfigure,
        state: state,
        controller: controller,
      ),
      _buildRolesAndPermissionsCard(
        canConfigure: canConfigure,
        state: state,
        controller: controller,
      ),
      _buildAuditCard(state: state, controller: controller),
      _buildPrivacyCard(
        canConfigure: canConfigure,
        state: state,
        controller: controller,
      ),
    ];

    if (!useDualColumn) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i != cards.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards[2]),
            const SizedBox(width: 12),
            Expanded(child: cards[3]),
          ],
        ),
      ],
    );
  }

  Widget _buildUsersCard({
    required bool canConfigure,
    required SecurityManagementState state,
    required SecurityManagementController controller,
  }) {
    return _SecurityCard(
      title: 'Autenticacion de usuarios',
      subtitle: 'Lista real de usuarios registrados y su estado de seguridad.',
      icon: Icons.verified_user_outlined,
      action: _PillInfo(
        label:
            'Pendientes: ${state.users.where((user) => user.status == 'pending').length}',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.users.isEmpty)
            const _EmptyCardText(
              'No hay usuarios para mostrar.',
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
                dataTextStyle: const TextStyle(
                  color: AppTheme.tertiary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                columns: const [
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Correo / Usuario')),
                  DataColumn(label: Text('Rol')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Ultimo acceso')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: state.users
                    .map(
                      (user) => DataRow(
                        cells: [
                          DataCell(Text(user.fullName)),
                          DataCell(Text(user.email ?? user.username)),
                          DataCell(
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _roleCodeFromName(
                                  user.role,
                                  state.roles,
                                ),
                                items: state.roles
                                    .map(
                                      (role) => DropdownMenuItem<String>(
                                        value: role.roleCode,
                                        child: Text(role.roleName),
                                      ),
                                    )
                                    .toList(),
                                onChanged: canConfigure
                                    ? (nextRoleCode) {
                                        if (nextRoleCode == null) return;
                                        controller.changeUserRole(
                                          user.id,
                                          nextRoleCode,
                                        );
                                      }
                                    : null,
                              ),
                            ),
                          ),
                          DataCell(_StatusChip(status: user.status)),
                          DataCell(Text(_formatDateTime(user.lastAccessAt))),
                          DataCell(
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if (user.status == 'pending')
                                  OutlinedButton.icon(
                                    onPressed: canConfigure
                                        ? () => controller.validateUser(user.id)
                                        : null,
                                    icon: const Icon(Icons.verified_outlined,
                                        size: 16),
                                    label: const Text('Validar'),
                                  ),
                                IconButton(
                                  tooltip: user.status == 'blocked'
                                      ? 'Desbloquear usuario'
                                      : 'Bloquear usuario',
                                  onPressed: canConfigure
                                      ? () =>
                                          _confirmBlockToggle(user, controller)
                                      : null,
                                  icon: Icon(
                                    user.status == 'blocked'
                                        ? Icons.lock_open_outlined
                                        : Icons.lock_outline,
                                    color: AppTheme.secondary,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Restablecer contrasena',
                                  onPressed: canConfigure
                                      ? () =>
                                          _promptResetPassword(user, controller)
                                      : null,
                                  icon: const Icon(
                                    Icons.restart_alt_outlined,
                                    color: AppTheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRolesAndPermissionsCard({
    required bool canConfigure,
    required SecurityManagementState state,
    required SecurityManagementController controller,
  }) {
    final selectedRole = state.selectedRoleCode;
    final permissionSet = selectedRole == null
        ? <String>{}
        : (state.rolePermissions[selectedRole] ?? <String>{});

    return _SecurityCard(
      title: 'Roles y permisos',
      subtitle: 'RBAC persistente por rol con guardado real en base de datos.',
      icon: Icons.admin_panel_settings_outlined,
      action: ElevatedButton.icon(
        onPressed: canConfigure ? controller.saveSelectedRolePermissions : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.tertiary,
          foregroundColor: Colors.white,
        ),
        icon: const Icon(Icons.save_outlined),
        label: const Text('Guardar cambios'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.roles.isEmpty)
            const _EmptyCardText('No hay roles configurados.')
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.roles
                  .map(
                    (role) => ChoiceChip(
                      label: Text(role.roleName),
                      avatar: Icon(_roleIcon(role.roleCode), size: 16),
                      selected: selectedRole == role.roleCode,
                      selectedColor: AppTheme.secondaryContainer,
                      backgroundColor: AppTheme.surfaceContainerLow,
                      onSelected: (_) => controller.selectRole(role.roleCode),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 4),
            ...state.permissionsCatalog.map(
              (permission) => SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _permissionLabel(permission.code),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  permission.code,
                  style: const TextStyle(
                    color: AppTheme.secondary,
                    fontSize: 11,
                  ),
                ),
                value: permissionSet.contains(permission.code),
                activeThumbColor: AppTheme.chlorophyllGreen,
                activeTrackColor:
                    AppTheme.chlorophyllGreen.withValues(alpha: 0.3),
                onChanged: (enabled) {
                  if (selectedRole == null || !canConfigure) return;
                  controller.togglePermission(
                    selectedRole,
                    permission.code,
                    enabled,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuditCard({
    required SecurityManagementState state,
    required SecurityManagementController controller,
  }) {
    final totalPages = state.auditPageSize == 0
        ? 1
        : (state.auditTotal / state.auditPageSize).ceil();
    final currentPage = state.auditPage + 1;

    final userFilters = <_UserFilterOption>[
      const _UserFilterOption(label: 'Todos', userId: null),
      ...state.users.map(
        (user) => _UserFilterOption(label: user.fullName, userId: user.id),
      ),
    ];

    final actionOptions = <String>{
      for (final row in state.auditLogs) row.eventAction,
      if (state.auditAction != null) state.auditAction!,
    }.toList()
      ..sort();

    final moduleOptions = <String>{
      for (final row in state.auditLogs) row.module,
      if (state.auditModule != null) state.auditModule!,
    }.toList()
      ..sort();

    return _SecurityCard(
      title: 'Auditoria de operaciones',
      subtitle: 'Eventos inmutables con filtros y busqueda en tiempo real.',
      icon: Icons.fact_check_outlined,
      action: OutlinedButton.icon(
        onPressed:
            state.auditLogs.isEmpty ? null : () => _showAuditExportInfo(),
        icon: const Icon(Icons.file_download_outlined),
        label: const Text('Exportar auditoria'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AuditFilter(
                label: 'Usuario',
                value: userFilters
                    .firstWhere(
                      (option) => option.userId == state.auditUserId,
                      orElse: () => userFilters.first,
                    )
                    .label,
                options: userFilters.map((option) => option.label).toList(),
                onChanged: (label) {
                  final selected = userFilters.firstWhere(
                    (option) => option.label == label,
                    orElse: () => userFilters.first,
                  );
                  controller.updateAuditFilters(
                    userId: selected.userId,
                    clearUser: selected.userId == null,
                  );
                },
              ),
              _AuditFilter(
                label: 'Accion',
                value: state.auditAction ?? 'Todas',
                options: ['Todas', ...actionOptions],
                onChanged: (value) {
                  controller.updateAuditFilters(
                    action: value == 'Todas' ? null : value,
                    clearAction: value == 'Todas',
                  );
                },
              ),
              _AuditFilter(
                label: 'Modulo',
                value: state.auditModule ?? 'Todos',
                options: ['Todos', ...moduleOptions],
                onChanged: (value) {
                  controller.updateAuditFilters(
                    module: value == 'Todos' ? null : value,
                    clearModule: value == 'Todos',
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            onSubmitted: (value) =>
                controller.updateAuditFilters(search: value),
            decoration: InputDecoration(
              hintText: 'Buscar por usuario, accion, modulo o descripcion...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: () {
                  _searchController.clear();
                  controller.updateAuditFilters(search: '');
                },
                icon: const Icon(Icons.close),
              ),
              fillColor: AppTheme.surfaceContainerHighest,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (state.auditLogs.isEmpty)
            const _EmptyCardText(
                'No hay eventos para los filtros seleccionados.')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
                dataTextStyle: const TextStyle(
                  color: AppTheme.tertiary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                columns: const [
                  DataColumn(label: Text('Fecha y hora')),
                  DataColumn(label: Text('Usuario')),
                  DataColumn(label: Text('Accion realizada')),
                  DataColumn(label: Text('Modulo')),
                  DataColumn(label: Text('Resultado')),
                  DataColumn(label: Text('IP / Dispositivo')),
                ],
                rows: state.auditLogs
                    .map(
                      (row) => DataRow(
                        cells: [
                          DataCell(Text(_formatDateTime(row.createdAt))),
                          DataCell(Text(row.user)),
                          DataCell(_AuditActionChip(action: row.eventAction)),
                          DataCell(Text(row.module)),
                          DataCell(_AuditResultChip(result: row.result)),
                          DataCell(
                              Text('${row.ipAddress} / ${row.deviceInfo}')),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Total: ${state.auditTotal} registros',
                style: const TextStyle(
                  color: AppTheme.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: state.auditPage > 0
                    ? () => controller.setAuditPage(state.auditPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '$currentPage / ${max(totalPages, 1)}',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                onPressed: state.auditPage + 1 < max(totalPages, 1)
                    ? () => controller.setAuditPage(state.auditPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard({
    required bool canConfigure,
    required SecurityManagementState state,
    required SecurityManagementController controller,
  }) {
    final sessionMinutes =
        int.tryParse(state.settings['session_expiration_minutes'] ?? '480') ??
            480;
    final maxAttempts =
        int.tryParse(state.settings['max_failed_attempts'] ?? '5') ?? 5;
    final lockoutMinutes =
        int.tryParse(state.settings['lockout_minutes'] ?? '15') ?? 15;
    final strongPassword =
        (state.settings['strong_password_required'] ?? 'true') == 'true';
    final forceRotation =
        (state.settings['force_password_rotation'] ?? 'true') == 'true';
    final twoFactorEnabled =
        (state.settings['two_factor_enabled'] ?? 'false') == 'true';
    final maskSensitive =
        (state.settings['mask_sensitive_data'] ?? 'true') == 'true';

    return _SecurityCard(
      title: 'Privacidad y proteccion de datos',
      subtitle: 'Ajustes persistentes de endurecimiento y sesion.',
      icon: Icons.lock_person_outlined,
      child: Column(
        children: [
          _ConfigItem(
            title: 'Tiempo de expiracion de sesion',
            description:
                'Define minutos maximos de inactividad antes de cerrar sesion.',
            trailing: DropdownButton<int>(
              value: [60, 120, 240, 480, 720].contains(sessionMinutes)
                  ? sessionMinutes
                  : 480,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(12),
              items: const [60, 120, 240, 480, 720]
                  .map(
                    (minutes) => DropdownMenuItem<int>(
                      value: minutes,
                      child: Text('$minutes min'),
                    ),
                  )
                  .toList(),
              onChanged: canConfigure
                  ? (value) {
                      if (value == null) return;
                      controller.saveSetting(
                        'session_expiration_minutes',
                        value.toString(),
                      );
                    }
                  : null,
            ),
          ),
          _ConfigItem(
            title: 'Bloquear usuario tras intentos fallidos',
            description:
                'Cantidad maxima de intentos antes de bloqueo temporal.',
            trailing: DropdownButton<int>(
              value: [3, 4, 5, 6, 7].contains(maxAttempts) ? maxAttempts : 5,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(12),
              items: const [3, 4, 5, 6, 7]
                  .map(
                    (value) => DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value intentos'),
                    ),
                  )
                  .toList(),
              onChanged: canConfigure
                  ? (value) {
                      if (value == null) return;
                      controller.saveSetting(
                          'max_failed_attempts', value.toString());
                    }
                  : null,
            ),
          ),
          _ConfigItem(
            title: 'Duracion de bloqueo temporal',
            description: 'Tiempo de bloqueo tras exceder intentos fallidos.',
            trailing: DropdownButton<int>(
              value: [5, 10, 15, 30, 60].contains(lockoutMinutes)
                  ? lockoutMinutes
                  : 15,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(12),
              items: const [5, 10, 15, 30, 60]
                  .map(
                    (value) => DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value min'),
                    ),
                  )
                  .toList(),
              onChanged: canConfigure
                  ? (value) {
                      if (value == null) return;
                      controller.saveSetting(
                          'lockout_minutes', value.toString());
                    }
                  : null,
            ),
          ),
          _ConfigItem(
            title: 'Solicitar cambio de contrasena periodico',
            description:
                'Forzar rotacion de credenciales para todo el personal.',
            trailing: Switch.adaptive(
              value: forceRotation,
              activeThumbColor: AppTheme.chlorophyllGreen,
              activeTrackColor:
                  AppTheme.chlorophyllGreen.withValues(alpha: 0.3),
              onChanged: canConfigure
                  ? (value) => controller.saveSetting(
                        'force_password_rotation',
                        value.toString(),
                      )
                  : null,
            ),
          ),
          _ConfigItem(
            title: 'Requerir contrasena fuerte',
            description: 'Minimo longitud y complejidad para nuevas claves.',
            trailing: Switch.adaptive(
              value: strongPassword,
              activeThumbColor: AppTheme.chlorophyllGreen,
              activeTrackColor:
                  AppTheme.chlorophyllGreen.withValues(alpha: 0.3),
              onChanged: canConfigure
                  ? (value) => controller.saveSetting(
                        'strong_password_required',
                        value.toString(),
                      )
                  : null,
            ),
          ),
          _ConfigItem(
            title: 'Activar autenticacion de dos factores',
            description:
                'Bandera de preparacion para 2FA en futuras versiones.',
            trailing: Switch.adaptive(
              value: twoFactorEnabled,
              activeThumbColor: AppTheme.chlorophyllGreen,
              activeTrackColor:
                  AppTheme.chlorophyllGreen.withValues(alpha: 0.3),
              onChanged: canConfigure
                  ? (value) => controller.saveSetting(
                        'two_factor_enabled',
                        value.toString(),
                      )
                  : null,
            ),
          ),
          _ConfigItem(
            title: 'Ocultar datos sensibles en pantalla',
            description:
                'Mascara datos criticos en vistas operativas y ajustes.',
            trailing: Switch.adaptive(
              value: maskSensitive,
              activeThumbColor: AppTheme.chlorophyllGreen,
              activeTrackColor:
                  AppTheme.chlorophyllGreen.withValues(alpha: 0.3),
              onChanged: canConfigure
                  ? (value) => controller.saveSetting(
                        'mask_sensitive_data',
                        value.toString(),
                      )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBlockToggle(
    SecurityUserView user,
    SecurityManagementController controller,
  ) async {
    final action = user.status == 'blocked' ? 'desbloquear' : 'bloquear';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action[0].toUpperCase()}${action.substring(1)} usuario'),
        content: Text('Confirma que deseas $action a ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.toggleBlockUser(user);
    }
  }

  Future<void> _promptResetPassword(
    SecurityUserView user,
    SecurityManagementController controller,
  ) async {
    final tempPassword = _generateTemporaryPassword();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restablecer contrasena'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Usuario: ${user.fullName}'),
            const SizedBox(height: 8),
            Text('Clave temporal sugerida: $tempPassword'),
            const SizedBox(height: 8),
            const Text(
              'Se forzara cambio de contrasena en el siguiente inicio de sesion.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.resetPassword(user.id, tempPassword);
    }
  }

  void _showAuditExportInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar auditoria'),
        content: const Text(
          'La exportacion se encuentra en cola para backend/API.\n\n'
          'Los filtros y paginacion ya estan aplicados en la consulta real.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  String _roleCodeFromName(String roleName, List<RolePermissionView> roles) {
    for (final role in roles) {
      if (role.roleName.toLowerCase() == roleName.toLowerCase()) {
        return role.roleCode;
      }
    }
    return roles.isNotEmpty ? roles.first.roleCode : roleName.toLowerCase();
  }

  String _permissionLabel(String code) {
    const labels = {
      'registrar_venta': 'Registrar ventas',
      'procesar_cobro': 'Procesar cobros',
      'abrir_caja': 'Abrir caja',
      'cerrar_caja': 'Cerrar caja',
      'ajustar_inventario': 'Ajustar inventario',
      'gestionar_productos': 'Gestionar productos',
      'ver_reportes': 'Ver reportes',
      'cancelar_venta': 'Cancelar ventas',
      'aplicar_descuento': 'Aplicar descuentos',
      'generar_factura': 'Generar facturas',
      'configurar_sistema': 'Configurar sistema',
    };
    return labels[code] ?? code;
  }

  IconData _roleIcon(String roleCode) {
    switch (roleCode) {
      case 'admin':
        return Icons.shield_outlined;
      case 'barista':
        return Icons.coffee_outlined;
      default:
        return Icons.point_of_sale_outlined;
    }
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'Sin registro';
    final local = value.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year.toString().padLeft(4, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  String _generateTemporaryPassword() {
    const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    const lower = 'abcdefghijkmnopqrstuvwxyz';
    const numbers = '23456789';
    const symbols = '!@#%&*';
    final random = Random.secure();

    final chars = <String>[
      upper[random.nextInt(upper.length)],
      lower[random.nextInt(lower.length)],
      numbers[random.nextInt(numbers.length)],
      symbols[random.nextInt(symbols.length)],
    ];

    const all = '$upper$lower$numbers$symbols';
    while (chars.length < 12) {
      chars.add(all[random.nextInt(all.length)]);
    }

    chars.shuffle(random);
    return chars.join();
  }
}

class _SecurityHero extends StatelessWidget {
  const _SecurityHero({required this.isAdmin});

  final bool isAdmin;

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
          colors: [Color(0xFF725A42), Color(0xFF351F17)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(53, 31, 23, 0.18),
            blurRadius: 22,
            spreadRadius: -8,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield_moon_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SEGURIDAD DEL SISTEMA',
                  style: TextStyle(
                    color: Color(0xFFFBEEDB),
                    letterSpacing: 1.1,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Control centralizado de acceso, permisos y auditoria',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAdmin
                      ? 'Modo administrador: puedes ejecutar acciones sensibles.'
                      : 'Modo consulta: acciones sensibles bloqueadas por permisos.',
                  style: const TextStyle(
                    color: Color(0xFFF3E6D5),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

class _SettingsSidebar extends StatelessWidget {
  const _SettingsSidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(8, 6, 8, 12),
            child: Text(
              'Ajustes',
              style: TextStyle(
                color: AppTheme.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _SidebarItem(
            title: 'Seguridad',
            subtitle: 'Acceso y auditoria',
            icon: Icons.shield_outlined,
            selected: true,
          ),
          SizedBox(height: 6),
          _SidebarItem(
            title: 'Apariencia',
            subtitle: 'Tema y visual',
            icon: Icons.palette_outlined,
          ),
          SizedBox(height: 6),
          _SidebarItem(
            title: 'Integraciones',
            subtitle: 'Conexiones externas',
            icon: Icons.hub_outlined,
          ),
        ],
      ),
    );
  }
}

class _SecuritySectionTabs extends StatelessWidget {
  const _SecuritySectionTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _CompactSectionChip(
            icon: Icons.shield_outlined,
            label: 'Seguridad',
            selected: true,
          ),
          _CompactSectionChip(
            icon: Icons.palette_outlined,
            label: 'Apariencia',
          ),
          _CompactSectionChip(
            icon: Icons.hub_outlined,
            label: 'Integraciones',
          ),
        ],
      ),
    );
  }
}

class _CompactSectionChip extends StatelessWidget {
  const _CompactSectionChip({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.surfaceContainer
            : AppTheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 15,
              color: selected ? AppTheme.primary : AppTheme.secondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: selected ? AppTheme.primary : AppTheme.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.selected = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: selected ? AppTheme.surfaceContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.secondaryContainer
                  : AppTheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: selected ? AppTheme.primary : AppTheme.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.secondary,
                    fontSize: 11,
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

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.action,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(48, 50, 33, 0.07),
            blurRadius: 20,
            spreadRadius: -10,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
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
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'active' => ('Activo', const Color(0xFF2E7D32)),
      'pending' => ('Pendiente', const Color(0xFFF9A825)),
      'blocked' => ('Bloqueado', const Color(0xFFC62828)),
      _ => (status, AppTheme.secondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _AuditActionChip extends StatelessWidget {
  const _AuditActionChip({required this.action});

  final String action;

  static const Set<String> criticalActions = {
    'cancelar_venta',
    'inventory_adjusted',
    'cash_register_closed',
    'permissions_changed',
    'role_changed',
    'user_blocked',
  };

  @override
  Widget build(BuildContext context) {
    final isCritical = criticalActions.contains(action);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCritical
            ? const Color(0xFF7B1F1F).withValues(alpha: 0.12)
            : AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        action,
        style: TextStyle(
          color: isCritical ? const Color(0xFF7B1F1F) : AppTheme.primary,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _AuditResultChip extends StatelessWidget {
  const _AuditResultChip({required this.result});

  final String result;

  @override
  Widget build(BuildContext context) {
    final success = result.toLowerCase() == 'success';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: success
            ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
            : const Color(0xFFC62828).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        success ? 'Exito' : 'Fallo',
        style: TextStyle(
          color: success ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _PillInfo extends StatelessWidget {
  const _PillInfo({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ConfigItem extends StatelessWidget {
  const _ConfigItem({
    required this.title,
    required this.description,
    required this.trailing,
  });

  final String title;
  final String description;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _AuditFilter extends StatelessWidget {
  const _AuditFilter({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: options.contains(value) ? value : options.first,
        underline: const SizedBox.shrink(),
        borderRadius: BorderRadius.circular(12),
        style: const TextStyle(
          color: AppTheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        iconEnabledColor: AppTheme.secondary,
        items: options
            .map(
              (option) => DropdownMenuItem<String>(
                value: option,
                child: Text('$label: $option'),
              ),
            )
            .toList(),
        onChanged: (selected) {
          if (selected == null) return;
          onChanged(selected);
        },
      ),
    );
  }
}

class _EmptyCardText extends StatelessWidget {
  const _EmptyCardText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: AppTheme.secondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _UserFilterOption {
  const _UserFilterOption({required this.label, required this.userId});

  final String label;
  final int? userId;
}
