class Terminal {
  final int id;
  final String marca;
  final String modelo;
  final String serie;
  final String inventario;
  final int rpeResponsable;
  final String nombreResponsable;
  final int usuarioId;
  final Map<String, List<String>>
      fotos; // ✅ Ahora las fotos estarán agrupadas por fecha

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
      id: json['id'],
      marca: json['marca'],
      modelo: json['modelo'],
      serie: json['serie'],
      inventario: json['inventario'],
      rpeResponsable: json['rpe_responsable'],
      nombreResponsable: json['nombre_responsable'],
      usuarioId: json['usuario_id'],
      fotos: json['fotos'] != null && json['fotos'] is Map<String, dynamic>
          ? (json['fotos'] as Map<String, dynamic>)
              .map((key, value) => MapEntry(key, List<String>.from(value)))
          : {}, // ✅ Manejar caso en el que no haya fotos
    );
  }
}
