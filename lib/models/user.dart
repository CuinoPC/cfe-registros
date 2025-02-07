class User {
  final String nombre;
  final int rp;
  final int areaId; // ✅ Ahora el área es un ID (entero)
  final String contrasenia;
  final bool esAdmin;

  User({
    required this.nombre,
    required this.rp,
    required this.areaId, // ✅ Cambiado a entero
    required this.contrasenia,
    required this.esAdmin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      nombre: json['nombre_completo'],
      rp: json['rp'],
      areaId: json['area_id'], // ✅ Debe coincidir con la BD
      contrasenia: json['contrasenia'] ?? "No disponible",
      esAdmin: json['es_admin'],
    );
  }
}
