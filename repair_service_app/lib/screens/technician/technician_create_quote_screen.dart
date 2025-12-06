import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:repair_service_app/config/theme.dart';
import 'package:repair_service_app/models/service.dart';
import 'package:repair_service_app/services/service_service.dart';
import 'package:repair_service_app/utils/formatters.dart';
import 'package:repair_service_app/utils/validators.dart';
import 'package:repair_service_app/widgets/common/custom_app_bar.dart';
import 'package:repair_service_app/widgets/common/loading_indicator.dart';
import 'package:repair_service_app/widgets/dialogs/alert_dialog.dart';
import 'package:repair_service_app/widgets/dialogs/confirm_dialog.dart';
import 'package:repair_service_app/widgets/dialogs/success_dialog.dart';
import 'package:repair_service_app/widgets/forms/custom_text_field.dart';
import 'package:repair_service_app/widgets/forms/photo_upload_field.dart';

// Extensión para String para agregar funcionalidad relacionada con estados de servicio
extension ServiceStatusExtension on String {
  String get formattedServiceStatus {
    switch (this) {
      case 'new':
        return 'Nuevo';
      case 'assigned':
        return 'Asignado';
      case 'in_progress':
        return 'En Progreso';
      case 'completed':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  Color get serviceStatusColor {
    switch (this) {
      case 'new':
        return AppTheme.newServiceColor;
      case 'assigned':
        return AppTheme.assignedServiceColor;
      case 'in_progress':
        return AppTheme.inProgressServiceColor;
      case 'completed':
        return AppTheme.completedServiceColor;
      case 'cancelled':
        return AppTheme.cancelledServiceColor;
      default:
        return Colors.grey;
    }
  }
  
  IconData get serviceTypeIcon {
    switch (this) {
      case 'repair':
        return Icons.build;
      case 'maintenance':
        return Icons.handyman;
      default:
        return Icons.home_repair_service;
    }
  }
}

// Extensión para Service para agregar propiedades faltantes
extension ServiceExtension on Service {
  String? get technicianLocationName {
    return 'No disponible';
  }

  String? get clientLocationName {
    return 'No disponible';
  }
}

class TechnicianCreateQuoteScreen extends StatefulWidget {
  final int serviceId;
  
  const TechnicianCreateQuoteScreen({
    Key? key,
    required this.serviceId,
  }) : super(key: key);

  @override
  State<TechnicianCreateQuoteScreen> createState() => _TechnicianCreateQuoteScreenState();
}

class _TechnicianCreateQuoteScreenState extends State<TechnicianCreateQuoteScreen> {
  final ServiceService _serviceService = ServiceService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  Service? _service;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _priceEdited = false;
  List<File> _beforePhotos = [];
  String? _priceError;
  String? _photoError;
  
  @override
  void initState() {
    super.initState();
    _loadServiceDetails();
  }
  
  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _loadServiceDetails() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await _serviceService.getServiceById(widget.serviceId);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          
          if (response.success && response.data != null) {
            _service = response.data;
            
            // Pre-llenar el precio si ya existe
            if (_service!.estimatedPrice != null) {
              _priceController.text = _service!.estimatedPrice!.toString();
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'No se pudieron cargar los detalles del servicio: $e',
        );
      }
    }
  }
  
  Future<void> _submitQuote() async {
    // Validar el formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Validar que haya al menos una foto
    if (_beforePhotos.isEmpty && (_service?.beforePhotos.isEmpty ?? true)) {
      setState(() {
        _photoError = 'Debe subir al menos una foto del equipo antes de enviar el presupuesto';
      });
      return;
    } else {
      setState(() {
        _photoError = null;
      });
    }
    
    // Confirmar envío
    final bool? confirm = await showConfirmDialog(
      context: context,
      title: 'Confirmar Presupuesto',
      content: '¿Estás seguro de que deseas enviar un presupuesto de ${Formatters.formatCurrency(double.parse(_priceController.text))} para este servicio?',
      confirmText: 'Enviar Presupuesto',
      cancelText: 'Cancelar',
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      // Subir fotos primero si hay nuevas
      for (final photo in _beforePhotos) {
        final uploadResponse = await _serviceService.uploadServicePhoto(
          widget.serviceId, 
          photo, 
          'before'
        );
        
        if (!uploadResponse.success) {
          throw Exception('Error al subir foto: ${uploadResponse.message}');
        }
      }
      
      // Actualizar el precio estimado
      final double price = double.parse(_priceController.text);
      final priceResponse = await _serviceService.updateEstimatedPrice(
        widget.serviceId, 
        price
      );
      
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        
        if (priceResponse.success) {
          // Mostrar diálogo de éxito
          showAnimatedSuccessDialog(
            context: context,
            title: 'Presupuesto Enviado',
            message: 'El presupuesto de ${Formatters.formatCurrency(price)} ha sido enviado exitosamente.',
            buttonText: 'Aceptar',
            onButtonPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context, true); // Volver a la pantalla anterior con resultado positivo
            },
          );
        } else {
          showErrorDialog(
            context: context,
            title: 'Error',
            message: 'No se pudo enviar el presupuesto: ${priceResponse.message}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Error al enviar el presupuesto: $e',
        );
      }
    }
  }
  
  Future<void> _addPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    
    if (image != null && mounted) {
      setState(() {
        _beforePhotos.add(File(image.path));
        _photoError = null;
      });
    }
  }
  
  void _removePhoto(int index) {
    setState(() {
      _beforePhotos.removeAt(index);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Generar Presupuesto',
        ),
        body: const LoadingIndicator(message: 'Cargando detalles del servicio...'),
      );
    }
    
    if (_service == null) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Generar Presupuesto',
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'No se encontró el servicio',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadServiceDetails,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Generar Presupuesto',
        actions: [
          TextButton.icon(
            onPressed: _submitQuote,
            icon: const Icon(
              Icons.send,
              color: Colors.white,
            ),
            label: const Text(
              'Enviar',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildServiceInfoCard(),
                  const SizedBox(height: 24),
                  _buildQuoteForm(),
                  const SizedBox(height: 24),
                  _buildPhotosSection(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (_isSubmitting)
            const FullscreenLoadingIndicator(
              message: 'Enviando presupuesto...',
            ),
        ],
      ),
    );
  }
  
  Widget _buildServiceInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _service!.status.serviceStatusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _service!.serviceType.serviceTypeIcon,
                    color: _service!.status.serviceStatusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Servicio #${_service!.id}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_service!.deviceType} ${_service!.deviceBrand}',
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _service!.status.serviceStatusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _service!.status.serviceStatusColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _service!.status.formattedServiceStatus,
                    style: TextStyle(
                      color: _service!.status.serviceStatusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Problema reportado:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _service!.issueDescription,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cliente:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _service!.clientName,
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ubicación:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _service!.clientLocationName ?? 'No especificada',
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuoteForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del Presupuesto',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            MoneyTextField(
              label: 'Precio Estimado',
              hint: '0.00',
              controller: _priceController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El precio es requerido';
                }
                try {
                  final price = double.parse(value);
                  if (price <= 0) {
                    return 'El precio debe ser mayor a 0';
                  }
                } catch (e) {
                  return 'Ingrese un número válido';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _priceEdited = true;
                  if (_priceError != null) {
                    _priceError = null;
                  }
                });
              },
            ),
            if (_priceError != null)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Text(
                  _priceError!,
                  style: TextStyle(
                    color: AppTheme.errorColor,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            MessageTextField(
              label: 'Notas adicionales',
              hint: 'Ingrese notas o detalles adicionales sobre el presupuesto',
              controller: _notesController,
              minLines: 3,
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPhotosSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.photo_camera,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Fotos del Equipo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' (Obligatorio)',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.errorColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Debe tomar fotos del equipo dañado antes de enviar el presupuesto.',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            if (_photoError != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.errorColor,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppTheme.errorColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _photoError!,
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            // Mostrar fotos existentes si hay
            if (_service!.beforePhotos.isNotEmpty) ...[
              const Text(
                'Fotos existentes:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildExistingPhotosGrid(),
              const SizedBox(height: 16),
            ],
            // Nuevas fotos
            if (_beforePhotos.isNotEmpty) ...[
              const Text(
                'Nuevas fotos:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildNewPhotosGrid(),
              const SizedBox(height: 16),
            ],
            // Botón para agregar foto
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addPhoto,
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Agregar Foto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExistingPhotosGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _service!.beforePhotos.length,
      itemBuilder: (context, index) {
        final photo = _service!.beforePhotos[index];
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey[300]!,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  photo.photoPath,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.error,
                        color: Colors.red,
                      ),
                    );
                  },
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Foto ${index + 1}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildNewPhotosGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _beforePhotos.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey[300]!,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.file(
                  _beforePhotos[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _removePhoto(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitQuote,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : Text(
                'ENVIAR PRESUPUESTO: ${_priceEdited ? Formatters.formatCurrency(double.tryParse(_priceController.text) ?? 0) : ""}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}