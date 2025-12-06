import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Formatters {
  // Formatear moneda (pesos mexicanos)
  static String formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }
  
  // Formatear porcentaje
  static String formatPercentage(double value, {int decimalDigits = 2}) {
    final formatter = NumberFormat.percentPattern('es_MX')
      ..maximumFractionDigits = decimalDigits;
    return formatter.format(value / 100);
  }
  
  // Formatear fecha corta (dd/mm/yyyy)
  static String formatShortDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
  
  // Formatear fecha y hora (dd/mm/yyyy HH:mm)
  static String formatDateTime(String dateTimeString) {
    try {
      final date = DateTime.parse(dateTimeString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateTimeString;
    }
  }
  
  // Formatear fecha relativa (hoy, ayer, hace X días)
  static String formatRelativeDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Hoy, ${DateFormat('HH:mm').format(date)}';
      } else if (difference.inDays == 1) {
        return 'Ayer, ${DateFormat('HH:mm').format(date)}';
      } else if (difference.inDays < 7) {
        return 'Hace ${difference.inDays} días';
      } else {
        return DateFormat('dd/MM/yyyy').format(date);
      }
    } catch (e) {
      return dateString;
    }
  }
  
  // Formatear teléfono con máscara (XX) XXXX-XXXX
  static String formatPhone(String phone) {
    if (phone.length != 10) return phone;
    
    return '(${phone.substring(0, 2)}) ${phone.substring(2, 6)}-${phone.substring(6)}';
  }
}

// InputFormatter para teléfonos (10 dígitos)
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Eliminar caracteres no numéricos
    final newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    // Limitar a 10 dígitos
    if (newText.length > 10) {
      return oldValue;
    }
    
    String formattedText = newText;
    
    // Aplicar formato según cantidad de dígitos
    if (newText.length >= 3) {
      formattedText = '(${newText.substring(0, 2)})';
      
      if (newText.length >= 7) {
        formattedText += ' ${newText.substring(2, 6)}-${newText.substring(6)}';
      } else if (newText.length > 2) {
        formattedText += ' ${newText.substring(2)}';
      }
    }
    
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

// InputFormatter para moneda (decimal con dos decimales)
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, 
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    // Eliminar todo excepto números y punto decimal
    String newText = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');
    
    // Asegurar que solo haya un punto decimal
    if (newText.contains('.')) {
      final parts = newText.split('.');
      if (parts.length > 2) {
        newText = '${parts[0]}.${parts[1]}';
      }
      
      // Limitar a dos decimales
      final decimalPart = parts[1];
      if (decimalPart.length > 2) {
        newText = '${parts[0]}.${decimalPart.substring(0, 2)}';
      }
    }
    
    // Formatear con separadores de miles
    try {
      final value = double.parse(newText);
      final formatted = NumberFormat.currency(
        locale: 'es_MX',
        symbol: '\$',
        decimalDigits: newText.contains('.') ? 2 : 0,
      ).format(value);
      
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } catch (e) {
      return oldValue;
    }
  }
}