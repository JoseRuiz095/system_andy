import '../../domain/entities/venta.dart';

class VentaModel extends Venta {
  VentaModel({required super.id, required super.total, required super.fecha});

  factory VentaModel.fromJson(Map<String, dynamic> json) => VentaModel(
        id: json['id'],
        total: json['total'],
        fecha: DateTime.parse(json['fecha']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'total': total,
        'fecha': fecha.toIso8601String(),
      };
}
