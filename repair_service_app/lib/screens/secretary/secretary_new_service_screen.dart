import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:repair_service_app/config/routes.dart';
import 'package:repair_service_app/config/theme.dart';
import 'package:repair_service_app/models/service.dart';
import 'package:repair_service_app/models/technician.dart';
import 'package:repair_service_app/services/service_service.dart';
import 'package:repair_service_app/services/technician_service.dart';
import 'package:repair_service_app/utils/validators.dart';
import 'package:repair_service_app/widgets/common/custom_app_bar.dart';
import 'package:repair_service_app/widgets/common/loading_indicator.dart';
import 'package:repair_service_app/widgets/dialogs/alert_dialog.dart';
import 'package:repair_service_app/widgets/dialogs/confirm_dialog.dart';
import 'package:repair_service_app/widgets/dialogs/success_dialog.dart';
import 'package:repair_service_app/widgets/forms/custom_dropdown.dart';
import 'package:repair_service_app/widgets/forms/custom_text_field.dart';

class SecretaryNewServiceScreen extends StatefulWidget {
  const SecretaryNewServiceScreen({Key? key}) : super(key: key);

  @override
  State<SecretaryNewServiceScreen> createState() => _SecretaryNewServiceScreenState();
}

class _SecretaryNewServiceScreenState extends State<SecretaryNewServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final ServiceService _serviceService = ServiceService();
  final TechnicianService _technicianService = TechnicianService();

  bool _isLoading = false;
  bool _isLoadingTechnicians = false;
  bool _isWarranty = false;
  List<Technician> _availableTechnicians = [];
  int? _selectedTechnicianId;
  int? _selectedLocationId;
  String? _selectedServiceType;
  int? _originalServiceId;

  // Controladores para los campos del formulario
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientPhoneController = TextEditingController();
  final TextEditingController _clientEmailController = TextEditingController();
  final TextEditingController _clientAddressController = TextEditingController();
  final TextEditingController _deviceTypeController = TextEditingController();
  final TextEditingController _deviceBrandController = TextEditingController();
  final TextEditingController _issueDescriptionController = TextEditingController();
  final TextEditingController _originalServiceIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTechnicians();
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _clientEmailController.dispose();
    _clientAddressController.dispose();
    _deviceTypeController.dispose();
    _deviceBrandController.dispose();
    _issueDescriptionController.dispose();
    _originalServiceIdController.dispose();
    super.dispose();
  }

  Future<void> _loadTechnicians() async {
    setState(() {
      _isLoadingTechnicians = true;
    });

    try {
      final response = await _technicianService.getAvailableTechnicians(
        locationId: _selectedLocationId,
      );
      
      if (mounted) {
        setState(() {
          _isLoadingTechnicians = false;
          if (response.success && response.data != null) {
            _availableTechnicians = response.data!;
          } else {
            _availableTechnicians = [];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTechnicians = false;
          _availableTechnicians = [];
        });
        
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'No se pudieron cargar los técnicos disponibles. Por favor, inténtalo de nuevo.',
        );
      }
    }
  }

  Future<void> _createService() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar campos específicos para garantía
    if (_isWarranty && (_originalServiceId == null || _originalServiceId! <= 0)) {
      showErrorDialog(
        context: context,
        title: 'Error',
        message: 'Para crear una garantía, debe proporcionar el ID del servicio original.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Preparar datos del servicio
      final Map<String, dynamic> serviceData = {
        'client_name': _clientNameController.text.trim(),
        'client_phone': _clientPhoneController.text.trim(),
        'client_email': _clientEmailController.text.trim(),
        'client_address': _clientAddressController.text.trim(),
        'client_location_id': _selectedLocationId,
        'device_type': _deviceTypeController.text.trim(),
        'device_brand': _deviceBrandController.text.trim(),
        'issue_description': _issueDescriptionController.text.trim(),
        'service_type': _selectedServiceType,
        'is_warranty': _isWarranty,
        'technician_id': _selectedTechnicianId,
      };

      if (_isWarranty && _originalServiceId != null) {
        serviceData['original_service_id'] = _originalServiceId;
      }

      // Llamar al servicio para crear el servicio
      final response = _isWarranty
          ? await _serviceService.createWarrantyService(_originalServiceId!)
          : await _serviceService.createService(serviceData);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (response.success && response.data != null) {
          Service newService = response.data!;
          
          if (_isWarranty) {
            // Mostrar diálogo de garantía creada
            showWarrantyCreatedDialog(
              context: context,
              warrantyServiceId: newService.id,
              originalServiceId: _originalServiceId!,
              onButtonPressed: () {
                Navigator.pushReplacementNamed(
                  context, 
                  AppRoutes.secretaryServiceDetails,
                  arguments: newService.id,
                );
              },
            );
          } else {
            // Mostrar diálogo de servicio guardado
            showServiceSavedDialog(
              context: context,
              serviceId: newService.id,
              serviceName: '${newService.deviceType} ${newService.deviceBrand}',
              onButtonPressed: () {
                Navigator.pushReplacementNamed(
                  context, 
                  AppRoutes.secretaryServiceDetails,
                  arguments: newService.id,
                );
              },
            );
          }
        } else {
          showErrorDialog(
            context: context,
            title: 'Error',
            message: response.message,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Ocurrió un error inesperado. Por favor, inténtalo de nuevo.',
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    // Verificar si se han hecho cambios
    bool hasChanges = _clientNameController.text.isNotEmpty ||
        _clientPhoneController.text.isNotEmpty ||
        _clientEmailController.text.isNotEmpty ||
        _clientAddressController.text.isNotEmpty ||
        _deviceTypeController.text.isNotEmpty ||
        _deviceBrandController.text.isNotEmpty ||
        _issueDescriptionController.text.isNotEmpty ||
        _originalServiceIdController.text.isNotEmpty ||
        _selectedLocationId != null ||
        _selectedServiceType != null ||
        _selectedTechnicianId != null ||
        _isWarranty;

    if (hasChanges) {
      final result = await showExitConfirmDialog(
        context: context,
        title: '¿Cancelar creación?',
        content: 'Hay cambios sin guardar. ¿Estás seguro de que deseas salir?',
        confirmText: 'Sí, cancelar',
        cancelText: 'No, continuar editando',
      );
      return result ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: CustomAppBar(
          title: _isWarranty ? 'Nueva Garantía' : 'Nuevo Servicio',
          actions: [
            IconButton(
              icon: Icon(_isWarranty ? Icons.verified : Icons.home_repair_service),
              onPressed: null,
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
                    _buildWarrantyToggle(),
                    const SizedBox(height: 16),
                    if (_isWarranty) ...[
                      _buildWarrantySection(),
                      const SizedBox(height: 16),
                    ],
                    _buildSectionTitle('Información del Cliente'),
                    const SizedBox(height: 16),
                    _buildClientSection(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Información del Equipo'),
                    const SizedBox(height: 16),
                    _buildDeviceSection(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Asignación de Técnico'),
                    const SizedBox(height: 16),
                    _buildTechnicianSection(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const FullscreenLoadingIndicator(
                message: 'Creando servicio...',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarrantyToggle() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _isWarranty 
              ? AppTheme.warrantyServiceColor 
              : Colors.grey[300]!,
          width: _isWarranty ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SwitchListTile(
          title: const Text(
            '¿Es una garantía?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            _isWarranty
                ? 'Sí, este servicio corresponde a una garantía de un servicio anterior.'
                : 'No, este es un nuevo servicio regular.',
          ),
          value: _isWarranty,
          onChanged: (value) {
            setState(() {
              _isWarranty = value;
              if (!value) {
                _originalServiceId = null;
                _originalServiceIdController.clear();
              }
            });
          },
          activeColor: AppTheme.warrantyServiceColor,
          secondary: Icon(
            _isWarranty ? Icons.verified : Icons.new_releases,
            color: _isWarranty 
                ? AppTheme.warrantyServiceColor 
                : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildWarrantySection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppTheme.warrantyServiceColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Información de Garantía',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'ID del Servicio Original',
              hint: 'Ingrese el número de servicio original',
              controller: _originalServiceIdController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (_isWarranty) {
                  return Validators.validateRequired(value, fieldName: 'ID del servicio original');
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _originalServiceId = value.isNotEmpty ? int.tryParse(value) : null;
                });
              },
              prefixIcon: Icons.find_in_page,
              suffixIcon: Icons.search,
              onSuffixIconPressed: () {
                // Aquí se podría implementar una búsqueda de servicios
                // por ahora solo es un placeholder
                showInfoDialog(
                  context: context,
                  title: 'Buscar Servicio',
                  message: 'La funcionalidad de búsqueda de servicios será implementada en una versión futura.',
                );
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Nota: Al crear una garantía, se reutilizarán los datos del cliente y equipo del servicio original.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              label: 'Nombre del Cliente',
              hint: 'Ingrese el nombre completo',
              controller: _clientNameController,
              validator: (value) => Validators.validateRequired(value, fieldName: 'Nombre del cliente'),
              enabled: !_isWarranty,
              prefixIcon: Icons.person,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Teléfono',
              hint: 'Ingrese el número de teléfono (10 dígitos)',
              controller: _clientPhoneController,
              validator: (value) {
                final required = Validators.validateRequired(value, fieldName: 'Teléfono');
                if (required != null) return required;
                
                final phone = Validators.validatePhone(value);
                if (phone != null) return phone;
                
                return null;
              },
              enabled: !_isWarranty,
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Correo Electrónico (opcional)',
              hint: 'Ingrese el correo electrónico',
              controller: _clientEmailController,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  return Validators.validateEmail(value);
                }
                return null;
              },
              enabled: !_isWarranty,
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Dirección',
              hint: 'Ingrese la dirección completa',
              controller: _clientAddressController,
              validator: (value) => Validators.validateRequired(value, fieldName: 'Dirección'),
              enabled: !_isWarranty,
              prefixIcon: Icons.home,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            LocationDropdown(
              label: 'Ubicación',
              value: _selectedLocationId,
              onChanged: !_isWarranty 
                ? (value) {
                    setState(() {
                      _selectedLocationId = value;
                    });
                    _loadTechnicians();
                  }
                : null,
              validator: (value) {
                if (value == null) {
                  return 'Por favor seleccione una ubicación';
                }
                return null;
              },
              enabled: !_isWarranty,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              label: 'Tipo de Equipo',
              hint: 'Ej: Refrigerador, Lavadora, Televisor',
              controller: _deviceTypeController,
              validator: (value) => Validators.validateRequired(
                value, 
                fieldName: 'Tipo de equipo'
              ),
              enabled: !_isWarranty,
              prefixIcon: Icons.devices,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Marca del Equipo',
              hint: 'Ej: Samsung, LG, Whirlpool',
              controller: _deviceBrandController,
              validator: (value) => Validators.validateRequired(
                value, 
                fieldName: 'Marca del equipo'
              ),
              enabled: !_isWarranty,
              prefixIcon: Icons.branding_watermark,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            ServiceTypeDropdown(
              label: 'Tipo de Servicio',
              value: _selectedServiceType,
              onChanged: (value) {
                setState(() {
                  _selectedServiceType = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Por favor seleccione un tipo de servicio';
                }
                return null;
              },
              enabled: !_isWarranty,
            ),
            const SizedBox(height: 16),
            MessageTextField(
              label: 'Descripción del Problema',
              hint: 'Describa detalladamente la falla o el problema que presenta el equipo',
              controller: _issueDescriptionController,
              validator: (value) => Validators.validateRequired(
                value, 
                fieldName: 'Descripción del problema'
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicianSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Selecciona un Técnico',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (_isLoadingTechnicians)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                if (!_isLoadingTechnicians)
                  TextButton.icon(
                    onPressed: _loadTechnicians,
                    icon: const Icon(
                      Icons.refresh,
                      size: 16,
                    ),
                    label: const Text('Actualizar'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTechnicianDropdown(),
            const SizedBox(height: 16),
            if (_availableTechnicians.isEmpty && !_isLoadingTechnicians)
              const Text(
                'No hay técnicos disponibles en este momento.',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            if (_selectedTechnicianId != null)
              _buildSelectedTechnicianInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicianDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedTechnicianId,
      items: [
        const DropdownMenuItem<int>(
          value: null,
          child: Text('Sin técnico asignado'),
        ),
        ..._availableTechnicians.map((technician) {
          return DropdownMenuItem<int>(
            value: technician.id,
            child: Row(
              children: [
                Icon(
                  Icons.engineering,
                  size: 16,
                  color: technician.hasPendingWarranty
                      ? AppTheme.warrantyServiceColor
                      : AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${technician.name} (${technician.locationName})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          _selectedTechnicianId = value;
        });
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppTheme.dividerColor,
          ),
        ),
        hintText: 'Seleccionar técnico',
        prefixIcon: const Icon(Icons.engineering),
      ),
    );
  }

  Widget _buildSelectedTechnicianInfo() {
    // Buscar el técnico seleccionado
    final selectedTechnician = _availableTechnicians.firstWhere(
      (technician) => technician.id == _selectedTechnicianId,
      orElse: () => Technician(
        id: 0,
        userId: 0,
        name: 'Desconocido',
        locationId: 0,
        locationName: 'Desconocida',
        isAvailable: false,
        hasPendingWarranty: false,
        completionRate: 0,
        pendingServices: 0,
      ),
    );

    if (selectedTechnician.id == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selectedTechnician.hasPendingWarranty
              ? AppTheme.warrantyServiceColor.withOpacity(0.5)
              : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  selectedTechnician.name.isNotEmpty
                      ? selectedTechnician.name[0].toUpperCase()
                      : 'T',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedTechnician.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Ubicación: ${selectedTechnician.locationName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTechnicianStatItem(
                'Tasa',
                '${selectedTechnician.completionRate.toStringAsFixed(0)}%',
                Icons.star_rate,
                Colors.amber,
              ),
              _buildTechnicianStatItem(
                'Pendientes',
                '${selectedTechnician.pendingServices}',
                Icons.pending_actions,
                Colors.blue,
              ),
              if (selectedTechnician.hasPendingWarranty)
                _buildTechnicianStatItem(
                  'Garantías',
                  'Pendientes',
                  Icons.verified,
                  AppTheme.warrantyServiceColor,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _createService,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: _isWarranty ? AppTheme.warrantyServiceColor : AppTheme.primaryColor,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        _isWarranty ? 'CREAR GARANTÍA' : 'CREAR SERVICIO',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}