import 'package:bcrypt/bcrypt.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_andy/config/dependencies.dart';
import 'package:system_andy/core/database/app_database.dart';
import 'package:system_andy/features/auth/application/auth_session_controller.dart';

class SecurityManagementState {
  const SecurityManagementState({
    required this.isLoading,
    required this.isSaving,
    required this.users,
    required this.roles,
    required this.permissionsCatalog,
    required this.selectedRoleCode,
    required this.rolePermissions,
    required this.auditLogs,
    required this.auditTotal,
    required this.auditPage,
    required this.auditPageSize,
    required this.auditSearch,
    required this.auditModule,
    required this.auditAction,
    required this.auditUserId,
    required this.settings,
    required this.lastError,
    required this.message,
  });

  const SecurityManagementState.initial()
      : isLoading = true,
        isSaving = false,
        users = const [],
        roles = const [],
        permissionsCatalog = const [],
        selectedRoleCode = null,
        rolePermissions = const {},
        auditLogs = const [],
        auditTotal = 0,
        auditPage = 0,
        auditPageSize = 10,
        auditSearch = '',
        auditModule = null,
        auditAction = null,
        auditUserId = null,
        settings = const {},
        lastError = null,
        message = null;

  final bool isLoading;
  final bool isSaving;
  final List<SecurityUserView> users;
  final List<RolePermissionView> roles;
  final List<Permission> permissionsCatalog;
  final String? selectedRoleCode;
  final Map<String, Set<String>> rolePermissions;
  final List<SecurityAuditLogView> auditLogs;
  final int auditTotal;
  final int auditPage;
  final int auditPageSize;
  final String auditSearch;
  final String? auditModule;
  final String? auditAction;
  final int? auditUserId;
  final Map<String, String> settings;
  final String? lastError;
  final String? message;

  SecurityManagementState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<SecurityUserView>? users,
    List<RolePermissionView>? roles,
    List<Permission>? permissionsCatalog,
    String? selectedRoleCode,
    bool clearSelectedRoleCode = false,
    Map<String, Set<String>>? rolePermissions,
    List<SecurityAuditLogView>? auditLogs,
    int? auditTotal,
    int? auditPage,
    int? auditPageSize,
    String? auditSearch,
    String? auditModule,
    bool clearAuditModule = false,
    String? auditAction,
    bool clearAuditAction = false,
    int? auditUserId,
    bool clearAuditUser = false,
    Map<String, String>? settings,
    String? lastError,
    bool clearError = false,
    String? message,
    bool clearMessage = false,
  }) {
    return SecurityManagementState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      users: users ?? this.users,
      roles: roles ?? this.roles,
      permissionsCatalog: permissionsCatalog ?? this.permissionsCatalog,
      selectedRoleCode: clearSelectedRoleCode
          ? null
          : (selectedRoleCode ?? this.selectedRoleCode),
      rolePermissions: rolePermissions ?? this.rolePermissions,
      auditLogs: auditLogs ?? this.auditLogs,
      auditTotal: auditTotal ?? this.auditTotal,
      auditPage: auditPage ?? this.auditPage,
      auditPageSize: auditPageSize ?? this.auditPageSize,
      auditSearch: auditSearch ?? this.auditSearch,
      auditModule: clearAuditModule ? null : (auditModule ?? this.auditModule),
      auditAction: clearAuditAction ? null : (auditAction ?? this.auditAction),
      auditUserId: clearAuditUser ? null : (auditUserId ?? this.auditUserId),
      settings: settings ?? this.settings,
      lastError: clearError ? null : (lastError ?? this.lastError),
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

class SecurityManagementController
    extends StateNotifier<SecurityManagementState> {
  SecurityManagementController(this._ref, this._dao)
      : super(const SecurityManagementState.initial()) {
    loadInitial();
  }

  final Ref _ref;
  final PosDao _dao;

  int? get _currentUserId => _ref.read(authSessionProvider).currentUser?.id;

  bool get _canConfigure => _ref
      .read(authSessionProvider.notifier)
      .hasPermission('configurar_sistema');

  Future<void> loadInitial() async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearMessage: true);
    try {
      await Future.wait([
        _loadUsers(),
        _loadRolesAndPermissions(),
        _loadAudit(),
        _loadSettings(),
      ]);
      state = state.copyWith(isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        lastError: 'No se pudo cargar el modulo de seguridad: $error',
      );
    }
  }

  Future<void> _loadUsers() async {
    final users = await _dao.listSecurityUsers();
    state = state.copyWith(users: users);
  }

  Future<void> _loadRolesAndPermissions() async {
    final roles = await _dao.listRolesWithPermissions();
    final catalog = await _dao.listAllPermissions();
    final rolePermissions = <String, Set<String>>{
      for (final role in roles) role.roleCode: {...role.permissions},
    };

    state = state.copyWith(
      roles: roles,
      permissionsCatalog: catalog,
      rolePermissions: rolePermissions,
      selectedRoleCode: state.selectedRoleCode ??
          (roles.isNotEmpty ? roles.first.roleCode : null),
    );
  }

  Future<void> _loadAudit() async {
    final filter = SecurityAuditFilter(
      limit: state.auditPageSize,
      offset: state.auditPage * state.auditPageSize,
      module: state.auditModule,
      eventAction: state.auditAction,
      userId: state.auditUserId,
      search: state.auditSearch,
    );

    final rows = await _dao.querySecurityAuditLogs(filter);
    final total = await _dao.countSecurityAuditLogs(filter);
    state = state.copyWith(auditLogs: rows, auditTotal: total);
  }

  Future<void> _loadSettings() async {
    final settings = await _dao.listSecuritySettings();
    state = state.copyWith(
      settings: {
        for (final setting in settings) setting.key: setting.value,
      },
    );
  }

  void selectRole(String roleCode) {
    state = state.copyWith(
        selectedRoleCode: roleCode, clearMessage: true, clearError: true);
  }

  void togglePermission(String roleCode, String permissionCode, bool enabled) {
    final next = <String, Set<String>>{
      for (final entry in state.rolePermissions.entries)
        entry.key: {...entry.value},
    };

    final current = next.putIfAbsent(roleCode, () => <String>{});
    if (enabled) {
      current.add(permissionCode);
    } else {
      current.remove(permissionCode);
    }

    state = state.copyWith(
        rolePermissions: next, clearMessage: true, clearError: true);
  }

  Future<void> saveSelectedRolePermissions() async {
    if (!_canConfigure) {
      await _registerUnauthorized('Guardar permisos', 'Seguridad');
      return;
    }

    final roleCode = state.selectedRoleCode;
    if (roleCode == null) return;
    final matchingRoles = state.roles.where((r) => r.roleCode == roleCode);
    final role = matchingRoles.isEmpty ? null : matchingRoles.first;
    if (role == null) return;

    state =
        state.copyWith(isSaving: true, clearError: true, clearMessage: true);
    try {
      await _dao.replaceRolePermissions(
        roleId: role.roleId,
        permissionCodes: state.rolePermissions[roleCode] ?? <String>{},
        changedByUserId: _currentUserId ?? role.roleId,
      );
      await _loadRolesAndPermissions();
      await _ref
          .read(authSessionProvider.notifier)
          .refreshCurrentUserPermissions();
      state = state.copyWith(
          isSaving: false, message: 'Permisos guardados correctamente.');
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        lastError: 'No se pudieron guardar permisos: $error',
      );
    }
  }

  Future<void> validateUser(int userId) async {
    await _withGuardedAction(
      actionName: 'Validar usuario',
      module: 'Seguridad',
      operation: () async {
        await _dao.validatePendingUser(
          targetUserId: userId,
          adminUserId: _currentUserId ?? userId,
        );
        await _loadUsers();
        await _loadAudit();
      },
      successMessage: 'Usuario validado correctamente.',
    );
  }

  Future<void> toggleBlockUser(SecurityUserView user) async {
    await _withGuardedAction(
      actionName:
          user.status == 'blocked' ? 'Desbloquear usuario' : 'Bloquear usuario',
      module: 'Seguridad',
      operation: () async {
        final nextStatus = user.status == 'blocked' ? 'active' : 'blocked';
        await _dao.updateUserStatus(
          targetUserId: user.id,
          status: nextStatus,
          changedByUserId: _currentUserId ?? user.id,
        );
        await _loadUsers();
        await _loadAudit();
      },
      successMessage: user.status == 'blocked'
          ? 'Usuario desbloqueado correctamente.'
          : 'Usuario bloqueado correctamente.',
    );
  }

  Future<void> resetPassword(int userId, String tempPassword) async {
    await _withGuardedAction(
      actionName: 'Restablecer contrasena',
      module: 'Seguridad',
      operation: () async {
        final hash = BCrypt.hashpw(tempPassword, BCrypt.gensalt(logRounds: 12));
        await _dao.resetUserPassword(
          targetUserId: userId,
          passwordHash: hash,
          passwordAlgo: 'bcrypt',
          changedByUserId: _currentUserId ?? userId,
        );
        await _loadUsers();
        await _loadAudit();
      },
      successMessage: 'Contrasena restablecida. Temporal: $tempPassword',
    );
  }

  Future<void> changeUserRole(int userId, String roleCode) async {
    final matchingRoles = state.roles.where((r) => r.roleCode == roleCode);
    final role = matchingRoles.isEmpty ? null : matchingRoles.first;
    if (role == null) return;

    await _withGuardedAction(
      actionName: 'Cambiar rol de usuario',
      module: 'Seguridad',
      operation: () async {
        await _dao.changeUserRole(
          targetUserId: userId,
          newRoleId: role.roleId,
          changedByUserId: _currentUserId ?? userId,
        );
        await _loadUsers();
        await _loadAudit();
      },
      successMessage: 'Rol actualizado a ${role.roleName}.',
    );
  }

  Future<void> updateAuditFilters({
    String? search,
    String? module,
    bool clearModule = false,
    String? action,
    bool clearAction = false,
    int? userId,
    bool clearUser = false,
  }) async {
    state = state.copyWith(
      auditSearch: search ?? state.auditSearch,
      auditModule: clearModule ? null : (module ?? state.auditModule),
      auditAction: clearAction ? null : (action ?? state.auditAction),
      auditUserId: clearUser ? null : (userId ?? state.auditUserId),
      auditPage: 0,
      clearError: true,
      clearMessage: true,
    );
    await _loadAudit();
  }

  Future<void> setAuditPage(int page) async {
    state = state.copyWith(auditPage: page, clearError: true);
    await _loadAudit();
  }

  Future<void> saveSetting(String key, String value) async {
    await _withGuardedAction(
      actionName: 'Actualizar ajuste de seguridad',
      module: 'Seguridad',
      operation: () async {
        await _dao.upsertSecuritySetting(
          key: key,
          value: value,
          updatedByUserId: _currentUserId,
        );
        await _loadSettings();
      },
      successMessage: 'Configuracion actualizada.',
    );
  }

  Future<void> _withGuardedAction({
    required String actionName,
    required String module,
    required Future<void> Function() operation,
    required String successMessage,
  }) async {
    if (!_canConfigure) {
      await _registerUnauthorized(actionName, module);
      return;
    }

    state =
        state.copyWith(isSaving: true, clearError: true, clearMessage: true);
    try {
      await operation();
      state = state.copyWith(isSaving: false, message: successMessage);
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        lastError: 'Operacion no completada: $error',
      );
    }
  }

  Future<void> _registerUnauthorized(String actionName, String module) async {
    final userId = _currentUserId;
    if (userId != null) {
      await _dao.registerUnauthorizedAttempt(
        userId: userId,
        attemptedAction: actionName,
        module: module,
      );
      await _loadAudit();
    }

    state = state.copyWith(
      lastError:
          'No tienes permisos suficientes para realizar esta accion. Solicita acceso a un administrador.',
      message: null,
      isSaving: false,
    );
  }
}

final securityManagementProvider = StateNotifierProvider<
    SecurityManagementController, SecurityManagementState>(
  (ref) => SecurityManagementController(ref, ref.watch(posDaoProvider)),
);
