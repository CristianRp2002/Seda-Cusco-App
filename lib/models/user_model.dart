class UserModel {
  final String id;
  final String username;
  final String nombreCompleto;
  final String rol;

  UserModel({
    required this.id,
    required this.username,
    required this.nombreCompleto,
    required this.rol,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      nombreCompleto: json['nombre_completo'],
      rol: json['rol']['nombre'],
    );
  }
}