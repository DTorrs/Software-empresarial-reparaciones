import 'package:repair_service_app/models/technician.dart';

class ServicePhoto {
  final int id;
  final String photoPath;
  final String photoType; // 'before' o 'after'
  final String uploadedAt;
  
  ServicePhoto({
    required this.id,
    required this.photoPath,
    required this.photoType,
    required this.uploadedAt,
  });
  
  factory ServicePhoto.fromJson(Map<String, dynamic> json) {
    return ServicePhoto(
      id: json['id'],
      photoPath: json['photo_path'],
      photoType: json['photo_type'],
      uploadedAt: json['uploaded_at'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'photo_path': photoPath,
      'photo_type': photoType,
      'uploaded_at': uploadedAt,
    };
  }
}

class Service {
  final int id;
  final int clientId;
  final String clientName;
  final String deviceType;
  final String deviceBrand;
  final String issueDescription;
  final String serviceType; // 'repair' o 'maintenance'
  final String status; // 'new', 'assigned', 'in_progress', 'completed', 'cancelled'
  final bool isWarranty;
  final int? originalServiceId;
  final int? technicianId;
  final String? technicianName;
  final double? estimatedPrice;
  final double? finalPrice;
  final double? paymentPercentage;
  final double? paymentAmount;
  final String? assignedDate;
  final String? completedDate;
  final String? createdAt;
  final String? updatedAt;
  final String? clientLocationName;
  final List<ServicePhoto> beforePhotos;
  final List<ServicePhoto> afterPhotos;
  
  // Constructor
  Service({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.deviceType,
    required this.deviceBrand,
    required this.issueDescription,
    required this.serviceType,
    required this.status,
    required this.isWarranty,
    this.originalServiceId,
    this.technicianId,
    this.technicianName,
    this.estimatedPrice,
    this.finalPrice,
    this.paymentPercentage,
    this.paymentAmount,
    this.assignedDate,
    this.completedDate,
    this.createdAt,
    this.updatedAt,
    this.clientLocationName,
    this.beforePhotos = const [],
    this.afterPhotos = const [],
  });
  
  // Crear desde JSON
  factory Service.fromJson(Map<String, dynamic> json) {
    // Procesar fotos si existen
    List<ServicePhoto> beforePhotos = [];
    List<ServicePhoto> afterPhotos = [];
    
    if (json['photos'] != null) {
      if (json['photos']['before'] != null) {
        beforePhotos = (json['photos']['before'] as List)
            .map((photoJson) => ServicePhoto.fromJson(photoJson))
            .toList();
      }
      
      if (json['photos']['after'] != null) {
        afterPhotos = (json['photos']['after'] as List)
            .map((photoJson) => ServicePhoto.fromJson(photoJson))
            .toList();
      }
    }
    
    return Service(
      id: json['id'],
      clientId: json['client_id'],
      clientName: json['client_name'],
      deviceType: json['device_type'],
      deviceBrand: json['device_brand'],
      issueDescription: json['issue_description'],
      serviceType: json['service_type'],
      status: json['status'],
      isWarranty: json['is_warranty'] ?? false,
      originalServiceId: json['original_service_id'],
      technicianId: json['technician_id'],
      technicianName: json['technician_name'],
      estimatedPrice: json['estimated_price']?.toDouble(),
      finalPrice: json['final_price']?.toDouble(),
      paymentPercentage: json['payment_percentage']?.toDouble(),
      paymentAmount: json['payment_amount']?.toDouble(),
      assignedDate: json['assigned_date'],
      completedDate: json['completed_date'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      clientLocationName: json['client_location_name'] ?? json['client_location'],
      beforePhotos: beforePhotos,
      afterPhotos: afterPhotos,
    );
  }
  
  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'client_name': clientName,
      'device_type': deviceType,
      'device_brand': deviceBrand,
      'issue_description': issueDescription,
      'service_type': serviceType,
      'status': status,
      'is_warranty': isWarranty,
      'original_service_id': originalServiceId,
      'technician_id': technicianId,
      'technician_name': technicianName,
      'estimated_price': estimatedPrice,
      'final_price': finalPrice,
      'payment_percentage': paymentPercentage,
      'payment_amount': paymentAmount,
      'assigned_date': assignedDate,
      'completed_date': completedDate,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'client_location_name': clientLocationName,
      'photos': {
        'before': beforePhotos.map((photo) => photo.toJson()).toList(),
        'after': afterPhotos.map((photo) => photo.toJson()).toList(),
      },
    };
  }
  
  // Copia con cambios
  Service copyWith({
    int? id,
    int? clientId,
    String? clientName,
    String? deviceType,
    String? deviceBrand,
    String? issueDescription,
    String? serviceType,
    String? status,
    bool? isWarranty,
    int? originalServiceId,
    int? technicianId,
    String? technicianName,
    double? estimatedPrice,
    double? finalPrice,
    double? paymentPercentage,
    double? paymentAmount,
    String? assignedDate,
    String? completedDate,
    String? createdAt,
    String? updatedAt,
    String? clientLocationName,
    List<ServicePhoto>? beforePhotos,
    List<ServicePhoto>? afterPhotos,
  }) {
    return Service(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      deviceType: deviceType ?? this.deviceType,
      deviceBrand: deviceBrand ?? this.deviceBrand,
      issueDescription: issueDescription ?? this.issueDescription,
      serviceType: serviceType ?? this.serviceType,
      status: status ?? this.status,
      isWarranty: isWarranty ?? this.isWarranty,
      originalServiceId: originalServiceId ?? this.originalServiceId,
      technicianId: technicianId ?? this.technicianId,
      technicianName: technicianName ?? this.technicianName,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      finalPrice: finalPrice ?? this.finalPrice,
      paymentPercentage: paymentPercentage ?? this.paymentPercentage,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      assignedDate: assignedDate ?? this.assignedDate,
      completedDate: completedDate ?? this.completedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      clientLocationName: clientLocationName ?? this.clientLocationName,
      beforePhotos: beforePhotos ?? this.beforePhotos,
      afterPhotos: afterPhotos ?? this.afterPhotos,
    );
  }
  
  // Métodos de utilidad
  
  // Verificar si el servicio tiene fotos antes
  bool get hasBeforePhotos => beforePhotos.isNotEmpty;
  
  // Verificar si el servicio tiene fotos después
  bool get hasAfterPhotos => afterPhotos.isNotEmpty;
  
  // Verificar si el servicio tiene un técnico asignado
  bool get hasTechnician => technicianId != null;
  
  // Verificar si el servicio está listo para presupuesto (tiene técnico asignado y fotos antes)
  bool get isReadyForQuote => hasTechnician && hasBeforePhotos;
  
  // Verificar si el servicio está listo para completar (tiene técnico, presupuesto, fotos antes y después)
  bool get isReadyToComplete => 
      hasTechnician && 
      hasBeforePhotos && 
      hasAfterPhotos && 
      estimatedPrice != null;
  
  // Calcular el monto de pago para el técnico
  double calculateTechnicianPayment(Technician technician) {
    if (finalPrice == null) return 0.0;
    
    double percentage = technician.getPaymentPercentage();
    return (finalPrice! * percentage) / 100;
  }
  
  @override
  String toString() {
    return 'Service(id: $id, clientName: $clientName, deviceType: $deviceType, status: $status, isWarranty: $isWarranty)';
  }
  
}