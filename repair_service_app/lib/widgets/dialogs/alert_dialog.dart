import 'package:flutter/material.dart';
import 'package:repair_service_app/config/theme.dart';

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onButtonPressed;
  final IconData? icon;
  final Color? iconColor;
  final Color? backgroundColor;
  
  const CustomAlertDialog({
    Key? key,
    required this.title,
    required this.message,
    this.buttonText = 'Aceptar',
    this.onButtonPressed,
    this.icon,
    this.iconColor,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: backgroundColor ?? Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: iconColor ?? AppTheme.primaryColor,
              size: 28,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Text(message),
      actions: [
        ElevatedButton(
          onPressed: onButtonPressed ?? () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: iconColor ?? AppTheme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(buttonText),
        ),
      ],
    );
  }
}

/// Muestra un diálogo de alerta informativo
Future<void> showInfoDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonText = 'Aceptar',
  VoidCallback? onButtonPressed,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return CustomAlertDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        onButtonPressed: onButtonPressed,
        icon: Icons.info,
        iconColor: AppTheme.infoColor,
      );
    },
  );
}

/// Muestra un diálogo de alerta de éxito
Future<void> showSuccessDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonText = 'Aceptar',
  VoidCallback? onButtonPressed,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return CustomAlertDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        onButtonPressed: onButtonPressed,
        icon: Icons.check_circle,
        iconColor: AppTheme.successColor,
      );
    },
  );
}

/// Muestra un diálogo de alerta de error
Future<void> showErrorDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonText = 'Aceptar',
  VoidCallback? onButtonPressed,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return CustomAlertDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        onButtonPressed: onButtonPressed,
        icon: Icons.error,
        iconColor: AppTheme.errorColor,
      );
    },
  );
}

/// Muestra un diálogo de alerta de advertencia
Future<void> showWarningDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonText = 'Aceptar',
  VoidCallback? onButtonPressed,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return CustomAlertDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        onButtonPressed: onButtonPressed,
        icon: Icons.warning,
        iconColor: AppTheme.warningColor,
      );
    },
  );
}