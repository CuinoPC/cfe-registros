class Lector {
  final int id;
  final String marca;
  final String modelo;
  final String folio;
  final String tipoConector;
  final String rpeResponsable;
  final String nombreResponsable;
  final int usuarioId;
  final String area;
  final Map<String, List<String>> fotos;

  Lector({
    required this.id,
    required this.marca,
    required this.modelo,
    required this.folio,
    required this.tipoConector,
    required this.rpeResponsable,
    required this.nombreResponsable,
    required this.usuarioId,
    required this.area,
    required this.fotos,
  });

  factory Lector.fromJson(Map<String, dynamic> json) {
    return Lector(
      id: json['id'] != null ? json['id'] as int : 0,
      marca: json['marca'] ?? 'Desconocido',
      modelo: json['modelo'] ?? 'Desconocido',
      folio: json['folio'] ?? 'N/A',
      tipoConector: json['tipo_conector'] ?? 'N/A',
      rpeResponsable: json['rpe_responsable'] ?? 'N/A',
      nombreResponsable: json['nombre_responsable'] ?? 'N/A',
      usuarioId: json['usuario_id'] != null ? json['usuario_id'] as int : 0,
      area: json['area'] ?? 'No disponible',
      fotos: json['fotos'] != null && json['fotos'] is Map<String, dynamic>
          ? (json['fotos'] as Map<String, dynamic>)
              .map((key, value) => MapEntry(key, List<String>.from(value)))
          : {},
    );
  }
}
