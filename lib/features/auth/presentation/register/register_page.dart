import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_andy/config/routes.dart';
import 'package:system_andy/core/theme/app_theme.dart';
import 'package:system_andy/features/auth/application/auth_session_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

enum StaffRole { cashier, barista }

extension StaffRoleX on StaffRole {
  String get label {
    switch (this) {
      case StaffRole.cashier:
        return 'Cajero';
      case StaffRole.barista:
        return 'Barista';
    }
  }

  IconData get icon {
    switch (this) {
      case StaffRole.cashier:
        return Icons.point_of_sale_outlined;
      case StaffRole.barista:
        return Icons.local_cafe_outlined;
    }
  }
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  StaffRole _selectedRole = StaffRole.cashier;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool get _hasMinLength => _passwordController.text.trim().length >= 8;
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_passwordController.text);
  bool get _hasSpecial => RegExp(r'[!@#\$%^&*()_+\-={}:;\"\\|,.<>/?]').hasMatch(
        _passwordController.text,
      );
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_passwordController.text);

  int get _securityScore {
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUppercase) score++;
    if (_hasSpecial) score++;
    if (_hasNumber) score++;
    return score;
  }

  String get _securityLabel {
    if (_securityScore >= 4) return 'Excelente';
    if (_securityScore >= 3) return 'Buena';
    if (_securityScore >= 2) return 'Media';
    return 'Baja';
  }

  Color get _securityColor {
    if (_securityScore >= 4) return Colors.green.shade700;
    if (_securityScore >= 3) return AppTheme.primary;
    if (_securityScore >= 2) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() {
    final result = ref.read(authSessionProvider.notifier).register(
          fullName: _fullNameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
          role: _selectedRole.name,
        );

    if (!mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(result.message ?? 'No fue posible registrar la cuenta.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final loginResult = ref.read(authSessionProvider.notifier).login(
          emailOrUser: _emailController.text,
          password: _passwordController.text,
        );

    if (!loginResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loginResult.message ?? 'Cuenta creada, inicia sesion.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.login, (r) => false);
      return;
    }

    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.ventas, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 600;
    final isLarge = screenWidth >= 1200;

    final horizontalPadding = isCompact
        ? 16.0
        : isLarge
            ? 40.0
            : 24.0;
    final verticalPadding = isCompact ? 16.0 : 24.0;
    final maxContentWidth = screenWidth >= 1800
        ? 1280.0
        : screenWidth >= 1400
            ? 1120.0
            : 920.0;
    final logoSize = isCompact ? 96.0 : 120.0;
    final cardPadding = isCompact
        ? const EdgeInsets.all(18)
        : isLarge
            ? const EdgeInsets.all(36)
            : const EdgeInsets.all(32);

    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLow,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: SizedBox(
              width: 400,
              height: 400,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.secondaryContainer.withValues(alpha: 0.2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondaryContainer.withValues(alpha: 0.2),
                      blurRadius: 100,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -200,
            right: -200,
            child: SizedBox(
              width: 500,
              height: 500,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryFixed.withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryFixed.withValues(alpha: 0.1),
                      blurRadius: 100,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, viewport) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: logoSize,
                            height: logoSize,
                            child: SvgPicture.asset(
                              'lib/core/theme/images/AndysVector.svg',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Moka Manager',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Tu rinconcito de control y cafe.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.secondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: cardPadding,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(48, 50, 33, 0.06),
                                  blurRadius: 64,
                                  spreadRadius: -12,
                                  offset: Offset(0, 32),
                                ),
                              ],
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final useTwoColumns =
                                    constraints.maxWidth >= 860;

                                final leftColumn = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Crear cuenta',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.primary,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Configura tu perfil para acceder al sistema POS.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.secondary,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    _buildTextField(
                                      label: 'Nombre completo',
                                      hint: 'Juan Pérez',
                                      controller: _fullNameController,
                                      prefixIcon: Icons.person_outline,
                                    ),
                                    const SizedBox(height: 14),
                                    _buildTextField(
                                      label: 'Correo laboral',
                                      hint: 'nombre@andys.cafe.com',
                                      controller: _emailController,
                                      prefixIcon: Icons.mail_outline,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 14),
                                    _buildTextField(
                                      label: 'Contraseña',
                                      hint: '••••••••',
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      onChanged: (_) => setState(() {}),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: AppTheme.outline,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    _buildTextField(
                                      label: 'Confirmar contraseña',
                                      hint: '••••••••',
                                      controller: _confirmPasswordController,
                                      obscureText: _obscureConfirmPassword,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: AppTheme.outline,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscureConfirmPassword =
                                                !_obscureConfirmPassword;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                );

                                final rightColumn = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Rol',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.tertiary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: StaffRole.values
                                          .map(
                                            (role) => Expanded(
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                  right: role ==
                                                          StaffRole.values.last
                                                      ? 0
                                                      : 8,
                                                ),
                                                child: _RoleCard(
                                                  role: role,
                                                  selected:
                                                      role == _selectedRole,
                                                  onTap: () {
                                                    setState(
                                                      () =>
                                                          _selectedRole = role,
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                    const SizedBox(height: 14),
                                    _buildSecurityCard(),
                                    const SizedBox(height: 18),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: _register,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primary,
                                          foregroundColor: AppTheme.onPrimary,
                                          elevation: 4,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Crear cuenta',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Center(
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pushNamedAndRemoveUntil(
                                            AppRoutes.login,
                                            (route) => false,
                                          );
                                        },
                                        child: const Text('Ya tengo cuenta'),
                                      ),
                                    ),
                                  ],
                                );
                                if (!useTwoColumns) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      leftColumn,
                                      const SizedBox(height: 18),
                                      rightColumn,
                                    ],
                                  );
                                }

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 11, child: leftColumn),
                                    const SizedBox(width: 28),
                                    Expanded(flex: 9, child: rightColumn),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                size: 12,
                                color:
                                    AppTheme.secondary.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'REGISTRO SEGURO',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color:
                                      AppTheme.secondary.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: viewport.maxHeight < 760 ? 8 : 0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.tertiary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppTheme.hintTextColor,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: AppTheme.surfaceContainerHighest,
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, color: AppTheme.secondary),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityCard() {
    final validations = <({String label, bool valid})>[
      (label: '8+ caracteres', valid: _hasMinLength),
      (label: 'Una mayúscula', valid: _hasUppercase),
      (label: 'Símbolo especial', valid: _hasSpecial),
      (label: 'Un número', valid: _hasNumber),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'NIVEL DE SEGURIDAD',
                style: TextStyle(
                  color: AppTheme.secondary,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _securityColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _securityLabel,
                  style: TextStyle(
                    color: _securityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(4, (index) {
              final active = index < _securityScore;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
                  height: 5,
                  decoration: BoxDecoration(
                    color: active
                        ? _securityColor
                        : AppTheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: validations
                .map(
                  (item) => _ValidationItem(
                    label: item.label,
                    valid: item.valid,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final StaffRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryFixed.withValues(alpha: 0.2)
              : AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.transparent,
            width: 1.8,
          ),
        ),
        child: Column(
          children: [
            Icon(role.icon, color: AppTheme.primary, size: 20),
            const SizedBox(height: 4),
            Text(
              role.label,
              style: const TextStyle(
                color: AppTheme.tertiary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValidationItem extends StatelessWidget {
  const _ValidationItem({required this.label, required this.valid});

  final String label;
  final bool valid;

  @override
  Widget build(BuildContext context) {
    final color = valid ? AppTheme.primary : AppTheme.secondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          valid ? Icons.check_circle : Icons.circle_outlined,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
