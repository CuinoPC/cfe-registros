class User {
  final String nombre;
  final int rp;
  final String area;
  final String contrasenia;
  final bool esAdmin;

  User({
    required this.nombre,
    required this.rp,
    required this.area,
    required this.contrasenia,
    required this.esAdmin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      nombre: json['nombre_completo'],
      rp: json['rp'],
      area: json['area'],
      contrasenia:
          json['contrasenia'] ?? "No disponible", // Asegurar que nunca sea null
      esAdmin: json['es_admin'],
    );
  }
}
