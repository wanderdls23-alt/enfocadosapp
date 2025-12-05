import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../../data/models/certificate_model.dart';
import '../../providers/certificate_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';

class CertificateViewerScreen extends ConsumerStatefulWidget {
  final String certificateId;

  const CertificateViewerScreen({
    Key? key,
    required this.certificateId,
  }) : super(key: key);

  @override
  ConsumerState<CertificateViewerScreen> createState() =>
      _CertificateViewerScreenState();
}

class _CertificateViewerScreenState extends ConsumerState<CertificateViewerScreen>
    with SingleTickerProviderStateMixin {
  final ScreenshotController _screenshotController = ScreenshotController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isPortrait = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _animationController.forward();

    // Permitir orientación horizontal para mejor visualización
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _animationController.dispose();
    // Restaurar orientación vertical
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final certificateAsync = ref.watch(
      certificateDetailProvider(widget.certificateId),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          certificateAsync.when(
            data: (certificate) => certificate != null
                ? Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.download, color: Colors.white),
                        onPressed: () => _downloadCertificate(certificate),
                        tooltip: 'Descargar',
                      ),
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.white),
                        onPressed: () => _shareCertificate(certificate),
                        tooltip: 'Compartir',
                      ),
                    ],
                  )
                : const SizedBox(),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: certificateAsync.when(
        data: (certificate) {
          if (certificate == null) {
            return const Center(
              child: Text(
                'Certificado no encontrado',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return OrientationBuilder(
            builder: (context, orientation) {
              _isPortrait = orientation == Orientation.portrait;
              return AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Screenshot(
                            controller: _screenshotController,
                            child: _buildCertificate(certificate),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: LoadingWidget()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar certificado',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(certificateDetailProvider(widget.certificateId));
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCertificate(CertificateModel certificate) {
    final size = MediaQuery.of(context).size;
    final certificateWidth = _isPortrait
        ? size.width - 40
        : size.height - 40;
    final certificateHeight = certificateWidth * 0.7; // Proporción 10:7

    return Container(
      width: certificateWidth,
      height: certificateHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Fondo decorativo
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CustomPaint(
                painter: CertificateBackgroundPainter(
                  primaryColor: Color(int.parse(
                    certificate.certificateColor.replaceAll('#', '0xFF'),
                  )),
                ),
              ),
            ),
          ),

          // Contenido del certificado
          Padding(
            padding: EdgeInsets.all(certificateWidth * 0.08),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                if (certificate.badgeUrl != null)
                  CachedNetworkImage(
                    imageUrl: certificate.badgeUrl!,
                    height: certificateHeight * 0.15,
                    errorWidget: (_, __, ___) => Image.asset(
                      'assets/images/logo.png',
                      height: certificateHeight * 0.15,
                    ),
                  )
                else
                  Image.asset(
                    'assets/images/logo.png',
                    height: certificateHeight * 0.15,
                  ),

                SizedBox(height: certificateHeight * 0.05),

                // Título
                Text(
                  'CERTIFICADO',
                  style: TextStyle(
                    fontSize: certificateHeight * 0.08,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 4,
                    color: Colors.black87,
                  ),
                ),

                Text(
                  certificate.achievementMessage.toUpperCase(),
                  style: TextStyle(
                    fontSize: certificateHeight * 0.04,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Color(int.parse(
                      certificate.certificateColor.replaceAll('#', '0xFF'),
                    )),
                  ),
                ),

                SizedBox(height: certificateHeight * 0.06),

                // Otorgado a
                Text(
                  'Otorgado a',
                  style: TextStyle(
                    fontSize: certificateHeight * 0.03,
                    color: Colors.black54,
                  ),
                ),

                SizedBox(height: certificateHeight * 0.02),

                // Nombre del estudiante
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: certificateWidth * 0.1,
                    vertical: certificateHeight * 0.01,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Color(int.parse(
                          certificate.certificateColor.replaceAll('#', '0xFF'),
                        )),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    certificate.studentName,
                    style: TextStyle(
                      fontSize: certificateHeight * 0.06,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: certificateHeight * 0.04),

                // Por completar
                Text(
                  'Por completar exitosamente el curso',
                  style: TextStyle(
                    fontSize: certificateHeight * 0.025,
                    color: Colors.black54,
                  ),
                ),

                SizedBox(height: certificateHeight * 0.02),

                // Nombre del curso
                Text(
                  certificate.courseName,
                  style: TextStyle(
                    fontSize: certificateHeight * 0.035,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),

                SizedBox(height: certificateHeight * 0.03),

                // Detalles
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDetail(
                      'Calificación Final',
                      '${certificate.finalGrade.toStringAsFixed(1)}%',
                      certificateHeight,
                    ),
                    SizedBox(width: certificateWidth * 0.08),
                    _buildDetail(
                      'Horas Completadas',
                      certificate.completionHours.toString(),
                      certificateHeight,
                    ),
                  ],
                ),

                SizedBox(height: certificateHeight * 0.04),

                // Fecha
                Text(
                  certificate.formattedDate,
                  style: TextStyle(
                    fontSize: certificateHeight * 0.025,
                    color: Colors.black54,
                  ),
                ),

                const Spacer(),

                // Firma y código QR
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Firma
                    Column(
                      children: [
                        if (certificate.signatureUrl != null)
                          CachedNetworkImage(
                            imageUrl: certificate.signatureUrl!,
                            height: certificateHeight * 0.08,
                            errorWidget: (_, __, ___) => Container(
                              width: certificateWidth * 0.25,
                              height: 1,
                              color: Colors.black54,
                            ),
                          )
                        else
                          Container(
                            width: certificateWidth * 0.25,
                            height: 1,
                            color: Colors.black54,
                          ),
                        const SizedBox(height: 4),
                        Text(
                          certificate.instructorName ?? 'Director',
                          style: TextStyle(
                            fontSize: certificateHeight * 0.02,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (certificate.instructorTitle != null)
                          Text(
                            certificate.instructorTitle!,
                            style: TextStyle(
                              fontSize: certificateHeight * 0.018,
                              color: Colors.black54,
                            ),
                          ),
                      ],
                    ),

                    // Código QR
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: QrImageView(
                            data: certificate.verificationUrl ?? certificate.shareUrl,
                            version: QrVersions.auto,
                            size: certificateHeight * 0.12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'N° ${certificate.certificateNumber}',
                          style: TextStyle(
                            fontSize: certificateHeight * 0.015,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(String label, String value, double certificateHeight) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: certificateHeight * 0.04,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFCC0000),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: certificateHeight * 0.02,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Future<void> _downloadCertificate(CertificateModel certificate) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Capturar imagen del certificado
      final Uint8List? image = await _screenshotController.capture(
        delay: const Duration(milliseconds: 100),
        pixelRatio: 3.0,
      );

      if (image != null) {
        // Guardar en galería
        final result = await ImageGallerySaver.saveImage(
          image,
          quality: 100,
          name: 'certificate_${certificate.certificateNumber}',
        );

        Navigator.pop(context); // Cerrar diálogo de carga

        if (result['isSuccess']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Certificado guardado en la galería'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context); // Cerrar diálogo de carga
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareCertificate(CertificateModel certificate) async {
    try {
      await ref.read(certificateShareProvider.notifier).shareCertificate(certificate);
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

// Painter personalizado para el fondo del certificado
class CertificateBackgroundPainter extends CustomPainter {
  final Color primaryColor;

  CertificateBackgroundPainter({required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Fondo blanco
    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Patrón decorativo en las esquinas
    paint.color = primaryColor.withOpacity(0.1);
    paint.style = PaintingStyle.fill;

    // Esquina superior izquierda
    final path1 = Path();
    path1.moveTo(0, 0);
    path1.lineTo(size.width * 0.2, 0);
    path1.quadraticBezierTo(
      size.width * 0.1,
      size.height * 0.05,
      0,
      size.height * 0.15,
    );
    path1.close();
    canvas.drawPath(path1, paint);

    // Esquina superior derecha
    final path2 = Path();
    path2.moveTo(size.width * 0.8, 0);
    path2.lineTo(size.width, 0);
    path2.lineTo(size.width, size.height * 0.15);
    path2.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.05,
      size.width * 0.8,
      0,
    );
    path2.close();
    canvas.drawPath(path2, paint);

    // Esquina inferior izquierda
    final path3 = Path();
    path3.moveTo(0, size.height * 0.85);
    path3.quadraticBezierTo(
      size.width * 0.1,
      size.height * 0.95,
      size.width * 0.2,
      size.height,
    );
    path3.lineTo(0, size.height);
    path3.close();
    canvas.drawPath(path3, paint);

    // Esquina inferior derecha
    final path4 = Path();
    path4.moveTo(size.width * 0.8, size.height);
    path4.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.95,
      size.width,
      size.height * 0.85,
    );
    path4.lineTo(size.width, size.height);
    path4.close();
    canvas.drawPath(path4, paint);

    // Borde decorativo
    paint.color = primaryColor.withOpacity(0.3);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;

    final borderRect = Rect.fromLTWH(
      size.width * 0.02,
      size.height * 0.02,
      size.width * 0.96,
      size.height * 0.96,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(borderRect, const Radius.circular(16)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}