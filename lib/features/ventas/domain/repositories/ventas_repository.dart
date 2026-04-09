import '../entities/venta.dart';

abstract class VentasRepository {
  Future<List<Venta>> getVentas();
  Future<void> agregarVenta(Venta venta);
}
