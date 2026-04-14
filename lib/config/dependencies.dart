import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_andy/core/database/app_database.dart';
import 'package:system_andy/features/ventas/data/repositories/ventas_repository_impl.dart';
import 'package:system_andy/features/ventas/domain/repositories/ventas_repository.dart';
import 'package:system_andy/features/ventas/data/datasources/ventas_remote_datasource.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final posDaoProvider = Provider<PosDao>(
  (ref) => PosDao(ref.watch(appDatabaseProvider)),
);

final ventasRemoteDatasourceProvider = Provider<VentasRemoteDatasource>(
  (ref) => VentasRemoteDatasourceImpl(),
);

final ventasRepositoryProvider = Provider<VentasRepository>(
  (ref) => VentasRepositoryImpl(
    remoteDatasource: ref.watch(ventasRemoteDatasourceProvider),
  ),
);
// Agrega más providers aquí
