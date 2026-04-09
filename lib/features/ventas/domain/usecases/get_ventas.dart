import '../entities/venta.dart';
import '../repositories/ventas_repository.dart';

class GetVentas {
  final VentasRepository repository;
  GetVentas(this.repository);

  Future<List<Venta>> call() async {
    return await repository.getVentas();
  }
}
