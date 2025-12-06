import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:repair_service_app/config/app_config.dart';
import 'package:repair_service_app/config/theme.dart';
import 'package:repair_service_app/models/service.dart';
import 'package:repair_service_app/widgets/dialogs/confirm_dialog.dart';

class PhotoUploadField extends StatefulWidget {
  final String label;
  final String? hintText;
  final Function(File) onPhotoSelected;
  final Function()? onRemovePhoto;
  final File? selectedPhoto;
  final String? networkImageUrl;
  final String? validationError;
  final bool isRequired;
  final bool isEnabled;
  final double maxHeight;
  final double borderRadius;
  
  const PhotoUploadField({
    Key? key,
    required this.label,
    this.hintText,
    required this.onPhotoSelected,
    this.onRemovePhoto,
    this.selectedPhoto,
    this.networkImageUrl,
    this.validationError,
    this.isRequired = true,
    this.isEnabled = true,
    this.maxHeight = 200,
    this.borderRadius = 8,
  }) : super(key: key);

  @override
  State<PhotoUploadField> createState() => _PhotoUploadFieldState();
}

class _PhotoUploadFieldState extends State<PhotoUploadField> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isUploading = true;
      });
      
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: AppConfig.maxImageWidth.toDouble(),
        maxHeight: AppConfig.maxImageHeight.toDouble(),
        imageQuality: AppConfig.imageQuality.toInt(),
      );
      
      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        widget.onPhotoSelected(imageFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
  
  Future<void> _showImageOptions() async {
    if (!widget.isEnabled) return;
    
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
                if (widget.selectedPhoto != null || widget.networkImageUrl != null)
                  ListTile(
                    leading: const Icon(Icons.delete, color: AppTheme.errorColor),
                    title: const Text(
                      'Eliminar imagen',
                      style: TextStyle(color: AppTheme.errorColor),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      final bool? confirm = await showConfirmDialog(
                        context: context,
                        title: 'Eliminar imagen',
                        content: '¿Estás seguro de que deseas eliminar esta imagen?',
                        confirmText: 'Eliminar',
                        cancelText: 'Cancelar',
                        isDestructive: true,
                      );
                      
                      if (confirm == true && widget.onRemovePhoto != null) {
                        widget.onRemovePhoto!();
                      }
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final bool hasImage = widget.selectedPhoto != null || widget.networkImageUrl != null;
    final bool hasError = widget.validationError != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.isRequired)
              Text(
                ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.errorColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: widget.isEnabled ? _showImageOptions : null,
          child: Container(
            height: widget.maxHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: hasError 
                    ? AppTheme.errorColor 
                    : widget.isEnabled
                        ? AppTheme.dividerColor
                        : Colors.grey[300]!,
                width: hasError ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius - 1),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (hasImage)
                    _buildImagePreview()
                  else
                    _buildUploadPlaceholder(),
                  
                  if (_isUploading)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  
                  if (!widget.isEnabled)
                    Container(
                      color: Colors.black12,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              widget.validationError!,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.errorColor,
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildImagePreview() {
    if (widget.selectedPhoto != null) {
      return Image.file(
        widget.selectedPhoto!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (widget.networkImageUrl != null) {
      return Image.network(
        widget.networkImageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
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
                size: 40,
              ),
            ),
          );
        },
      );
    } else {
      return Container(); // Nunca debería llegar aquí
    }
  }
  
  Widget _buildUploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo,
          size: 48,
          color: widget.isEnabled ? AppTheme.primaryColor : Colors.grey,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            widget.hintText ?? 'Toca para subir una foto',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: widget.isEnabled ? Colors.grey[700] : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}

// Widget específico para mostrar fotos de servicio
class ServicePhotosField extends StatelessWidget {
  final String label;
  final List<ServicePhoto> photos;
  final Function(int) onViewPhoto;
  final Function()? onAddPhoto;
  final bool isRequired;
  final bool isEnabled;
  final String photoType; // 'before' o 'after'
  
  const ServicePhotosField({
    Key? key,
    required this.label,
    required this.photos,
    required this.onViewPhoto,
    this.onAddPhoto,
    this.isRequired = true,
    this.isEnabled = true,
    required this.photoType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.errorColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        photos.isEmpty
            ? _buildEmptyState(context)
            : _buildPhotoGrid(context),
      ],
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled && onAddPhoto != null ? onAddPhoto! : null,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEnabled ? AppTheme.dividerColor : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo,
                size: 32,
                color: isEnabled ? AppTheme.primaryColor : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                photoType == 'before'
                    ? 'Agregar fotos del equipo dañado'
                    : 'Agregar fotos del equipo reparado',
                style: TextStyle(
                  fontSize: 12,
                  color: isEnabled ? Colors.grey[700] : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPhotoGrid(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: photos.length + (isEnabled && onAddPhoto != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == photos.length) {
          // Botón para agregar más fotos
          return GestureDetector(
            onTap: onAddPhoto,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.dividerColor,
                  width: 1,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.add_circle_outline,
                  size: 32,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          );
        } else {
          // Miniatura de foto existente
          return GestureDetector(
            onTap: () => onViewPhoto(index),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.dividerColor,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Stack(
                  children: [
                    Image.network(
                      photos[index].photoPath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
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
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        color: Colors.black54,
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
            ),
          );
        }
      },
    );
  }
}