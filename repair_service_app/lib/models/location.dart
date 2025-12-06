class Location {
  final int id;
  final String name;
  final int? techniciansCount;
  final int? servicesCount;
  final int? completedServices;
  final int? warrantyServices;
  final String? createdAt;
  final String? updatedAt;
  
  // Constructor
  Location({
    required this.id,
    required this.name,
    this.techniciansCount,
    this.servicesCount,
    this.completedServices,
    this.warrantyServices,
    this.createdAt,
    this.updatedAt,
  });
  
  // Crear desde JSON
  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      name: json['name'],
      techniciansCount: json['technicians_count'],
      servicesCount: json['services_count'],
      completedServices: json['completed_services'],
      warrantyServices: json['warranty_services'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
  
  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'technicians_count': techniciansCount,
      'services_count': servicesCount,
      'completed_services': completedServices,
      'warranty_services': warrantyServices,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
  
  // Copia con cambios
  Location copyWith({
    int? id,
    String? name,
    int? techniciansCount,
    int? servicesCount,
    int? completedServices,
    int? warrantyServices,
    String? createdAt,
    String? updatedAt,
  }) {
    return Location(
      id: id ?? this.id,
      name: name ?? this.name,
      techniciansCount: techniciansCount ?? this.techniciansCount,
      servicesCount: servicesCount ?? this.servicesCount,
      completedServices: completedServices ?? this.completedServices,
      warrantyServices: warrantyServices ?? this.warrantyServices,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  // Obtener porcentaje de servicios completados
  double get completionPercentage {
    if (servicesCount == null || servicesCount == 0 || completedServices == null) {
      return 0.0;
    }
    return (completedServices! / servicesCount!) * 100;
  }
  
  @override
  String toString() {
    return 'Location(id: $id, name: $name, techniciansCount: $techniciansCount, servicesCount: $servicesCount)';
  }
  
  // Lista de ubicaciones predefinidas
  static List<Location> getPredefinedLocations() {
    return [
      Location(id: 1, name: 'CDMX'),
      Location(id: 2, name: 'Estado de México'),
      Location(id: 3, name: 'Monterrey'),
      Location(id: 4, name: 'Guadalajara'),
      Location(id: 5, name: 'Querétaro'),
      Location(id: 6, name: 'Veracruz'),
      Location(id: 7, name: 'Puebla'),
      Location(id: 8, name: 'Cancún'),
      Location(id: 9, name: 'Baja California Sur'),
      Location(id: 10, name: 'Indefinido'),
    ];
  }
}