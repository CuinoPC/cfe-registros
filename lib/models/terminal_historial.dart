class HistorialRegistro {
  final int id;
  final int terminalId;
  final String marca;
  final String modelo;
  final String serie;
  final String inventario;
  final String rpeResponsable;
  final String nombreResponsable;
  final int usuarioId;
  final String area;
  final String accion;
  final String realizadoPor;
  final DateTime fecha;

  HistorialRegistro({
    required this.id,
    required this.terminalId,
    required this.marca,
    required this.modelo,
    required this.serie,
    required this.inventario,
    required this.rpeResponsable,
    required this.nombreResponsable,
    required this.usuarioId,
    required this.area,
    required this.accion,
    required this.realizadoPor,
    required this.fecha,
  });

  factory HistorialRegistro.fromJson(Map<String, dynamic> json) {
    return HistorialRegistro(
      id: json['id'],
      terminalId: json['terminal_id'],
      marca: json['marca'],
      modelo: json['modelo'],
      serie: json['serie'],
      inventario: json['inventario'],
      rpeResponsable: json['rpe_responsable'],
      nombreResponsable: json['nombre_responsable'],
      usuarioId: json['usuario_id'],
      area: json['area'],
      accion: json['accion'],
      realizadoPor: json['realizado_por'] ?? 'No disponible',
      fecha: DateTime.parse(json['fecha']),
    );
  }
}
