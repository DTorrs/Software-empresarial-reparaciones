import 'package:flutter/material.dart';
import 'package:repair_service_app/config/theme.dart';

// Extensión para Strings
extension StringExtensions on String {
  // Capitalizar primera letra de cada palabra
  String get capitalize {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
  
  // Capitalizar solo la primera letra
  String get capitalizeFirst {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
  
  // Validar si es un email
  bool get isEmail {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(this);
  }
  
  // Validar si es un teléfono de 10 dígitos
  bool get isPhone {
    final cleaned = replaceAll(RegExp(r'[\s\-()]'), '');
    return RegExp(r'^\d{10}$').hasMatch(cleaned);
  }
  
  // Obtener solo dígitos
  String get digitsOnly {
    return replaceAll(RegExp(r'[^\d]'), '');
  }
  
  // Obtener color según estado de servicio
  Color get serviceStatusColor {
    return AppTheme.getServiceStatusColor(this);
  }
  
  // Obtener nombre formateado según estado de servicio
  String get formattedServiceStatus {
    return AppTheme.getFormattedServiceStatus(this);
  }
  
  // Obtener icono según tipo de servicio
  IconData get serviceTypeIcon {
    return AppTheme.getServiceTypeIcon(this);
  }
}

// Extensión para DateTime
extension DateTimeExtensions on DateTime {
  // Formatear fecha corta (dd/mm/yyyy)
  String get toShortDate {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
  }
  
  // Formatear fecha y hora (dd/mm/yyyy HH:mm)
  String get toDateTime {
    return '${toShortDate} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
  
  // Comprobar si es hoy
  bool get isToday {
    final now = DateTime.now();
    return now.year == year && now.month == month && now.day == day;
  }
  
  // Comprobar si es ayer
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return yesterday.year == year && yesterday.month == month && yesterday.day == day;
  }
  
  // Obtener fecha relativa
  String get toRelative {
    final now = DateTime.now();
    final difference = now.difference(this);
    
    if (isToday) {
      return 'Hoy, ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } else if (isYesterday) {
      return 'Ayer, ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return toShortDate;
    }
  }
}

// Extensión para BuildContext
extension BuildContextExtensions on BuildContext {
  // Obtener tema
  ThemeData get theme => Theme.of(this);
  
  // Obtener colores
  ColorScheme get colorScheme => theme.colorScheme;
  
  // Obtener tamaño de pantalla
  Size get screenSize => MediaQuery.of(this).size;
  
  // Obtener ancho de pantalla
  double get screenWidth => screenSize.width;
  
  // Obtener alto de pantalla
  double get screenHeight => screenSize.height;
  
  // Comprobar si el dispositivo es una tablet
  bool get isTablet => screenWidth > 600;
  
  // Navegación simplificada
  Future<T?> navigateTo<T>(Widget page) {
    return Navigator.push<T>(this, MaterialPageRoute(builder: (_) => page));
  }
  
  // Navegación con reemplazo
  Future<T?> navigateAndReplace<T>(Widget page) {
    return Navigator.pushReplacement<T, dynamic>(
      this, 
      MaterialPageRoute(builder: (_) => page)
    );
  }
  
  // Quitar teclado
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }
  
  // Mostrar SnackBar
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}