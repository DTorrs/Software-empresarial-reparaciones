class Client {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final int locationId;
  final String locationName;
  final String? createdAt;
  final String? updatedAt;
  
  // Constructor
  Client({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    required this.locationId,
    required this.locationName,
    this.createdAt,
    this.updatedAt,
  });
  
  // Crear desde JSON
  factory Client.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    if (json['id'] == null) {
      throw FormatException('Missing required field: id');
    }
    if (json['name'] == null) {
      throw FormatException('Missing required field: name');
    }
    if (json['location_id'] == null) {
      throw FormatException('Missing required field: location_id');
    }
    if (json['location_name'] == null) {
      throw FormatException('Missing required field: location_name');
    }
    
    return Client(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      locationId: json['location_id'],
      locationName: json['location_name'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
  
  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'location_id': locationId,
      'location_name': locationName,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
  
  // Copia con cambios
  Client copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    int? locationId,
    String? locationName,
    String? createdAt,
    String? updatedAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  // Método para obtener inicial para avatar
  String get initial {
    if (name.isEmpty) return 'C';
    return name[0].toUpperCase();
  }
  
  // Método para formatear la información de contacto
  String get contactInfo {
    List<String> parts = [];
    if (phone != null && phone!.isNotEmpty) parts.add('Tel: $phone');
    if (email != null && email!.isNotEmpty) parts.add('Email: $email');
    return parts.join(' • ');
  }
  
  @override
  String toString() {
    return 'Client(id: $id, name: $name, location: $locationName)';
  }
}