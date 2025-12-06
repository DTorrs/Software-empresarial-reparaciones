class Technician {
  final int id;
  final int userId;
  final String name;
  final String? email;
  final int locationId;
  final String locationName;
  final bool isAvailable;
  final bool hasPendingWarranty;
  final double completionRate;
  final int pendingServices;
  final String? createdAt;
  final String? updatedAt;
  
  // Constructor
  Technician({
    required this.id,
    required this.userId,
    required this.name,
    this.email,
    required this.locationId,
    required this.locationName,
    required this.isAvailable,
    required this.hasPendingWarranty,
    required this.completionRate,
    required this.pendingServices,
    this.createdAt,
    this.updatedAt,
  });
  
factory Technician.fromJson(Map<String, dynamic> json) {
  return Technician(
    id: json['id'] ?? 0,
    userId: json['user_id'] ?? 0, // This is likely missing too
    name: json['name'] ?? '',
    email: json['email'],
    locationId: json['location_id'] ?? 0, // Using default since it's missing
    locationName: json['location_name'] ?? '',
    isAvailable: json['is_available'] == 1, // Convert int to boolean
    hasPendingWarranty: json['has_pending_warranty'] == 1, // Convert int to boolean
    completionRate: double.tryParse(json['completion_rate']?.toString() ?? '0') ?? 0.0,
    pendingServices: json['pending_services'] ?? 0,
    createdAt: json['created_at'],
    updatedAt: json['updated_at'],
  );
}
  
  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'email': email,
      'location_id': locationId,
      'location_name': locationName,
      'is_available': isAvailable,
      'has_pending_warranty': hasPendingWarranty,
      'completion_rate': completionRate,
      'pending_services': pendingServices,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
  
  // Copia con cambios
  Technician copyWith({
    int? id,
    int? userId,
    String? name,
    String? email,
    int? locationId,
    String? locationName,
    bool? isAvailable,
    bool? hasPendingWarranty,
    double? completionRate,
    int? pendingServices,
    String? createdAt,
    String? updatedAt,
  }) {
    return Technician(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      isAvailable: isAvailable ?? this.isAvailable,
      hasPendingWarranty: hasPendingWarranty ?? this.hasPendingWarranty,
      completionRate: completionRate ?? this.completionRate,
      pendingServices: pendingServices ?? this.pendingServices,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  // Método para verificar disponibilidad del técnico
  bool get isReadyForNewService => isAvailable && !hasPendingWarranty;
  
  // Método para obtener el porcentaje de pago según la tasa de finalización
  double getPaymentPercentage() {
    if (completionRate >= 80) {
      return 80.0; // 80% del valor del servicio
    } else if (completionRate >= 70) {
      return 70.0; // 70% del valor (reducción del 10%)
    } else {
      return 60.0; // 60% del valor (reducción del 20%)
    }
  }
  
  @override
  String toString() {
    return 'Technician(id: $id, name: $name, locationName: $locationName, completionRate: $completionRate, pendingServices: $pendingServices)';
  }
}