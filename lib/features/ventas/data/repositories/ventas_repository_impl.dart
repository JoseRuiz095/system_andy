import '../../domain/entities/venta.dart';
import '../../domain/repositories/ventas_repository.dart';
import '../datasources/ventas_remote_datasource.dart';
import '../models/venta_model.dart';

class VentasRepositoryImpl implements VentasRepository {
  final VentasRemoteDatasource remoteDatasource;
  VentasRepositoryImpl({required this.remoteDatasource});

  @override
  Future<List<Venta>> getVentas() async {
    return await remoteDatasource.fetchVentas();
  }

  @override
  Future<void> agregarVenta(Venta venta) async {
    await remoteDatasource.postVenta(venta as VentaModel);
  }
}
