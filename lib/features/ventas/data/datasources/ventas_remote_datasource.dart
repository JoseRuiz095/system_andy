import '../models/venta_model.dart';

abstract class VentasRemoteDatasource {
  Future<List<VentaModel>> fetchVentas();
  Future<void> postVenta(VentaModel venta);
}

class VentasRemoteDatasourceImpl implements VentasRemoteDatasource {
  @override
  Future<List<VentaModel>> fetchVentas() async {
    // TODO: Implementar consumo de API REST
    return [];
  }

  @override
  Future<void> postVenta(VentaModel venta) async {
    // TODO: Implementar consumo de API REST
  }
}
