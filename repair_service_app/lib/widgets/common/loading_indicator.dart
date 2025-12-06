import 'package:flutter/material.dart';
import 'package:repair_service_app/config/theme.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final Color? color;
  final double size;
  final double strokeWidth;
  final bool isFullScreen;
  
  const LoadingIndicator({
    Key? key,
    this.message,
    this.color,
    this.size = 40.0,
    this.strokeWidth = 4.0,
    this.isFullScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Widget loadingIndicator = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppTheme.primaryColor,
            ),
            strokeWidth: strokeWidth,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
    
    if (isFullScreen) {
      return Material(
        type: MaterialType.transparency,
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 24,
                horizontal: 32,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: loadingIndicator,
            ),
          ),
        ),
      );
    }
    
    return Center(child: loadingIndicator);
  }
}

// FullscreenLoadingIndicator como una utilidad para superposición
class FullscreenLoadingIndicator extends StatelessWidget {
  final String? message;
  
  const FullscreenLoadingIndicator({
    Key? key,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ModalBarrier(
          dismissible: false,
          color: Colors.black54,
        ),
        Center(
          child: LoadingIndicator(
            message: message,
            isFullScreen: true,
          ),
        ),
      ],
    );
  }
  
  // Método para mostrar/ocultar el indicador de carga en pantalla completa
  static OverlayEntry? _overlayEntry;
  
  static void show(BuildContext context, {String? message}) {
    hide(); // Asegurar que no haya un overlay existente
    
    _overlayEntry = OverlayEntry(
      builder: (context) => FullscreenLoadingIndicator(message: message),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }
  
  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

// LoadingFutureBuilder para simplificar el uso de FutureBuilder con carga
class LoadingFutureBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final String? loadingMessage;
  final Widget? errorWidget;
  final Function(Object, StackTrace?)? onError;
  
  const LoadingFutureBuilder({
    Key? key,
    required this.future,
    required this.builder,
    this.loadingMessage,
    this.errorWidget,
    this.onError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoadingIndicator(message: loadingMessage);
        } else if (snapshot.hasError) {
          if (onError != null) {
            onError!(snapshot.error!, snapshot.stackTrace);
          }
          
          if (errorWidget != null) {
            return errorWidget!;
          }
          
          return ErrorDisplay(
            error: snapshot.error.toString(),
            stackTrace: snapshot.stackTrace?.toString(),
          );
        } else if (snapshot.hasData) {
          return builder(context, snapshot.data as T);
        } else {
          return const ErrorDisplay(
            error: 'No se recibieron datos',
          );
        }
      },
    );
  }
}

// ErrorDisplay para mostrar errores
class ErrorDisplay extends StatelessWidget {
  final String error;
  final String? stackTrace;
  final VoidCallback? onRetry;
  
  const ErrorDisplay({
    Key? key,
    required this.error,
    this.stackTrace,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.errorColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (stackTrace != null && stackTrace!.isNotEmpty) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('Detalles técnicos'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Text(
                        stackTrace!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}