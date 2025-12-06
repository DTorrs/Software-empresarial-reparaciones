import 'package:flutter/material.dart';
import 'package:repair_service_app/config/theme.dart';
import 'package:repair_service_app/models/payment.dart';
import 'package:repair_service_app/utils/formatters.dart';
import 'package:repair_service_app/utils/extensions.dart';

class PaymentCard extends StatelessWidget {
  final Payment payment;
  final VoidCallback? onTap;
  final bool compact;
  final bool showTechnician;
  
  const PaymentCard({
    Key? key,
    required this.payment,
    this.onTap,
    this.compact = false,
    this.showTechnician = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: payment.isWarranty ?? false
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
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
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
              "Pago Servicio #${payment.serviceId}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              Formatters.formatCurrency(payment.paymentAmount),
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
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
            _getDeviceIcon(),
            size: 16,
            color: Colors.grey[700],
          ),
          const SizedBox(width: 8),
          Text(
            '${payment.deviceType ?? ''} ${payment.deviceBrand ?? ''}',
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
              payment.clientName ?? 'Cliente',
              style: const TextStyle(
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.payments,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                '${Formatters.formatPercentage(payment.appliedPercentage)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            Formatters.formatShortDate(payment.calculationDate),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
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
                if (payment.deviceType != null && payment.deviceBrand != null)
                  Row(
                    children: [
                      Icon(
                        _getDeviceIcon(),
                        size: 18,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${payment.deviceType} ${payment.deviceBrand}',
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
                if (payment.clientName != null)
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
                          payment.clientName!,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                if (showTechnician && payment.technicianName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.engineering,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        payment.technicianName!,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  Formatters.formatPercentage(payment.appliedPercentage),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                Formatters.formatShortDate(payment.calculationDate),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 12),
      const Divider(height: 1),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(
            context,
            'Precio servicio',
            Formatters.formatCurrency(payment.servicePrice),
          ),
          _buildStatItem(
            context,
            'Porcentaje',
            '${payment.appliedPercentage.toStringAsFixed(0)}%',
          ),
          _buildStatItem(
            context,
            'Pago',
            Formatters.formatCurrency(payment.paymentAmount),
            highlightValue: true,
          ),
        ],
      ),
      if (payment.isWarranty != null && payment.isWarranty!) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.warrantyServiceColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.warrantyServiceColor,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified,
                color: AppTheme.warrantyServiceColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text(
                'Servicio de garantía',
                style: TextStyle(
                  color: AppTheme.warrantyServiceColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
      if (payment.completedDate != null) ...[
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 16,
              color: Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              'Completado: ${Formatters.formatShortDate(payment.completedDate!)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    ];
  }
  
  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value, {
    bool highlightValue = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: highlightValue ? AppTheme.primaryColor : Colors.black87,
          ),
        ),
      ],
    );
  }
  
  IconData _getDeviceIcon() {
    if (payment.deviceType == null) return Icons.devices;
    
    final type = payment.deviceType!.toLowerCase();
    
    if (type.contains('refrigerador') || type.contains('nevera')) {
      return Icons.kitchen;
    } else if (type.contains('lavadora')) {
      return Icons.local_laundry_service;
    } else if (type.contains('televisor') || type.contains('tv')) {
      return Icons.tv;
    } else if (type.contains('estufa') || type.contains('horno')) {
      return Icons.microwave;
    } else if (type.contains('aire acondicionado')) {
      return Icons.ac_unit;
    } else if (type.contains('computadora') || type.contains('laptop')) {
      return Icons.computer;
    } else if (type.contains('celular') || type.contains('teléfono')) {
      return Icons.smartphone;
    }
    
    return Icons.devices;
  }
}

// Widget para mostrar un resumen de pagos
class PaymentSummaryCard extends StatelessWidget {
  final PaymentSummary summary;
  final VoidCallback? onTap;
  final String title;
  final Color? color;
  
  const PaymentSummaryCard({
    Key? key,
    required this.summary,
    this.onTap,
    this.title = 'Resumen de Pagos',
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AppTheme.primaryColor;
    
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${summary.totalServices} servicios',
                      style: TextStyle(
                        color: cardColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryStats(context, cardColor),
                  const SizedBox(height: 16),
                  _buildDateRange(context),
                  if (summary.recentPaymentAmount != null && summary.recentServices != null) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    _buildRecentActivity(context, cardColor),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryStats(BuildContext context, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildStatBox(
            context,
            'Total Servicios',
            Formatters.formatCurrency(summary.totalServiceValue),
            Icons.attach_money,
            color.withOpacity(0.8),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox(
            context,
            'Total Pagos',
            Formatters.formatCurrency(summary.totalPaymentAmount),
            Icons.payments,
            color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox(
            context,
            'Promedio',
            '${summary.averagePercentage.toStringAsFixed(1)}%',
            Icons.percent,
            color.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatBox(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDateRange(BuildContext context) {
    String dateRange = 'Sin datos de fechas';
    
    if (summary.firstPaymentDate != null && summary.lastPaymentDate != null) {
      final firstDate = Formatters.formatShortDate(summary.firstPaymentDate!);
      final lastDate = Formatters.formatShortDate(summary.lastPaymentDate!);
      
      if (firstDate == lastDate) {
        dateRange = 'Fecha: $firstDate';
      } else {
        dateRange = 'Periodo: $firstDate - $lastDate';
      }
    }
    
    return Row(
      children: [
        const Icon(
          Icons.date_range,
          size: 16,
          color: Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          dateRange,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
  
  Widget _buildRecentActivity(BuildContext context, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actividad reciente (30 días)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildRecentStat(
              context,
              'Servicios',
              '${summary.recentServices}',
              Icons.assignment,
              color.withOpacity(0.7),
            ),
            _buildRecentStat(
              context,
              'Pagos',
              Formatters.formatCurrency(summary.recentPaymentAmount ?? 0),
              Icons.payments,
              color,
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildRecentStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.8),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}