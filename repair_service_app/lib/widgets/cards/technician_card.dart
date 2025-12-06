import 'package:flutter/material.dart';
import 'package:repair_service_app/config/theme.dart';
import 'package:repair_service_app/models/technician.dart';
import 'package:repair_service_app/utils/formatters.dart';

class TechnicianCard extends StatelessWidget {
  final Technician technician;
  final VoidCallback? onTap;
  final VoidCallback? onAssign;
  final bool showAssignButton;
  final bool showRestrictionBadges;
  final bool showProgressBar;
  final bool compact;
  
  const TechnicianCard({
    Key? key,
    required this.technician,
    this.onTap,
    this.onAssign,
    this.showAssignButton = false,
    this.showRestrictionBadges = true,
    this.showProgressBar = true,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: !technician.isAvailable && showRestrictionBadges
            ? BorderSide(color: Colors.grey[400]!, width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: compact ? 8 : 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: compact
                    ? _buildCompactContent(context)
                    : _buildFullContent(context),
              ),
            ),
            if (showProgressBar && !compact) _buildProgressBar(context),
            if (showAssignButton) _buildAssignButton(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _getHeaderColor(),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              technician.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showRestrictionBadges) ...[
            if (technician.hasPendingWarranty)
              _buildBadge('Garantía Pendiente', AppTheme.warrantyServiceColor),
            if (!technician.isAvailable)
              _buildBadge('No Disponible', Colors.grey[600]!),
          ],
        ],
      ),
    );
  }
  
  Widget _buildBadge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
  
  List<Widget> _buildCompactContent(BuildContext context) {
    return [
      Row(
        children: [
          const Icon(
            Icons.location_on,
            size: 16,
            color: Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            technician.locationName,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          const Icon(
            Icons.home_repair_service,
            size: 16,
            color: Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            'Servicios pendientes: ${technician.pendingServices}',
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          const Icon(
            Icons.star_rate,
            size: 16,
            color: Colors.amber,
          ),
          const SizedBox(width: 8),
          Text(
            'Tasa completado: ${Formatters.formatPercentage(technician.completionRate)}',
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    ];
  }
  
  List<Widget> _buildFullContent(BuildContext context) {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      technician.locationName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.email,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        technician.email ?? 'No disponible',
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCompletionRateColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  Formatters.formatPercentage(technician.completionRate),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pago: ${Formatters.formatPercentage(technician.getPaymentPercentage())}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 8),
      const Divider(),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(
            context,
            Icons.pending_actions,
            'Pendientes',
            technician.pendingServices.toString(),
          ),
          _buildStatItem(
            context,
            Icons.payment,
            'Pagos',
            '${technician.getPaymentPercentage().toStringAsFixed(0)}%',
          ),
          if (technician.hasPendingWarranty)
            _buildStatItem(
              context,
              Icons.verified,
              'Garantías',
              'Pendiente',
              color: AppTheme.warrantyServiceColor,
            )
          else
            _buildStatItem(
              context,
              Icons.check_circle,
              'Garantías',
              'Al día',
              color: AppTheme.successColor,
            ),
        ],
      ),
    ];
  }
  
  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color ?? Colors.grey[700],
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }
  
  Widget _buildProgressBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tasa de finalización: ${Formatters.formatPercentage(technician.completionRate)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: technician.completionRate / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(_getCompletionRateColor()),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAssignButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: ButtonBar(
        buttonPadding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ElevatedButton.icon(
            onPressed: technician.isReadyForNewService ? onAssign : null,
            icon: const Icon(Icons.assignment_ind),
            label: const Text('Asignar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helpers para determinar colores
  
  Color _getHeaderColor() {
    if (!technician.isAvailable) {
      return Colors.grey[700]!;
    }
    
    if (technician.hasPendingWarranty) {
      return AppTheme.warrantyServiceColor;
    }
    
    return AppTheme.primaryColor;
  }
  
  Color _getCompletionRateColor() {
    if (technician.completionRate >= 90) {
      return AppTheme.successColor;
    } else if (technician.completionRate >= 80) {
      return Colors.blue;
    } else if (technician.completionRate >= 70) {
      return AppTheme.warningColor;
    } else {
      return AppTheme.errorColor;
    }
  }
}

// Variante para mostrar en una grilla
class TechnicianGridCard extends StatelessWidget {
  final Technician technician;
  final VoidCallback? onTap;
  final VoidCallback? onAssign;
  final bool showAssignButton;
  
  const TechnicianGridCard({
    Key? key,
    required this.technician,
    this.onTap,
    this.onAssign,
    this.showAssignButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar y estado
            Container(
              decoration: BoxDecoration(
                color: _getHeaderColor(),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 24,
                    child: Text(
                      technician.name.isNotEmpty ? technician.name[0].toUpperCase() : 'T',
                      style: TextStyle(
                        fontSize: 20,
                        color: _getHeaderColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          technician.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          technician.locationName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenido
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoItem(
                      Icons.star_rate,
                      'Tasa: ${Formatters.formatPercentage(technician.completionRate)}',
                      color: _getCompletionRateColor(),
                    ),
                    const SizedBox(height: 4),
                    _buildInfoItem(
                      Icons.pending_actions,
                      'Pendientes: ${technician.pendingServices}',
                    ),
                    const SizedBox(height: 4),
                    _buildInfoItem(
                      Icons.payments,
                      'Pago: ${Formatters.formatPercentage(technician.getPaymentPercentage())}',
                    ),
                    if (technician.hasPendingWarranty) ...[
                      const SizedBox(height: 4),
                      _buildInfoItem(
                        Icons.verified,
                        'Garantía pendiente',
                        color: AppTheme.warrantyServiceColor,
                      ),
                    ],
                    if (!technician.isAvailable) ...[
                      const SizedBox(height: 4),
                      _buildInfoItem(
                        Icons.do_not_disturb,
                        'No disponible',
                        color: Colors.grey[600],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Botón asignar
            if (showAssignButton)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: ElevatedButton(
                  onPressed: technician.isReadyForNewService ? onAssign : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Asignar'),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color ?? Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color ?? Colors.grey[800],
              fontWeight: color != null ? FontWeight.bold : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  // Helpers para determinar colores - misma lógica que en TechnicianCard
  
  Color _getHeaderColor() {
    if (!technician.isAvailable) {
      return Colors.grey[700]!;
    }
    
    if (technician.hasPendingWarranty) {
      return AppTheme.warrantyServiceColor;
    }
    
    return AppTheme.primaryColor;
  }
  
  Color _getCompletionRateColor() {
    if (technician.completionRate >= 90) {
      return AppTheme.successColor;
    } else if (technician.completionRate >= 80) {
      return Colors.blue;
    } else if (technician.completionRate >= 70) {
      return AppTheme.warningColor;
    } else {
      return AppTheme.errorColor;
    }
  }
}