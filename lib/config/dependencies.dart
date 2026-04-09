import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_andy/features/ventas/data/repositories/ventas_repository_impl.dart';
import 'package:system_andy/features/ventas/domain/repositories/ventas_repository.dart';
import 'package:system_andy/features/ventas/data/datasources/ventas_remote_datasource.dart';

final ventasRemoteDatasourceProvider = Provider<VentasRemoteDatasource>(
  (ref) => VentasRemoteDatasourceImpl(),
);

final ventasRepositoryProvider = Provider<VentasRepository>(
  (ref) => VentasRepositoryImpl(
    remoteDatasource: ref.watch(ventasRemoteDatasourceProvider),
  ),
);
// Agrega más providers aquí
