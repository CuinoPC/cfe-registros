class HistorialLector {
  final int id;
  final int lectorId;
  final String marca;
  final String modelo;
  final String folio;
  final String tipoConector;
  final String rpeResponsable;
  final String nombreResponsable;
  final int usuarioId;
  final String area;
  final String accion;
  final String realizadoPor;
  final DateTime fecha;

  HistorialLector({
    required this.id,
    required this.lectorId,
    required this.marca,
    required this.modelo,
    required this.folio,
    required this.tipoConector,
    required this.rpeResponsable,
    required this.nombreResponsable,
    required this.usuarioId,
    required this.area,
    required this.accion,
    required this.realizadoPor,
    required this.fecha,
  });

  factory HistorialLector.fromJson(Map<String, dynamic> json) {
    return HistorialLector(
      id: json['id'],
      lectorId: json['lector_id'],
      marca: json['marca'],
      modelo: json['modelo'],
      folio: json['folio'],
      tipoConector: json['tipo_conector'],
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
