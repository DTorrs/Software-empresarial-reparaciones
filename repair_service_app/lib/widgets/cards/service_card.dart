import 'package:flutter/material.dart';
import 'package:repair_service_app/config/theme.dart';
import 'package:repair_service_app/models/service.dart';
import 'package:repair_service_app/utils/formatters.dart';
import 'package:repair_service_app/utils/extensions.dart';

class ServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool showAcceptButton;
  final bool showWarrantyBadge;
  final bool showLocation;
  final bool compact;
  
  const ServiceCard({
    Key? key,
    required this.service,
    this.onTap,
    this.onAccept,
    this.onReject,
    this.showAcceptButton = false,
    this.showWarrantyBadge = true,
    this.showLocation = true,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: service.isWarranty && showWarrantyBadge
            ? const BorderSide(color: AppTheme.warrantyServiceColor, width: 2)
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
            if (showAcceptButton || onReject != null) _buildButtons(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: service.status.serviceStatusColor,
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
              "Servicio #${service.id}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
          if (service.isWarranty && showWarrantyBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified,
                    color: AppTheme.warrantyServiceColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Garantía',
                    style: TextStyle(
                      color: AppTheme.warrantyServiceColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          if (!service.isWarranty || !showWarrantyBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                service.status.formattedServiceStatus,
                style: TextStyle(
                  color: service.status.serviceStatusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  List<Widget> _buildCompactContent(BuildContext context) {
    return [
      Row(
        children: [
          Icon(
            service.serviceType.serviceTypeIcon,
            size: 16,
            color: Colors.grey[700],
          ),
          const SizedBox(width: 8),
          Text(
            '${service.deviceType} ${service.deviceBrand}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          const Icon(
            Icons.person,
            size: 16,
            color: Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              service.clientName,
              style: const TextStyle(
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      if (showLocation && service.clientLocationName != null) ...[
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.location_on,
              size: 16,
              color: Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              service.clientLocationName!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
      if (service.assignedDate != null) ...[
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 16,
              color: Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              'Asignado: ${Formatters.formatShortDate(service.assignedDate!)}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    ];
  }
  
  List<Widget> _buildFullContent(BuildContext context) {
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      service.serviceType.serviceTypeIcon,
                      size: 18,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${service.deviceType} ${service.deviceBrand}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        service.clientName,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (showLocation && service.clientLocationName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        service.clientLocationName!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (service.estimatedPrice != null) ...[
                Text(
                  'Est: ${Formatters.formatCurrency(service.estimatedPrice!)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (service.finalPrice != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Final: ${Formatters.formatCurrency(service.finalPrice!)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'Problema: ${service.issueDescription}',
        style: const TextStyle(
          fontSize: 14,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Tipo: ${service.serviceType == 'repair' ? 'Reparación' : 'Mantenimiento'}',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          if (service.assignedDate != null)
            Text(
              'Asignado: ${Formatters.formatShortDate(service.assignedDate!)}',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
        ],
      ),
      if (service.technicianName != null) ...[
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.engineering,
              size: 16,
              color: Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              'Técnico: ${service.technicianName}',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    ];
  }
  
  Widget _buildButtons(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: ButtonBar(
        buttonPadding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (onReject != null)
            TextButton.icon(
              onPressed: onReject,
              icon: const Icon(Icons.close, color: AppTheme.errorColor),
              label: const Text(
                'Rechazar',
                style: TextStyle(color: AppTheme.errorColor),
              ),
            ),
          if (showAcceptButton)
            ElevatedButton.icon(
              onPressed: onAccept,
              icon: const Icon(Icons.check),
              label: const Text('Aceptar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

// Variante para mostrar como una grilla
class ServiceGridCard extends StatelessWidget {
  final Service service;
  final VoidCallback? onTap;
  
  const ServiceGridCard({
    Key? key,
    required this.service,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: service.isWarranty
            ? const BorderSide(color: AppTheme.warrantyServiceColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: service.status.serviceStatusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "#${service.id}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      service.status.formattedServiceStatus,
                      style: TextStyle(
                        color: service.status.serviceStatusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${service.deviceType}\n${service.deviceBrand}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        service.issueDescription,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.clientName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (service.estimatedPrice != null)
                    Text(
                      Formatters.formatCurrency(service.estimatedPrice!),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    )
                  else
                    const Text(
                      'Sin presupuesto',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  if (service.isWarranty)
                    const Row(
                      children: [
                        Icon(
                          Icons.verified,
                          color: AppTheme.warrantyServiceColor,
                          size: 14,
                        ),
                        SizedBox(width: 2),
                        Text(
                          'Garantía',
                          style: TextStyle(
                            color: AppTheme.warrantyServiceColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}