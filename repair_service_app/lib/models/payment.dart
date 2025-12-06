class Payment {
  final int id;
  final int technicianId;
  final int serviceId;
  final double servicePrice;
  final double appliedPercentage;
  final double paymentAmount;
  final String calculationDate;
  final String? technicianName;
  final String? deviceType;
  final String? deviceBrand;
  final String? serviceType;
  final String? clientName;
  final String? completedDate;
  final bool? isWarranty;
  
  // Constructor
  Payment({
    required this.id,
    required this.technicianId,
    required this.serviceId,
    required this.servicePrice,
    required this.appliedPercentage,
    required this.paymentAmount,
    required this.calculationDate,
    this.technicianName,
    this.deviceType,
    this.deviceBrand,
    this.serviceType,
    this.clientName,
    this.completedDate,
    this.isWarranty,
  });
  
  // Crear desde JSON
  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      technicianId: json['technician_id'],
      serviceId: json['service_id'],
      servicePrice: json['service_price']?.toDouble() ?? 0.0,
      appliedPercentage: json['applied_percentage']?.toDouble() ?? 0.0,
      paymentAmount: json['payment_amount']?.toDouble() ?? 0.0,
      calculationDate: json['calculation_date'],
      technicianName: json['technician_name'],
      deviceType: json['device_type'],
      deviceBrand: json['device_brand'],
      serviceType: json['service_type'],
      clientName: json['client_name'],
      completedDate: json['completed_date'],
      isWarranty: json['is_warranty'],
    );
  }
  
  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'technician_id': technicianId,
      'service_id': serviceId,
      'service_price': servicePrice,
      'applied_percentage': appliedPercentage,
      'payment_amount': paymentAmount,
      'calculation_date': calculationDate,
      'technician_name': technicianName,
      'device_type': deviceType,
      'device_brand': deviceBrand,
      'service_type': serviceType,
      'client_name': clientName,
      'completed_date': completedDate,
      'is_warranty': isWarranty,
    };
  }
  
  // Copia con cambios
  Payment copyWith({
    int? id,
    int? technicianId,
    int? serviceId,
    double? servicePrice,
    double? appliedPercentage,
    double? paymentAmount,
    String? calculationDate,
    String? technicianName,
    String? deviceType,
    String? deviceBrand,
    String? serviceType,
    String? clientName,
    String? completedDate,
    bool? isWarranty,
  }) {
    return Payment(
      id: id ?? this.id,
      technicianId: technicianId ?? this.technicianId,
      serviceId: serviceId ?? this.serviceId,
      servicePrice: servicePrice ?? this.servicePrice,
      appliedPercentage: appliedPercentage ?? this.appliedPercentage,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      calculationDate: calculationDate ?? this.calculationDate,
      technicianName: technicianName ?? this.technicianName,
      deviceType: deviceType ?? this.deviceType,
      deviceBrand: deviceBrand ?? this.deviceBrand,
      serviceType: serviceType ?? this.serviceType,
      clientName: clientName ?? this.clientName,
      completedDate: completedDate ?? this.completedDate,
      isWarranty: isWarranty ?? this.isWarranty,
    );
  }
  
  @override
  String toString() {
    return 'Payment(serviceId: $serviceId, technicianId: $technicianId, servicePrice: $servicePrice, appliedPercentage: $appliedPercentage, paymentAmount: $paymentAmount)';
  }
}

class PaymentSummary {
  final double totalServiceValue;
  final double totalPaymentAmount;
  final double averagePercentage;
  final int totalServices;
  final String? firstPaymentDate;
  final String? lastPaymentDate;
  final double? recentPaymentAmount;
  final int? recentServices;
  
  // Constructor
  PaymentSummary({
    required this.totalServiceValue,
    required this.totalPaymentAmount,
    required this.averagePercentage,
    required this.totalServices,
    this.firstPaymentDate,
    this.lastPaymentDate,
    this.recentPaymentAmount,
    this.recentServices,
  });
  
  // Crear desde JSON
  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    // Puede tener diferentes estructuras dependiendo de la API
    if (json['summary'] != null && json['recent'] != null) {
      // Formato cuando incluye datos recientes
      final summary = json['summary'];
      final recent = json['recent'];
      
      return PaymentSummary(
        totalServiceValue: summary['total_service_value']?.toDouble() ?? 0.0,
        totalPaymentAmount: summary['total_payment_amount']?.toDouble() ?? 0.0,
        averagePercentage: summary['average_percentage']?.toDouble() ?? 0.0,
        totalServices: summary['total_services'] ?? 0,
        firstPaymentDate: summary['first_payment_date'],
        lastPaymentDate: summary['last_payment_date'],
        recentPaymentAmount: recent['recent_payment_amount']?.toDouble() ?? 0.0,
        recentServices: recent['recent_services'] ?? 0,
      );
    } else {
      // Formato simple
      return PaymentSummary(
        totalServiceValue: json['total_service_value']?.toDouble() ?? 0.0,
        totalPaymentAmount: json['total_payment_amount']?.toDouble() ?? 0.0,
        averagePercentage: json['average_percentage']?.toDouble() ?? 0.0,
        totalServices: json['total_services'] ?? 0,
        firstPaymentDate: json['first_payment_date'],
        lastPaymentDate: json['last_payment_date'],
      );
    }
  }
  
  // Convertir a JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'total_service_value': totalServiceValue,
      'total_payment_amount': totalPaymentAmount,
      'average_percentage': averagePercentage,
      'total_services': totalServices,
      'first_payment_date': firstPaymentDate,
      'last_payment_date': lastPaymentDate,
    };
    
    if (recentPaymentAmount != null || recentServices != null) {
      data['recent'] = {
        'recent_payment_amount': recentPaymentAmount,
        'recent_services': recentServices,
      };
    }
    
    return data;
  }
}