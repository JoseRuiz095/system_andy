import 'package:flutter/material.dart';
import 'package:system_andy/features/ventas/presentation/pages/ventas_page.dart';
import 'package:system_andy/features/auth/presentation/login/login_page.dart';
// Importa otras páginas aquí

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String ventas = '/ventas';
  // Agrega más rutas aquí

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Página de inicio'))));
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case ventas:
        return MaterialPageRoute(builder: (_) => const VentasPage());
      // case ...
      default:
        return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Center(child: Text('Ruta no encontrada'))));
    }
  }
}
