import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  final String id;
  final String fullName;
  final String email;
  final String role;
}

class AuthSessionState {
  const AuthSessionState({
    required this.currentUser,
    required this.failedAttempts,
    required this.lockedUntilUtc,
    required this.lastError,
  });

  const AuthSessionState.initial()
      : currentUser = null,
        failedAttempts = 0,
        lockedUntilUtc = null,
        lastError = null;

  final AuthUser? currentUser;
  final int failedAttempts;
  final DateTime? lockedUntilUtc;
  final String? lastError;

  bool get isAuthenticated => currentUser != null;

  bool get isLocked {
    if (lockedUntilUtc == null) return false;
    return DateTime.now().toUtc().isBefore(lockedUntilUtc!);
  }

  AuthSessionState copyWith({
    AuthUser? currentUser,
    bool clearCurrentUser = false,
    int? failedAttempts,
    DateTime? lockedUntilUtc,
    bool clearLock = false,
    String? lastError,
    bool clearError = false,
  }) {
    return AuthSessionState(
      currentUser: clearCurrentUser ? null : (currentUser ?? this.currentUser),
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntilUtc:
          clearLock ? null : (lockedUntilUtc ?? this.lockedUntilUtc),
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
  AuthSessionController() : super(const AuthSessionState.initial()) {
    _seedDefaultUser();
  }

  static const int _maxFailedAttempts = 5;
  static const Duration _lockDuration = Duration(minutes: 5);
  final Map<String, _StoredAccount> _accountsByEmail = {};

  void _seedDefaultUser() {
    const email = 'admin@andys.cafe';
    const password = 'Admin123!';
    _accountsByEmail[email] = _StoredAccount(
      id: 'user-admin-1',
      fullName: 'Administrador Andy',
      email: email,
      role: 'admin',
      salt: _generateSalt(),
      passwordHash: '',
    );

    final seeded = _accountsByEmail[email]!;
    _accountsByEmail[email] = seeded.copyWith(
      passwordHash: _hashPassword(password, seeded.salt),
    );
  }

  AuthResult register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required String role,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    final cleanName = fullName.trim();

    if (cleanName.isEmpty) {
      return const AuthResult(success: false, message: 'Nombre obligatorio.');
    }

    if (!_isValidEmail(normalizedEmail)) {
      return const AuthResult(success: false, message: 'Correo invalido.');
    }

    if (!_isStrongPassword(password)) {
      return const AuthResult(
        success: false,
        message: 'La clave debe tener 8+ chars, mayuscula, numero y simbolo.',
      );
    }

    if (password != confirmPassword) {
      return const AuthResult(
        success: false,
        message: 'Las contrasenas no coinciden.',
      );
    }

    if (_accountsByEmail.containsKey(normalizedEmail)) {
      return const AuthResult(
        success: false,
        message: 'Ya existe una cuenta con ese correo.',
      );
    }

    final salt = _generateSalt();
    final created = _StoredAccount(
      id: 'user-${DateTime.now().microsecondsSinceEpoch}',
      fullName: cleanName,
      email: normalizedEmail,
      role: role,
      salt: salt,
      passwordHash: _hashPassword(password, salt),
    );
    _accountsByEmail[normalizedEmail] = created;

    state = state.copyWith(clearError: true);
    return const AuthResult(success: true);
  }

  AuthResult login({required String emailOrUser, required String password}) {
    final nowUtc = DateTime.now().toUtc();

    if (state.lockedUntilUtc != null &&
        nowUtc.isBefore(state.lockedUntilUtc!)) {
      final seconds = state.lockedUntilUtc!.difference(nowUtc).inSeconds;
      return AuthResult(
        success: false,
        message: 'Cuenta temporalmente bloqueada ($seconds s).',
      );
    }

    final normalized = emailOrUser.trim().toLowerCase();
    final account = _accountsByEmail[normalized];
    final valid = account != null &&
        _hashPassword(password, account.salt) == account.passwordHash;

    if (!valid) {
      final failed = state.failedAttempts + 1;
      if (failed >= _maxFailedAttempts) {
        final until = nowUtc.add(_lockDuration);
        state = state.copyWith(
          failedAttempts: 0,
          lockedUntilUtc: until,
          lastError: 'Intentos maximos alcanzados. Intenta mas tarde.',
          clearCurrentUser: true,
        );
      } else {
        state = state.copyWith(
          failedAttempts: failed,
          clearLock: true,
          lastError: 'Credenciales invalidas.',
          clearCurrentUser: true,
        );
      }
      return AuthResult(success: false, message: state.lastError);
    }

    state = state.copyWith(
      currentUser: AuthUser(
        id: account.id,
        fullName: account.fullName,
        email: account.email,
        role: account.role,
      ),
      failedAttempts: 0,
      clearLock: true,
      clearError: true,
    );
    return const AuthResult(success: true);
  }

  void logout() {
    state = state.copyWith(
      clearCurrentUser: true,
      failedAttempts: 0,
      clearError: true,
      clearLock: true,
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

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPassword(String password, String salt) {
    return sha256.convert(utf8.encode('$salt:$password')).toString();
  }
}

class _StoredAccount {
  const _StoredAccount({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.salt,
    required this.passwordHash,
  });

  final String id;
  final String fullName;
  final String email;
  final String role;
  final String salt;
  final String passwordHash;

  _StoredAccount copyWith({
    String? id,
    String? fullName,
    String? email,
    String? role,
    String? salt,
    String? passwordHash,
  }) {
    return _StoredAccount(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      salt: salt ?? this.salt,
      passwordHash: passwordHash ?? this.passwordHash,
    );
  }
}

final authSessionProvider =
    StateNotifierProvider<AuthSessionController, AuthSessionState>(
  (ref) => AuthSessionController(),
);
