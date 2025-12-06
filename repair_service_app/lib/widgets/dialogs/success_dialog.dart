import 'package:flutter/material.dart';
import 'package:repair_service_app/config/theme.dart';

class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onButtonPressed;
  final Widget? customContent;
  final bool showAnimation;
  
  const SuccessDialog({
    Key? key,
    required this.title,
    required this.message,
    this.buttonText = 'Aceptar',
    this.onButtonPressed,
    this.customContent,
    this.showAnimation = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildContent(context),
    );
  }
  
  Widget _buildContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.0,
            offset: Offset(0.0, 10.0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showAnimation)
            _buildSuccessAnimation()
          else
            const CircleAvatar(
              backgroundColor: AppTheme.successColor,
              radius: 40,
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 50,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.successColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          if (customContent != null) ...[
            const SizedBox(height: 16),
            customContent!,
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onButtonPressed ?? () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSuccessAnimation() {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            color: AppTheme.successColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              height: 80 * value,
              width: 80 * value,
              decoration: BoxDecoration(
                color: AppTheme.successColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 50 * value,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Muestra un diálogo de éxito con animación
Future<void> showAnimatedSuccessDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonText = 'Aceptar',
  VoidCallback? onButtonPressed,
  Widget? customContent,
  bool barrierDismissible = true,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext context) {
      return SuccessDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        onButtonPressed: onButtonPressed,
        customContent: customContent,
        showAnimation: true,
      );
    },
  );
}

/// Muestra un diálogo específico para operación completada
Future<void> showOperationCompletedDialog({
  required BuildContext context,
  String title = 'Operación Completada',
  required String message,
  String buttonText = 'Continuar',
  VoidCallback? onButtonPressed,
}) {
  return showAnimatedSuccessDialog(
    context: context,
    title: title,
    message: message,
    buttonText: buttonText,
    onButtonPressed: onButtonPressed,
  );
}

/// Muestra un diálogo específico para servicio guardado
Future<void> showServiceSavedDialog({
  required BuildContext context,
  required int serviceId,  // Added 'required' modifier
  String? serviceName,
  VoidCallback? onButtonPressed,
}) {
  return showAnimatedSuccessDialog(
    context: context,
    title: 'Servicio Guardado',
    message: 'El servicio ${serviceName != null ? '"$serviceName" ' : ''}ha sido guardado exitosamente con número #$serviceId.',
    buttonText: 'Aceptar',
    onButtonPressed: onButtonPressed,
    customContent: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_outline,
            color: AppTheme.infoColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Número de servicio: #$serviceId',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Muestra un diálogo específico para garantía creada
Future<void> showWarrantyCreatedDialog({
  required BuildContext context,
  required int warrantyServiceId,  // Added 'required' modifier
  required int originalServiceId,  // Added 'required' modifier
  VoidCallback? onButtonPressed,
}) {
  return showAnimatedSuccessDialog(
    context: context,
    title: 'Garantía Creada',
    message: 'La garantía para el servicio #$originalServiceId ha sido creada exitosamente.',
    buttonText: 'Aceptar',
    onButtonPressed: onButtonPressed,
    customContent: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warrantyServiceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.warrantyServiceColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.verified,
                color: AppTheme.warrantyServiceColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'ID de garantía: #$warrantyServiceId',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.warrantyServiceColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Servicio original: #$originalServiceId',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    ),
  );
}