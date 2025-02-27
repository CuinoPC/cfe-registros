class User {
  final String nombre;
  final String rp;
  final int areaId; // ✅ Ahora el área es un ID (entero)
  final String contrasenia;
  final bool esAdmin;
  final bool esCentro;

  User({
    required this.nombre,
    required this.rp,
    required this.areaId, // ✅ Cambiado a entero
    required this.contrasenia,
    required this.esAdmin,
    required this.esCentro,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      nombre: json['nombre_completo'],
      rp: json['rp'],
      areaId: json['area_id'], // ✅ Debe coincidir con la BD
      contrasenia: json['contrasenia'] ?? "No disponible",
      esAdmin: json['es_admin'],
      esCentro: json['es_centro'],
    );
  }
}
