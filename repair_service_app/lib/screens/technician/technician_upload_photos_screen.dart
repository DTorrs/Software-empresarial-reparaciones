import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:repair_service_app/config/app_config.dart';
import 'package:repair_service_app/config/theme.dart';
import 'package:repair_service_app/models/service.dart';
import 'package:repair_service_app/services/service_service.dart';
import 'package:repair_service_app/widgets/common/custom_app_bar.dart';
import 'package:repair_service_app/widgets/common/loading_indicator.dart';
import 'package:repair_service_app/widgets/dialogs/alert_dialog.dart';
import 'package:repair_service_app/widgets/dialogs/confirm_dialog.dart';
import 'package:repair_service_app/widgets/dialogs/success_dialog.dart';
import 'package:repair_service_app/widgets/forms/photo_upload_field.dart';

// Extensión para String para estados de servicio
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
}
class TechnicianUploadPhotosScreen extends StatefulWidget {
  final Service service;
  final String photoType; // 'before' o 'after'
  final Function(List<ServicePhoto>) onPhotosUploaded;
  
  const TechnicianUploadPhotosScreen({
    Key? key,
    required this.service,
    required this.photoType,
    required this.onPhotosUploaded,
  }) : super(key: key);

  @override
  State<TechnicianUploadPhotosScreen> createState() => _TechnicianUploadPhotosScreenState();
}

class _TechnicianUploadPhotosScreenState extends State<TechnicianUploadPhotosScreen> {
  final ServiceService _serviceService = ServiceService();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isUploading = false;
  List<File> _selectedPhotos = [];
  List<ServicePhoto> _existingPhotos = [];
  bool _hasChanges = false;
  
  @override
  void initState() {
    super.initState();
    _loadExistingPhotos();
  }
  
  void _loadExistingPhotos() {
    if (widget.photoType == 'before') {
      _existingPhotos = widget.service.beforePhotos;
    } else {
      _existingPhotos = widget.service.afterPhotos;
    }
  }
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: AppConfig.maxImageWidth.toDouble(),
        maxHeight: AppConfig.maxImageHeight.toDouble(),
        imageQuality: AppConfig.imageQuality.toInt(),
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedPhotos.add(File(pickedFile.path));
          _hasChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'No se pudo seleccionar la imagen: $e',
        );
      }
    }
  }
  
  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Tomar foto'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Seleccionar de galería'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
      _hasChanges = true;
    });
  }
  
  Future<void> _uploadPhotos() async {
    if (_selectedPhotos.isEmpty) {
      showWarningDialog(
        context: context,
        title: 'Sin fotos',
        message: 'Debes seleccionar al menos una foto para subir.',
      );
      return;
    }
    
    setState(() {
      _isUploading = true;
    });
    
    List<ServicePhoto> uploadedPhotos = [];
    bool hasError = false;
    String errorMessage = '';
    
    // Subir cada foto
    for (int i = 0; i < _selectedPhotos.length; i++) {
      try {
        final response = await _serviceService.uploadServicePhoto(
          widget.service.id,
          _selectedPhotos[i],
          widget.photoType,
        );
        
        if (response.success && response.data != null) {
  uploadedPhotos.add(response.data!); 
        } else {
          hasError = true;
          errorMessage = response.message;
          break;
        }
      } catch (e) {
        hasError = true;
        errorMessage = e.toString();
        break;
      }
    }
    
    if (mounted) {
      setState(() {
        _isUploading = false;
      });
      
      if (hasError) {
        showErrorDialog(
          context: context,
          title: 'Error al subir fotos',
          message: errorMessage,
        );
      } else {
        // Mostrar mensaje de éxito
        showAnimatedSuccessDialog(
          context: context,
          title: 'Fotos subidas con éxito',
          message: 'Se han subido ${uploadedPhotos.length} fotos correctamente.',
          onButtonPressed: () {
            Navigator.pop(context); // Cerrar diálogo
            Navigator.pop(context, uploadedPhotos); // Volver a la pantalla anterior
          },
        );
        
        // Llamar al callback con las fotos subidas
        widget.onPhotosUploaded([..._existingPhotos, ...uploadedPhotos]);
      }
    }
  }
  
  Future<bool> _onWillPop() async {
    if (_hasChanges && _selectedPhotos.isNotEmpty) {
      final bool? shouldDiscard = await showConfirmDialog(
        context: context,
        title: 'Descartar cambios',
        content: '¿Estás seguro de que deseas salir sin subir las fotos seleccionadas?',
        confirmText: 'Descartar',
        cancelText: 'Continuar editando',
        isDestructive: true,
        icon: Icons.warning,
      );
      
      return shouldDiscard ?? false;
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: CustomAppBar(
          title: widget.photoType == 'before'
              ? 'Fotos del equipo dañado'
              : 'Fotos del equipo reparado',
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showPhotoGuidelines,
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildServiceInfoCard(),
                _buildExistingPhotosSection(),
                _buildSelectedPhotosSection(),
              ],
            ),
            if (_isUploading)
              const FullscreenLoadingIndicator(
                message: 'Subiendo fotos...',
              ),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploading ? null : _showImageOptions,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Agregar foto'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading || _selectedPhotos.isEmpty
                        ? null
                        : _uploadPhotos,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Subir fotos'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildServiceInfoCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Servicio #${widget.service.id}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dispositivo: ${widget.service.deviceType} ${widget.service.deviceBrand}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cliente: ${widget.service.clientName}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.service.status.serviceStatusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.service.status.serviceStatusColor.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    widget.service.status.formattedServiceStatus,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: widget.service.status.serviceStatusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Problema: ${widget.service.issueDescription}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.photoType == 'before'
                        ? Icons.build
                        : Icons.check_circle,
                    color: widget.photoType == 'before'
                        ? Colors.amber
                        : AppTheme.successColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.photoType == 'before'
                          ? 'Sube fotos del equipo dañado antes de iniciar la reparación. Esto es obligatorio para generar el presupuesto.'
                          : 'Sube fotos del equipo ya reparado. Esto es obligatorio para marcar el servicio como completado.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExistingPhotosSection() {
    if (_existingPhotos.isEmpty) {
      return Container();
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fotos existentes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _existingPhotos.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.network(
                            _existingPhotos[index].photoPath,
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
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          left: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            color: Colors.black54,
                            child: const Text(
                              'Ya subida',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
        ],
      ),
    );
  }
  
  Widget _buildSelectedPhotosSection() {
    return Expanded(
      child: _selectedPhotos.isEmpty
          ? _buildEmptyState()
          : _buildPhotoGrid(),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay fotos seleccionadas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.photoType == 'before'
                ? 'Toma fotos claras del equipo dañado'
                : 'Toma fotos claras del equipo reparado',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showImageOptions,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Agregar foto'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPhotoGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _selectedPhotos.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedPhotos[index],
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _removePhoto(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: AppTheme.errorColor,
                    size: 20,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  'Foto ${index + 1}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  void _showPhotoGuidelines() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          widget.photoType == 'before'
              ? 'Guía para fotos del equipo dañado'
              : 'Guía para fotos del equipo reparado',
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGuidelineItem(
                'Toma fotos con buena iluminación',
                'Evita sombras y lugares oscuros.',
              ),
              const SizedBox(height: 12),
              _buildGuidelineItem(
                'Captura diferentes ángulos',
                'Incluye tomas frontales, laterales y de las zonas específicas.',
              ),
              const SizedBox(height: 12),
              _buildGuidelineItem(
                'Enfócate en el área del problema',
                'Muestra claramente las partes dañadas o reparadas.',
              ),
              const SizedBox(height: 12),
              _buildGuidelineItem(
                'Asegúrate que las fotos sean claras',
                'Evita movimientos o imágenes borrosas.',
              ),
              const SizedBox(height: 12),
              if (widget.photoType == 'before')
                _buildGuidelineItem(
                  'Evidencia el estado inicial',
                  'Estas fotos son necesarias para generar el presupuesto.',
                )
              else
                _buildGuidelineItem(
                  'Muestra el trabajo terminado',
                  'Documenta la reparación completada satisfactoriamente.',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGuidelineItem(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle,
          color: AppTheme.successColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}