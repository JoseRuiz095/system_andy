import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_andy/config/routes.dart';
import 'package:system_andy/features/auth/application/auth_session_controller.dart';
import 'package:system_andy/features/auth/presentation/login/login_page.dart';

class VentasPage extends ConsumerWidget {
  const VentasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authSessionProvider);
    if (!authState.isAuthenticated) {
      return const LoginPage();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(authSessionProvider.notifier).logout();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesion',
          ),
        ],
      ),
      body: const Center(child: Text('Página de Ventas')),
    );
  }
}
