import 'dart:io';
import 'package:flutter/material.dart';
import 'package:repair_service_app/config/theme.dart';
import 'package:repair_service_app/models/service.dart';
import 'package:repair_service_app/services/service_service.dart';
import 'package:repair_service_app/utils/formatters.dart';
import 'package:repair_service_app/widgets/common/custom_app_bar.dart';
import 'package:repair_service_app/widgets/common/loading_indicator.dart';
import 'package:repair_service_app/widgets/dialogs/alert_dialog.dart';
import 'package:repair_service_app/widgets/dialogs/confirm_dialog.dart';
import 'package:repair_service_app/widgets/dialogs/success_dialog.dart';
import 'package:repair_service_app/widgets/forms/custom_text_field.dart';
import 'package:repair_service_app/widgets/forms/photo_upload_field.dart';
import 'package:image_picker/image_picker.dart';

// Agrega estas extensiones después de tus importaciones

// Extensión para String para estados de servicio
extension ServiceStatusExtension on String {
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

// Extensión para Service para propiedades faltantes
extension ServiceExtension on Service {
  String? get clientLocationName {
    // Implementación simplificada - puedes modificarla según tus necesidades
    return null;
  }

  bool get hasBeforePhotos {
    return beforePhotos.isNotEmpty;
  }
  
  bool get hasAfterPhotos {
    return afterPhotos.isNotEmpty;
  }
}

class TechnicianServiceDetailsScreen extends StatefulWidget {
  final int serviceId;
  
  const TechnicianServiceDetailsScreen({
    Key? key,
    required this.serviceId,
  }) : super(key: key);

  @override
  State<TechnicianServiceDetailsScreen> createState() => _TechnicianServiceDetailsScreenState();
}

class _TechnicianServiceDetailsScreenState extends State<TechnicianServiceDetailsScreen> {
  final ServiceService _serviceService = ServiceService();
  final GlobalKey<FormState> _quoteFormKey = GlobalKey<FormState>();
  final TextEditingController _estimatedPriceController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUpdatingStatus = false;
  bool _isSendingMessage = false;
  Service? _service;
  File? _selectedBeforePhoto;
  File? _selectedAfterPhoto;
  
  @override
  void initState() {
    super.initState();
    _loadServiceDetails();
  }
  
  @override
  void dispose() {
    _estimatedPriceController.dispose();
    _messageController.dispose();
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
            
            // Si hay un precio estimado, mostrarlo en el formulario
            if (_service?.estimatedPrice != null) {
              _estimatedPriceController.text = _service!.estimatedPrice.toString();
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
          message: 'No se pudo cargar los detalles del servicio: $e',
        );
      }
    }
  }
  
  Future<void> _saveEstimatedPrice() async {
    if (!_quoteFormKey.currentState!.validate()) return;
    
    final double price = double.parse(_estimatedPriceController.text);
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final response = await _serviceService.updateEstimatedPrice(
        _service!.id,
        price,
      );
      
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        if (response.success && response.data != null) {
          _service = response.data;
          
          showSuccessDialog(
            context: context,
            title: 'Presupuesto Guardado',
            message: 'El presupuesto ha sido guardado exitosamente y se ha notificado al cliente.',
          );
        } else {
          showErrorDialog(
            context: context,
            title: 'Error',
            message: 'No se pudo guardar el presupuesto: ${response.message}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Error al guardar el presupuesto: $e',
        );
      }
    }
  }
  
  Future<void> _updateServiceStatus(String newStatus) async {
    if (_service == null) return;
    
    // Validar si puede cambiar el estado
    if (newStatus == 'completed') {
      if (!_service!.hasBeforePhotos) {
        showWarningDialog(
          context: context,
          title: 'Fotos requeridas',
          message: 'Debes subir fotos del equipo dañado antes de marcar como completado.',
        );
        return;
      }
      
      if (!_service!.hasAfterPhotos) {
        showWarningDialog(
          context: context,
          title: 'Fotos requeridas',
          message: 'Debes subir fotos del equipo reparado antes de marcar como completado.',
        );
        return;
      }
      
      if (_service!.estimatedPrice == null) {
        showWarningDialog(
          context: context,
          title: 'Presupuesto requerido',
          message: 'Debes establecer un presupuesto antes de marcar como completado.',
        );
        return;
      }
    }
    
    // Confirmar cambio de estado
    final bool? confirm = await showConfirmDialog(
      context: context,
      title: 'Cambiar Estado',
      content: '¿Estás seguro de que deseas cambiar el estado del servicio a "${_getStatusName(newStatus)}"?',
      confirmText: 'Cambiar Estado',
      cancelText: 'Cancelar',
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isUpdatingStatus = true;
    });
    
    try {
      final response = await _serviceService.updateServiceStatus(
        _service!.id,
        newStatus,
      );
      
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
        
        if (response.success && response.data != null) {
          _service = response.data;
          
          showSuccessDialog(
            context: context,
            title: 'Estado Actualizado',
            message: 'El estado del servicio ha sido actualizado exitosamente a "${_getStatusName(newStatus)}".',
          );
        } else {
          showErrorDialog(
            context: context,
            title: 'Error',
            message: 'No se pudo actualizar el estado: ${response.message}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
        
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Error al actualizar el estado: $e',
        );
      }
    }
  }
  
  Future<void> _uploadServicePhoto(String photoType) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1080,
      maxHeight: 1920,
      imageQuality: 85,
    );
    
    if (pickedFile == null) return;
    
    final File photo = File(pickedFile.path);
    
    if (photoType == 'before') {
      setState(() {
        _selectedBeforePhoto = photo;
      });
    } else {
      setState(() {
        _selectedAfterPhoto = photo;
      });
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final response = await _serviceService.uploadServicePhoto(
        _service!.id,
        photo,
        photoType,
      );
      
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        if (response.success && response.data != null) {
          // Recargar los detalles del servicio para obtener las fotos actualizadas
          await _loadServiceDetails();
          
          showSuccessDialog(
            context: context,
            title: 'Foto Subida',
            message: 'La foto ha sido subida exitosamente.',
          );
        } else {
          showErrorDialog(
            context: context,
            title: 'Error',
            message: 'No se pudo subir la foto: ${response.message}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Error al subir la foto: $e',
        );
      }
    }
  }
  
  Future<void> _sendMessageToClient() async {
    if (_messageController.text.trim().isEmpty) return;
    
    setState(() {
      _isSendingMessage = true;
    });
    
    try {
      // Simulación de envío de mensaje a través de Twilio
      // En una implementación real, usaríamos un servicio para enviar el mensaje
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
        });
        
        // Limpiar el campo de mensaje
        _messageController.clear();
        
        showSuccessDialog(
          context: context,
          title: 'Mensaje Enviado',
          message: 'El mensaje ha sido enviado exitosamente al cliente.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
        });
        
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Error al enviar el mensaje: $e',
        );
      }
    }
  }
  
  String _getStatusName(String status) {
    switch (status) {
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
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Cargando Servicio',
        ),
        body: const LoadingIndicator(message: 'Cargando detalles del servicio...'),
      );
    }
    
    if (_service == null) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Error',
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
                'No se pudo cargar la información del servicio',
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
        title: 'Servicio #${_service!.id}',
        actions: [
          if (_service!.isWarranty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Tooltip(
                message: 'Servicio en garantía',
                child: const Icon(
                  Icons.verified,
                  color: AppTheme.warrantyServiceColor,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadServiceDetails,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildServiceInfoCard(),
                  const SizedBox(height: 24),
                  _buildStatusSection(),
                  const SizedBox(height: 24),
                  _buildPhotosSection(),
                  const SizedBox(height: 24),
                  _buildQuoteSection(),
                  const SizedBox(height: 24),
                  _buildClientCommunication(),
                  const SizedBox(height: 80), // Espacio para botones
                ],
              ),
            ),
          ),
          if (_isSaving || _isUpdatingStatus || _isSendingMessage)
            const FullscreenLoadingIndicator(message: 'Guardando cambios...'),
        ],
      ),
      bottomNavigationBar: _buildBottomButtons(),
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
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _service!.serviceType.serviceTypeIcon,
                    color: _service!.status.serviceStatusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_service!.deviceType} ${_service!.deviceBrand}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusName(_service!.status),
                        style: TextStyle(
                          fontSize: 14,
                          color: _service!.status.serviceStatusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _service!.serviceType == 'repair'
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : AppTheme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _service!.serviceType == 'repair' ? 'Reparación' : 'Mantenimiento',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _service!.serviceType == 'repair'
                          ? AppTheme.primaryColor
                          : AppTheme.secondaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Cliente', _service!.clientName),
            if (_service!.clientLocationName != null)
              _buildInfoRow('Ubicación', _service!.clientLocationName!),
            _buildInfoRow('Problema', _service!.issueDescription),
            if (_service!.assignedDate != null)
              _buildInfoRow('Fecha asignación', Formatters.formatShortDate(_service!.assignedDate!)),
            if (_service!.isWarranty && _service!.originalServiceId != null)
              _buildInfoRow('Servicio original', '#${_service!.originalServiceId}', 
                valueColor: AppTheme.warrantyServiceColor),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusSection() {
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
              'Estado del Servicio',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatusStep('Asignado', 'assigned', 1),
                _buildStatusArrow(),
                _buildStatusStep('En Progreso', 'in_progress', 2),
                _buildStatusArrow(),
                _buildStatusStep('Completado', 'completed', 3),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusStep(String label, String status, int step) {
    final bool isCurrentStatus = _service!.status == status;
    final bool isCompleted = _getStatusStep(_service!.status) >= step;
    
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted 
                  ? status.serviceStatusColor 
                  : Colors.grey[300],
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    )
                  : Text(
                      step.toString(),
                      style: TextStyle(
                        color: isCurrentStatus ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isCurrentStatus ? FontWeight.bold : FontWeight.normal,
              color: isCurrentStatus 
                  ? status.serviceStatusColor
                  : isCompleted 
                      ? Colors.black 
                      : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusArrow() {
    return const SizedBox(
      width: 20,
      child: Center(
        child: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey,
        ),
      ),
    );
  }
  
  int _getStatusStep(String status) {
    switch (status) {
      case 'new':
        return 0;
      case 'assigned':
        return 1;
      case 'in_progress':
        return 2;
      case 'completed':
        return 3;
      case 'cancelled':
        return -1;
      default:
        return 0;
    }
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
            const Text(
              'Fotos del Servicio',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Antes',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${_service!.beforePhotos.length})',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const Spacer(),
                          if (_service!.status != 'completed')
                            TextButton.icon(
                              onPressed: () => _uploadServicePhoto('before'),
                              icon: const Icon(Icons.camera_alt, size: 16),
                              label: const Text('Subir'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildPhotoGrid(_service!.beforePhotos),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Después',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${_service!.afterPhotos.length})',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const Spacer(),
                          if (_service!.status != 'completed')
                            TextButton.icon(
                              onPressed: () => _uploadServicePhoto('after'),
                              icon: const Icon(Icons.camera_alt, size: 16),
                              label: const Text('Subir'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildPhotoGrid(_service!.afterPhotos),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPhotoGrid(List<ServicePhoto> photos) {
    if (photos.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'No hay fotos',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
      );
    }
    
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // Mostrar foto en pantalla completa
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              photos[index].photoPath,
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
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.red,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildQuoteSection() {
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
                  Icons.request_quote,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Presupuesto',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_service!.estimatedPrice != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.green[300]!,
                      ),
                    ),
                    child: Text(
                      Formatters.formatCurrency(_service!.estimatedPrice!),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_service!.status != 'completed')
              Form(
                key: _quoteFormKey,
                child: Column(
                  children: [
                    MoneyTextField(
                      label: 'Precio estimado',
                      controller: _estimatedPriceController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese un precio estimado';
                        }
                        
                        final doubleValue = double.tryParse(value);
                        if (doubleValue == null || doubleValue <= 0) {
                          return 'Ingrese un precio válido';
                        }
                        
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _saveEstimatedPrice,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Presupuesto'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Al guardar el presupuesto, se notificará automáticamente al cliente con los detalles.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Presupuesto final',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Formatters.formatCurrency(_service!.estimatedPrice!),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.check_circle,
                          color: AppTheme.successColor,
                          size: 32,
                        ),
                      ],
                    ),
                  ),
                  if (_service!.paymentPercentage != null && _service!.paymentAmount != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.payments,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Pago calculado',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Porcentaje: ${Formatters.formatPercentage(_service!.paymentPercentage!)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Monto: ${Formatters.formatCurrency(_service!.paymentAmount!)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildClientCommunication() {
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
                  Icons.chat,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Comunicación con el Cliente',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Campo de mensaje
            MessageTextField(
              label: 'Mensaje para el cliente',
              hint: 'Escribe un mensaje para el cliente...',
              controller: _messageController,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _messageController.text.trim().isEmpty ? null : _sendMessageToClient,
              icon: const Icon(Icons.send),
              label: const Text('Enviar Mensaje'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Los mensajes se envían de forma anónima a través de Twilio. El cliente no verá tu número de teléfono.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBottomButtons() {
    // Si el servicio está completado, no mostrar botones de acción
    if (_service!.status == 'completed') {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Si el servicio está asignado, mostramos botón para cambiar a "En Progreso"
          if (_service!.status == 'assigned')
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isUpdatingStatus ? null : () => _updateServiceStatus('in_progress'),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar Trabajo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
              ),
            ),
          
          // Si el servicio está en progreso, mostramos botón para completar
          if (_service!.status == 'in_progress') ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isUpdatingStatus ? null : () => _updateServiceStatus('completed'),
                icon: const Icon(Icons.check_circle),
                label: const Text('Marcar Completado'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.completedServiceColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}