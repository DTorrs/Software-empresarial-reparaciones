class User {
  final int id;
  final String username;
  final String email;
  final String name;
  final String role;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;
  
  // Constructor
  User({
    required this.id,
    required this.username,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });
  
factory User.fromJson(Map<String, dynamic> json) {
  try {
    // Función auxiliar para convertir el valor de is_active a bool
    bool convertToBoolean(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value != 0; // 0 es false, cualquier otro número es true
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return false;
    }

    return User(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      isActive: convertToBoolean(json['is_active']), // Usar la función convertToBoolean
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  } catch (e) {
    print('Error en User.fromJson: $e');
    print('JSON que causó el error: $json');
    rethrow;
  }
}
  
  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'name': name,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
  
  // Copia con cambios
  User copyWith({
    int? id,
    String? username,
    String? email,
    String? name,
    String? role,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  // Método para validar si un usuario es administrador
  bool get isAdmin => role.toLowerCase() == 'admin';
  
  // Método para validar si un usuario es secretaria
  bool get isSecretary => role.toLowerCase() == 'secretary';
  
  // Método para validar si un usuario es técnico
  bool get isTechnician => role.toLowerCase() == 'technician';
  
  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email, name: $name, role: $role, isActive: $isActive)';
  }
}