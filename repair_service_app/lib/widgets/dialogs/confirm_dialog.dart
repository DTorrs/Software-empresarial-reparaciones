import 'package:flutter/material.dart';
import 'package:repair_service_app/config/theme.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;
  final IconData? icon;
  
  const ConfirmDialog({
    Key? key,
    required this.title,
    required this.content,
    this.confirmText = 'Aceptar',
    this.cancelText = 'Cancelar',
    this.isDestructive = false,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: isDestructive ? AppTheme.errorColor : AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isDestructive ? AppTheme.errorColor : null,
              ),
            ),
          ),
        ],
      ),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelText,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            confirmText,
            style: TextStyle(
              color: isDestructive ? AppTheme.errorColor : AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

/// Muestra un diálogo de confirmación y devuelve true si el usuario confirma
Future<bool?> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = 'Aceptar',
  String cancelText = 'Cancelar',
  bool isDestructive = false,
  IconData? icon,
  bool barrierDismissible = true,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext context) {
      return ConfirmDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        icon: icon,
      );
    },
  );
}

// Variante para confirmar eliminación
Future<bool?> showDeleteConfirmDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = 'Eliminar',
  String cancelText = 'Cancelar',
}) {
  return showConfirmDialog(
    context: context,
    title: title,
    content: content,
    confirmText: confirmText,
    cancelText: cancelText,
    isDestructive: true,
    icon: Icons.delete,
  );
}

// Variante para confirmar cancelación
Future<bool?> showCancelConfirmDialog({
  required BuildContext context,
  String title = '¿Cancelar cambios?',
  String content = 'Los cambios no guardados se perderán. ¿Deseas continuar?',
  String confirmText = 'Sí, cancelar',
  String cancelText = 'No, continuar editando',
}) {
  return showConfirmDialog(
    context: context,
    title: title,
    content: content,
    confirmText: confirmText,
    cancelText: cancelText,
    isDestructive: true,
    icon: Icons.warning,
  );
}

// Variante para confirmar salida
Future<bool?> showExitConfirmDialog({
  required BuildContext context,
  String title = '¿Salir sin guardar?',
  String content = 'Los cambios no guardados se perderán. ¿Deseas salir?',
  String confirmText = 'Sí, salir',
  String cancelText = 'No, continuar',
}) {
  return showConfirmDialog(
    context: context,
    title: title,
    content: content,
    confirmText: confirmText,
    cancelText: cancelText,
    isDestructive: true,
    icon: Icons.exit_to_app,
    barrierDismissible: false,
  );
}