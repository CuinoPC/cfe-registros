class Terminal {
  final int id;
  final String marca;
  final String modelo;
  final String serie;
  final String inventario;
  final String rpeResponsable;
  final String nombreResponsable;
  final int usuarioId;
  final Map<String, List<String>> fotos;

  Terminal({
    required this.id,
    required this.marca,
    required this.modelo,
    required this.serie,
    required this.inventario,
    required this.rpeResponsable,
    required this.nombreResponsable,
    required this.usuarioId,
    required this.fotos,
  });

  factory Terminal.fromJson(Map<String, dynamic> json) {
    return Terminal(
      id: json['id'] != null ? json['id'] as int : 0, // ✅ Si es null, poner 0
      marca:
          json['marca'] ?? 'Desconocido', // ✅ Si es null, poner 'Desconocido'
      modelo: json['modelo'] ?? 'Desconocido',
      serie: json['serie'] ?? 'N/A',
      inventario: json['inventario'] ?? 'N/A',
      rpeResponsable: json['rpe_responsable'] ?? 'N/A',
      nombreResponsable: json['nombre_responsable'] ?? 'N/A',
      usuarioId: json['usuario_id'] != null
          ? json['usuario_id'] as int
          : 0, // ✅ Si es null, poner 0
      fotos: json['fotos'] != null && json['fotos'] is Map<String, dynamic>
          ? (json['fotos'] as Map<String, dynamic>)
              .map((key, value) => MapEntry(key, List<String>.from(value)))
          : {},
    );
  }
}
