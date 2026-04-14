import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_andy/features/layout/main/main_panel_section.dart';
import 'package:system_andy/features/layout/main/mainpanel.dart';
import 'package:system_andy/features/auth/presentation/login/login_page.dart';
import 'package:system_andy/features/auth/presentation/register/register_page.dart';
import 'package:system_andy/features/auth/application/auth_session_controller.dart';
// Importa otras páginas aquí

class AppRoutes {
  static const String home = '/';
  static const String mainPanel = '/main';
  static const String login = '/login';
  static const String register = '/register';
  static const String ventas = '/ventas';
  // Agrega más rutas aquí

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final routeName = settings.name ?? home;
    Widget targetPage;

    switch (settings.name) {
      case home:
        targetPage = const MainPanel();
        break;
      case mainPanel:
        targetPage = const MainPanel();
        break;
      case login:
        targetPage = const LoginPage();
        break;
      case register:
        targetPage = const RegisterPage();
        break;
      case ventas:
        targetPage = const MainPanel(initialSection: MainPanelSection.ventas);
        break;
      // case ...
      default:
        targetPage =
            const Scaffold(body: Center(child: Text('Ruta no encontrada')));
        break;
    }

    return MaterialPageRoute(
      settings: settings,
      builder: (_) => _RouteGate(routeName: routeName, child: targetPage),
    );
  }
}

class _RouteGate extends ConsumerWidget {
  const _RouteGate({required this.routeName, required this.child});

  final String routeName;
  final Widget child;

  static const Set<String> _publicRoutes = {
    AppRoutes.login,
    AppRoutes.register,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authSessionProvider);
    final isPublicRoute = _publicRoutes.contains(routeName);

    if (!authState.isAuthenticated && !isPublicRoute) {
      return const LoginPage();
    }

    if (authState.isAuthenticated && isPublicRoute) {
      return const MainPanel();
    }

    return child;
  }
}
