import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../data/models/certificate_model.dart';
import '../../providers/certificate_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';

class MyCertificatesScreen extends ConsumerStatefulWidget {
  const MyCertificatesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MyCertificatesScreen> createState() => _MyCertificatesScreenState();
}

class _MyCertificatesScreenState extends ConsumerState<MyCertificatesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CertificateType? _selectedType;
  int? _selectedYear;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final certificatesAsync = ref.watch(userCertificatesProvider);
    final statsAsync = ref.watch(certificateStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Certificados'),
        backgroundColor: const Color(0xFFCC0000),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD700),
          tabs: const [
            Tab(text: 'CERTIFICADOS'),
            Tab(text: 'ESTADÍSTICAS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab de Certificados
          certificatesAsync.when(
            data: (certificates) {
              if (certificates.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.workspace_premium,
                  title: 'Sin certificados aún',
                  message: 'Completa cursos para obtener certificados',
                  actionLabel: 'Explorar Cursos',
                  onAction: () => context.push('/academy'),
                );
              }

              final filteredCertificates = _filterCertificates(certificates);

              return Column(
                children: [
                  // Filtros
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[100],
                    child: Row(
                      children: [
                        // Filtro por tipo
                        Expanded(
                          child: DropdownButtonFormField<CertificateType?>(
                            value: _selectedType,
                            decoration: InputDecoration(
                              labelText: 'Tipo',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Todos'),
                              ),
                              ...CertificateType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(_getTypeLabel(type)),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedType = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Filtro por año
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            value: _selectedYear,
                            decoration: InputDecoration(
                              labelText: 'Año',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Todos'),
                              ),
                              ..._getAvailableYears(certificates).map((year) {
                                return DropdownMenuItem(
                                  value: year,
                                  child: Text(year.toString()),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedYear = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Lista de certificados
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await ref.read(userCertificatesProvider.notifier)
                            .loadCertificates();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredCertificates.length,
                        itemBuilder: (context, index) {
                          final certificate = filteredCertificates[index];
                          return _buildCertificateCard(certificate);
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: LoadingWidget()),
            error: (error, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Error al cargar certificados'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(userCertificatesProvider.notifier)
                          .loadCertificates();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),

          // Tab de Estadísticas
          statsAsync.when(
            data: (stats) => _buildStatisticsTab(stats),
            loading: () => const Center(child: LoadingWidget()),
            error: (_, __) => const Center(
              child: Text('Error al cargar estadísticas'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateCard(CertificateModel certificate) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => context.push('/certificate/${certificate.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Badge/Icono
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Color(
                    int.parse(certificate.certificateColor.replaceAll('#', '0xFF')),
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: certificate.badgeUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: certificate.badgeUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Icon(
                            Icons.workspace_premium,
                            size: 40,
                            color: Color(
                              int.parse(certificate.certificateColor.replaceAll('#', '0xFF')),
                            ),
                          ),
                        ),
                      )
                    : Icon(
                        Icons.workspace_premium,
                        size: 40,
                        color: Color(
                          int.parse(certificate.certificateColor.replaceAll('#', '0xFF')),
                        ),
                      ),
              ),
              const SizedBox(width: 16),

              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      certificate.courseName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Color(
                          int.parse(certificate.certificateColor.replaceAll('#', '0xFF')),
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        certificate.achievementMessage,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(
                            int.parse(certificate.certificateColor.replaceAll('#', '0xFF')),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          certificate.formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.grade,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Calificación: ${certificate.finalGrade.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${certificate.completionHours} horas',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Botón de acción
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () => context.push('/certificate/${certificate.id}'),
                    color: const Color(0xFFCC0000),
                    tooltip: 'Ver certificado',
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () => _shareCertificate(certificate),
                    color: Colors.grey[600],
                    tooltip: 'Compartir',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsTab(Map<String, dynamic> stats) {
    final totalCertificates = stats['total'] ?? 0;
    final totalHours = stats['totalHours'] ?? 0;
    final averageGrade = stats['averageGrade'] ?? 0.0;
    final byType = stats['byType'] ?? {};
    final byYear = stats['byYear'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen general
          Row(
            children: [
              _buildStatCard(
                icon: Icons.workspace_premium,
                label: 'Total Certificados',
                value: totalCertificates.toString(),
                color: const Color(0xFFCC0000),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                icon: Icons.access_time,
                label: 'Horas Totales',
                value: totalHours.toString(),
                color: const Color(0xFFFFD700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            icon: Icons.grade,
            label: 'Promedio General',
            value: '${averageGrade.toStringAsFixed(1)}%',
            color: Colors.green,
            isFullWidth: true,
          ),

          const SizedBox(height: 32),

          // Certificados por tipo
          if (byType.isNotEmpty) ...[
            Text(
              'Por Tipo de Certificado',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...byType.entries.map((entry) {
              final type = _parseTypeFromString(entry.key);
              final count = entry.value ?? 0;
              final percentage = totalCertificates > 0
                  ? (count / totalCertificates * 100).toStringAsFixed(1)
                  : '0.0';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 120,
                      child: Text(
                        _getTypeLabel(type),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: count / totalCertificates,
                            child: Container(
                              height: 30,
                              decoration: BoxDecoration(
                                color: _getTypeColor(type),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Center(
                              child: Text(
                                '$count ($percentage%)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 32),

          // Certificados por año
          if (byYear.isNotEmpty) ...[
            Text(
              'Por Año',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              child: _buildYearChart(byYear),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isFullWidth = false,
  }) {
    return Expanded(
      flex: isFullWidth ? 2 : 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearChart(Map<String, dynamic> byYear) {
    final years = byYear.keys.toList()..sort();
    final maxCount = byYear.values.reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: years.map((year) {
        final count = byYear[year] ?? 0;
        final height = maxCount > 0 ? (count / maxCount) * 150 : 0.0;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 40,
              height: height,
              decoration: BoxDecoration(
                color: const Color(0xFFCC0000),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              year,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  List<CertificateModel> _filterCertificates(List<CertificateModel> certificates) {
    var filtered = certificates;

    if (_selectedType != null) {
      filtered = filtered.where((cert) => cert.type == _selectedType).toList();
    }

    if (_selectedYear != null) {
      filtered = filtered.where((cert) =>
        cert.issuedDate.year == _selectedYear
      ).toList();
    }

    return filtered;
  }

  List<int> _getAvailableYears(List<CertificateModel> certificates) {
    final years = certificates
        .map((cert) => cert.issuedDate.year)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return years;
  }

  String _getTypeLabel(CertificateType type) {
    switch (type) {
      case CertificateType.excellence:
        return 'Excelencia';
      case CertificateType.distinction:
        return 'Distinción';
      case CertificateType.honor:
        return 'Honor';
      case CertificateType.completion:
        return 'Completado';
      case CertificateType.participation:
        return 'Participación';
    }
  }

  Color _getTypeColor(CertificateType type) {
    switch (type) {
      case CertificateType.excellence:
        return const Color(0xFFFFD700); // Oro
      case CertificateType.distinction:
        return const Color(0xFFC0C0C0); // Plata
      case CertificateType.honor:
        return const Color(0xFFCD7F32); // Bronce
      case CertificateType.completion:
        return const Color(0xFFCC0000); // Rojo
      case CertificateType.participation:
        return Colors.blue;
    }
  }

  CertificateType _parseTypeFromString(String typeStr) {
    return CertificateType.values.firstWhere(
      (type) => type.toString().split('.').last == typeStr,
      orElse: () => CertificateType.completion,
    );
  }

  Future<void> _shareCertificate(CertificateModel certificate) async {
    try {
      await ref.read(certificateShareProvider.notifier)
          .shareCertificate(certificate);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al compartir: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}