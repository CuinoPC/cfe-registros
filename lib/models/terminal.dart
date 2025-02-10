class Terminal {
  final int id;
  final String marca;
  final String serie;
  final String inventario;
  final int rpeResponsable;
  final String nombreResponsable;
  final int usuarioId;
  final List<String> fotos; // ✅ Nueva propiedad para fotos

  Terminal({
    required this.id,
    required this.marca,
    required this.serie,
    required this.inventario,
    required this.rpeResponsable,
    required this.nombreResponsable,
    required this.usuarioId,
    required this.fotos, // ✅ Agregar fotos en el constructor
  });

  factory Terminal.fromJson(Map<String, dynamic> json) {
    return Terminal(
      id: json['id'],
      marca: json['marca'],
      serie: json['serie'],
      inventario: json['inventario'],
      rpeResponsable: json['rpe_responsable'],
      nombreResponsable: json['nombre_responsable'],
      usuarioId: json['usuario_id'],
      fotos:
          List<String>.from(json['fotos'] ?? []), // ✅ Asegurar fotos como lista
    );
  }
}
