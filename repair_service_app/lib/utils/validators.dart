class Validators {
  // Validar campo requerido
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es requerido${fieldName != null ? ': $fieldName' : ''}';
    }
    return null;
  }
  
  // Validar correo electrónico
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // No validar si está vacío (usar validateRequired para eso)
    }
    
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegExp.hasMatch(value)) {
      return 'Introduce un correo electrónico válido';
    }
    
    return null;
  }
  
  // Validar teléfono (10 dígitos)
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // No validar si está vacío (usar validateRequired para eso)
    }
    
    // Eliminar espacios, guiones y paréntesis
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-()]'), '');
    
    if (cleanPhone.length != 10 || !RegExp(r'^\d{10}$').hasMatch(cleanPhone)) {
      return 'El teléfono debe tener 10 dígitos';
    }
    
    return null;
  }
  
  // Validar contraseña (mínimo 6 caracteres)
  static String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.trim().isEmpty) {
      return 'La contraseña es requerida';
    }
    
    if (value.length < minLength) {
      return 'La contraseña debe tener al menos $minLength caracteres';
    }
    
    return null;
  }
  
  // Validar que dos valores sean iguales (útil para confirmar contraseña)
  static String? validateMatching(
    String? value1, 
    String? value2, {
    String field1 = 'Primer valor',
    String field2 = 'Segundo valor',
  }) {
    if (value1 == null || value2 == null) {
      return null;
    }
    
    if (value1 != value2) {
      return '$field1 y $field2 deben coincidir';
    }
    
    return null;
  }
  
  // Validar un número
  static String? validateNumber(String? value, {String? fieldName, bool allowDecimal = true}) {
    if (value == null || value.trim().isEmpty) {
      return null; // No validar si está vacío (usar validateRequired para eso)
    }
    
    final numRegExp = allowDecimal 
        ? RegExp(r'^-?\d+(\.\d+)?$')  // Permite decimales
        : RegExp(r'^-?\d+$');         // Solo enteros
    
    if (!numRegExp.hasMatch(value)) {
      return '${fieldName ?? 'Este campo'} debe ser un número${allowDecimal ? '' : ' entero'}';
    }
    
    return null;
  }
  
  // Validar rango numérico
  static String? validateNumberRange(
    String? value, {
    double? min,
    double? max,
    bool allowDecimal = true,
    String? fieldName,
  }) {
    // Primero validar que sea un número
    final numError = validateNumber(value, fieldName: fieldName, allowDecimal: allowDecimal);
    if (numError != null) {
      return numError;
    }
    
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    
    final number = double.parse(value);
    
    if (min != null && number < min) {
      return '${fieldName ?? 'Este campo'} debe ser mayor o igual a $min';
    }
    
    if (max != null && number > max) {
      return '${fieldName ?? 'Este campo'} debe ser menor o igual a $max';
    }
    
    return null;
  }
  
  // Validar longitud de texto
  static String? validateLength(
    String? value, {
    int? minLength,
    int? maxLength,
    String? fieldName,
  }) {
    if (value == null || value.trim().isEmpty) {
      return null; // No validar si está vacío (usar validateRequired para eso)
    }
    
    if (minLength != null && value.length < minLength) {
      return '${fieldName ?? 'Este campo'} debe tener al menos $minLength caracteres';
    }
    
    if (maxLength != null && value.length > maxLength) {
      return '${fieldName ?? 'Este campo'} debe tener máximo $maxLength caracteres';
    }
    
    return null;
  }
}