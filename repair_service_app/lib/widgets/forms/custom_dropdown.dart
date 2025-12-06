import 'package:flutter/material.dart';
import 'package:repair_service_app/config/theme.dart';

class CustomDropdown<T> extends StatefulWidget {
  final String label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final bool enabled;
  final AutovalidateMode autovalidateMode;
  final Widget? prefix;
  final IconData? prefixIcon;
  final bool isExpanded;
  final bool isDense;
  final Color? dropdownColor;
  final EdgeInsetsGeometry? contentPadding;
  
  const CustomDropdown({
    Key? key,
    required this.label,
    this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.enabled = true,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.prefix,
    this.prefixIcon,
    this.isExpanded = true,
    this.isDense = false,
    this.dropdownColor,
    this.contentPadding,
  }) : super(key: key);

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>> {
  late FocusNode _focusNode;
  bool _hasFocus = false;
  
  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }
  
  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }
  
  void _handleFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: widget.enabled ? AppTheme.textPrimaryColor : Colors.grey,
            ),
          ),
        ),
        DropdownButtonFormField<T>(
          value: widget.value,
          items: widget.items,
          onChanged: widget.enabled ? widget.onChanged : null,
          validator: widget.validator,
          focusNode: _focusNode,
          autovalidateMode: widget.autovalidateMode,
          isExpanded: widget.isExpanded,
          isDense: widget.isDense,
          dropdownColor: widget.dropdownColor ?? Colors.white,
          icon: const Icon(Icons.arrow_drop_down),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon)
                : widget.prefix,
            filled: true,
            fillColor: widget.enabled ? Colors.white : Colors.grey[100],
            contentPadding: widget.contentPadding ?? const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _hasFocus ? AppTheme.primaryColor : AppTheme.dividerColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppTheme.errorColor,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppTheme.errorColor,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Dropdown específico para seleccionar ubicaciones
class LocationDropdown extends StatelessWidget {
  final String label;
  final int? value;
  final void Function(int?)? onChanged;
  final String? Function(int?)? validator;
  final bool enabled;
  
  const LocationDropdown({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.validator,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Lista de ubicaciones predefinidas
    final locations = [
      {'id': 1, 'name': 'CDMX'},
      {'id': 2, 'name': 'Estado de México'},
      {'id': 3, 'name': 'Monterrey'},
      {'id': 4, 'name': 'Guadalajara'},
      {'id': 5, 'name': 'Querétaro'},
      {'id': 6, 'name': 'Veracruz'},
      {'id': 7, 'name': 'Puebla'},
      {'id': 8, 'name': 'Cancún'},
      {'id': 9, 'name': 'Baja California Sur'},
      {'id': 10, 'name': 'Indefinido'},
    ];
    
    return CustomDropdown<int>(
      label: label,
      hint: 'Seleccionar ubicación',
      value: value,
      items: locations.map((location) {
        return DropdownMenuItem<int>(
          value: location['id'] as int,
          child: Text(location['name'] as String),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      enabled: enabled,
      prefixIcon: Icons.location_on,
    );
  }
}

// Dropdown específico para seleccionar tipo de servicio
class ServiceTypeDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final void Function(String?)? onChanged;
  final String? Function(String?)? validator;
  final bool enabled;
  
  const ServiceTypeDropdown({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.validator,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Tipos de servicio
    final serviceTypes = [
      {'id': 'repair', 'name': 'Reparación', 'icon': Icons.build},
      {'id': 'maintenance', 'name': 'Mantenimiento', 'icon': Icons.settings},
    ];
    
    return CustomDropdown<String>(
      label: label,
      hint: 'Seleccionar tipo de servicio',
      value: value,
      items: serviceTypes.map((type) {
        return DropdownMenuItem<String>(
          value: type['id'] as String,
          child: Row(
            children: [
              Icon(
                type['icon'] as IconData,
                size: 18,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(type['name'] as String),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      enabled: enabled,
      prefixIcon: Icons.home_repair_service,
    );
  }
}

// Dropdown específico para seleccionar estado de servicio
class ServiceStatusDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final void Function(String?)? onChanged;
  final String? Function(String?)? validator;
  final bool enabled;
  final List<String>? allowedStatuses;
  
  const ServiceStatusDropdown({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.validator,
    this.enabled = true,
    this.allowedStatuses,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Estados de servicio disponibles
    final allStatuses = [
      {'id': 'new', 'name': 'Nuevo'},
      {'id': 'assigned', 'name': 'Asignado'},
      {'id': 'in_progress', 'name': 'En progreso'},
      {'id': 'completed', 'name': 'Completado'},
      {'id': 'cancelled', 'name': 'Cancelado'},
    ];
    
    // Filtrar estados según los permitidos
    final serviceStatuses = allowedStatuses != null
        ? allStatuses.where((status) => allowedStatuses!.contains(status['id'])).toList()
        : allStatuses;
    
    return CustomDropdown<String>(
      label: label,
      hint: 'Seleccionar estado',
      value: value,
      items: serviceStatuses.map((status) {
        return DropdownMenuItem<String>(
          value: status['id'] as String,
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getStatusColor(status['id'] as String),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(status['name'] as String),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      enabled: enabled,
      prefixIcon: Icons.flag,
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
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
        return AppTheme.infoColor;
    }
  }
}