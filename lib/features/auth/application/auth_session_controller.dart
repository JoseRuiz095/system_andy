import 'dart:async';

import 'package:bcrypt/bcrypt.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_andy/config/dependencies.dart';
import 'package:system_andy/core/database/app_database.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.role,
    required this.permissions,
  });

  final int id;
  final String fullName;
  final String username;
  final String? email;
  final String role;
  final Set<String> permissions;
}

class AuthSessionState {
  const AuthSessionState({
    required this.currentUser,
    required this.isLoading,
    required this.failedAttempts,
    required this.lockedUntilUtc,
    required this.sessionExpiresAtUtc,
    required this.activeSessionId,
    required this.lastError,
  });

  const AuthSessionState.initial()
      : currentUser = null,
        isLoading = false,
        failedAttempts = 0,
        lockedUntilUtc = null,
        sessionExpiresAtUtc = null,
        activeSessionId = null,
        lastError = null;

  final AuthUser? currentUser;
  final bool isLoading;
  final int failedAttempts;
  final DateTime? lockedUntilUtc;
  final DateTime? sessionExpiresAtUtc;
  final int? activeSessionId;
  final String? lastError;

  bool get isSessionExpired {
    if (sessionExpiresAtUtc == null) return false;
    return DateTime.now().toUtc().isAfter(sessionExpiresAtUtc!);
  }

  bool get isAuthenticated => currentUser != null && !isSessionExpired;

  bool get isLocked {
    if (lockedUntilUtc == null) return false;
    return DateTime.now().toUtc().isBefore(lockedUntilUtc!);
  }

  AuthSessionState copyWith({
    AuthUser? currentUser,
    bool clearCurrentUser = false,
    bool? isLoading,
    int? failedAttempts,
    DateTime? lockedUntilUtc,
    bool clearLock = false,
    DateTime? sessionExpiresAtUtc,
    bool clearSessionExpiry = false,
    int? activeSessionId,
    bool clearActiveSession = false,
    String? lastError,
    bool clearError = false,
  }) {
    return AuthSessionState(
      currentUser: clearCurrentUser ? null : (currentUser ?? this.currentUser),
      isLoading: isLoading ?? this.isLoading,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntilUtc:
          clearLock ? null : (lockedUntilUtc ?? this.lockedUntilUtc),
      sessionExpiresAtUtc: clearSessionExpiry
          ? null
          : (sessionExpiresAtUtc ?? this.sessionExpiresAtUtc),
      activeSessionId: clearActiveSession
          ? null
          : (activeSessionId ?? this.activeSessionId),
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

class AuthResult {
  const AuthResult({required this.success, this.message});

  final bool success;
  final String? message;
}

class AuthSessionController extends StateNotifier<AuthSessionState> {
  AuthSessionController(this._dao) : super(const AuthSessionState.initial());

  final PosDao _dao;

  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required String role,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final cleanName = fullName.trim();

    state = state.copyWith(isLoading: true, clearError: true);

    if (cleanName.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        lastError: 'Nombre obligatorio.',
      );
      return const AuthResult(success: false, message: 'Nombre obligatorio.');
    }

    if (!_isValidEmail(normalizedEmail)) {
      state = state.copyWith(isLoading: false, lastError: 'Correo invalido.');
      return const AuthResult(success: false, message: 'Correo invalido.');
    }

    final strongPasswordRequired =
        await _readBoolSecuritySetting('strong_password_required', true);
    if (strongPasswordRequired && !_isStrongPassword(password)) {
      state = state.copyWith(
        isLoading: false,
        lastError:
            'La clave debe tener 8+ chars, mayuscula, numero y simbolo.',
      );
      return const AuthResult(
        success: false,
        message: 'La clave debe tener 8+ chars, mayuscula, numero y simbolo.',
      );
    }

    if (password != confirmPassword) {
      state = state.copyWith(
        isLoading: false,
        lastError: 'Las contrasenas no coinciden.',
      );
      return const AuthResult(
        success: false,
        message: 'Las contrasenas no coinciden.',
      );
    }

    final existing = await _dao.findUserByIdentifier(normalizedEmail);
    if (existing != null) {
      state = state.copyWith(
        isLoading: false,
        lastError: 'Ya existe una cuenta con ese correo.',
      );
      return const AuthResult(
        success: false,
        message: 'Ya existe una cuenta con ese correo.',
      );
    }

    final roleCode = _normalizeRole(role);
    final bcryptHash = BCrypt.hashpw(password, BCrypt.gensalt(logRounds: 12));
    await _dao.createPendingUserAccount(
      username: normalizedEmail,
      email: normalizedEmail,
      fullName: cleanName,
      passwordHash: bcryptHash,
      roleCode: roleCode,
    );

    state = state.copyWith(isLoading: false, clearError: true);
    return const AuthResult(
      success: true,
      message:
          'Registro exitoso. Tu cuenta quedo pendiente de validacion por un administrador.',
    );
  }

  Future<AuthResult> login({
    required String emailOrUser,
    required String password,
    String? ipAddress,
    String? deviceInfo,
  }) async {
    final nowUtc = DateTime.now().toUtc();
    state = state.copyWith(isLoading: true, clearError: true);

    if (state.lockedUntilUtc != null &&
        nowUtc.isBefore(state.lockedUntilUtc!)) {
      final seconds = state.lockedUntilUtc!.difference(nowUtc).inSeconds;
      state = state.copyWith(isLoading: false);
      return AuthResult(
        success: false,
        message: 'Cuenta temporalmente bloqueada ($seconds s).',
      );
    }

    final maxFailedAttempts =
        await _readIntSecuritySetting('max_failed_attempts', 5);
    final lockoutMinutes = await _readIntSecuritySetting('lockout_minutes', 15);
    final sessionExpirationMinutes =
        await _readIntSecuritySetting('session_expiration_minutes', 480);

    final normalized = emailOrUser.trim().toLowerCase();
    final user = await _dao.findUserByIdentifier(normalized);

    if (user == null || user.passwordHash == null || user.passwordHash!.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        failedAttempts: 0,
        lastError: 'Credenciales invalidas.',
      );
      return const AuthResult(success: false, message: 'Credenciales invalidas.');
    }

    if (user.status == 'pending') {
      state = state.copyWith(
        isLoading: false,
        failedAttempts: user.failedAttempts,
        lastError: 'Tu cuenta aun no ha sido validada por un administrador.',
      );
      return const AuthResult(
        success: false,
        message: 'Tu cuenta aun no ha sido validada por un administrador.',
      );
    }

    if (user.status == 'blocked' && user.blockedAt != null) {
      final unlockAt = user.blockedAt!.add(Duration(minutes: lockoutMinutes));
      if (nowUtc.isBefore(unlockAt)) {
        state = state.copyWith(
          isLoading: false,
          lockedUntilUtc: unlockAt,
          failedAttempts: user.failedAttempts,
          lastError: 'Cuenta bloqueada temporalmente.',
        );
        return AuthResult(
          success: false,
          message:
              'Cuenta temporalmente bloqueada (${unlockAt.difference(nowUtc).inSeconds}s).',
        );
      }

      await _dao.updateUserStatus(
        targetUserId: user.id,
        status: 'active',
        changedByUserId: user.id,
        ipAddress: ipAddress,
        deviceInfo: deviceInfo,
      );
    }

    final valid = BCrypt.checkpw(password, user.passwordHash!);

    if (!valid) {
      await _dao.registerFailedLoginAttempt(
        userId: user.id,
        maxFailedAttempts: maxFailedAttempts,
        lockoutMinutes: lockoutMinutes,
        ipAddress: ipAddress,
        deviceInfo: deviceInfo,
      );
      final refreshed = await _dao.findUserByIdentifier(normalized);
      final failed = refreshed?.failedAttempts ?? state.failedAttempts + 1;
      final isNowLocked = (refreshed?.status ?? '') == 'blocked';
      final until = isNowLocked && refreshed?.blockedAt != null
          ? refreshed!.blockedAt!.add(Duration(minutes: lockoutMinutes))
          : null;

      state = state.copyWith(
        isLoading: false,
        failedAttempts: failed,
        lockedUntilUtc: until,
        lastError: isNowLocked
            ? 'Intentos maximos alcanzados. Intenta mas tarde.'
            : 'Credenciales invalidas.',
        clearCurrentUser: true,
        clearSessionExpiry: true,
        clearActiveSession: true,
      );
      return AuthResult(success: false, message: state.lastError);
    }

    await _dao.registerSuccessfulLogin(
      userId: user.id,
      ipAddress: ipAddress,
      deviceInfo: deviceInfo,
    );
    await _dao.closeAllActiveSessionsForUser(user.id);
    final sessionId = await _dao.startUserSession(userId: user.id);
    final roleCode = await _dao.getPrimaryRoleCodeForUser(user.id) ?? 'cashier';
    final permissions = await _dao.getPermissionCodesForUser(user.id);

    state = state.copyWith(
      currentUser: AuthUser(
        id: user.id,
        fullName: user.fullName,
        username: user.username,
        email: user.email,
        role: roleCode,
        permissions: permissions,
      ),
      isLoading: false,
      failedAttempts: 0,
      clearLock: true,
      sessionExpiresAtUtc:
          nowUtc.add(Duration(minutes: sessionExpirationMinutes)),
      activeSessionId: sessionId,
      clearError: true,
    );
    return const AuthResult(success: true);
  }

  void logout() {
    final sessionId = state.activeSessionId;
    if (sessionId != null) {
      unawaited(_dao.closeUserSession(sessionId));
    }

    state = state.copyWith(
      clearCurrentUser: true,
      isLoading: false,
      failedAttempts: 0,
      clearError: true,
      clearLock: true,
      clearSessionExpiry: true,
      clearActiveSession: true,
    );
  }

  bool hasPermission(String permissionCode) {
    final user = state.currentUser;
    if (user == null) return false;
    return user.permissions.contains(permissionCode) || user.role == 'admin';
  }

  Future<void> refreshCurrentUserPermissions() async {
    final user = state.currentUser;
    if (user == null) return;

    final roleCode = await _dao.getPrimaryRoleCodeForUser(user.id) ?? user.role;
    final permissions = await _dao.getPermissionCodesForUser(user.id);
    state = state.copyWith(
      currentUser: AuthUser(
        id: user.id,
        fullName: user.fullName,
        username: user.username,
        email: user.email,
        role: roleCode,
        permissions: permissions,
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  bool _isStrongPassword(String password) {
    if (password.length < 8) return false;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecial =
        RegExp(r'[!@#\$%^&*()_+\-={}:;"\\|,.<>/?]').hasMatch(password);
    return hasUpper && hasNumber && hasSpecial;
  }

  Future<int> _readIntSecuritySetting(String key, int fallback) async {
    final value = await _dao.getSecuritySettingValue(key);
    if (value == null) return fallback;
    return int.tryParse(value.trim()) ?? fallback;
  }

  Future<bool> _readBoolSecuritySetting(String key, bool fallback) async {
    final value = await _dao.getSecuritySettingValue(key);
    if (value == null) return fallback;
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
    return fallback;
  }

  String _normalizeRole(String role) {
    final normalized = role.trim().toLowerCase();
    switch (normalized) {
      case 'admin':
      case 'administrador':
        return 'admin';
      case 'barista':
        return 'barista';
      default:
        return 'cashier';
    }
  }
}

final authSessionProvider =
    StateNotifierProvider<AuthSessionController, AuthSessionState>(
  (ref) => AuthSessionController(ref.watch(posDaoProvider)),
);
