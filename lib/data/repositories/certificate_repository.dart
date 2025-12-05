import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/api_service.dart';
import '../models/certificate_model.dart';

class CertificateRepository {
  final ApiService _apiService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  CertificateRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Obtener todos los certificados del usuario
  Future<List<CertificateModel>> getMyCertificates() async {
    try {
      final response = await _apiService.get('/certificates/my-certificates');

      if (response.data['success']) {
        final certificates = (response.data['certificates'] as List)
            .map((cert) => CertificateModel.fromJson(cert))
            .toList();

        // Ordenar por fecha de emisión (más reciente primero)
        certificates.sort((a, b) => b.issuedDate.compareTo(a.issuedDate));

        return certificates;
      }

      return [];
    } catch (e) {
      throw Exception('Error al obtener certificados: $e');
    }
  }

  /// Obtener certificado específico
  Future<CertificateModel?> getCertificate(String certificateId) async {
    try {
      final response = await _apiService.get('/certificates/$certificateId');

      if (response.data['success']) {
        return CertificateModel.fromJson(response.data['certificate']);
      }

      return null;
    } catch (e) {
      throw Exception('Error al obtener certificado: $e');
    }
  }

  /// Verificar si se puede obtener certificado para un curso
  Future<CertificateRequirements> checkCertificateEligibility(String courseId) async {
    try {
      final response = await _apiService.get('/certificates/check-eligibility/$courseId');

      if (response.data['success']) {
        return CertificateRequirements.fromJson(response.data['requirements']);
      }

      throw Exception('No se pudo verificar elegibilidad');
    } catch (e) {
      throw Exception('Error al verificar elegibilidad: $e');
    }
  }

  /// Solicitar certificado para un curso completado
  Future<CertificateModel> requestCertificate(CertificateRequest request) async {
    try {
      final response = await _apiService.post(
        '/certificates/request',
        data: request.toJson(),
      );

      if (response.data['success']) {
        return CertificateModel.fromJson(response.data['certificate']);
      }

      throw Exception(response.data['error'] ?? 'Error al solicitar certificado');
    } catch (e) {
      throw Exception('Error al solicitar certificado: $e');
    }
  }

  /// Validar certificado por número
  Future<CertificateValidation> validateCertificate(String certificateNumber) async {
    try {
      final response = await _apiService.get(
        '/certificates/validate/$certificateNumber',
      );

      if (response.data['success']) {
        return CertificateValidation.fromJson(response.data['validation']);
      }

      return CertificateValidation(
        isValid: false,
        message: response.data['error'] ?? 'Certificado no válido',
        validatedAt: DateTime.now(),
      );
    } catch (e) {
      return CertificateValidation(
        isValid: false,
        message: 'Error al validar certificado',
        validatedAt: DateTime.now(),
      );
    }
  }

  /// Descargar certificado como PDF
  Future<File?> downloadCertificatePDF(String certificateId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/certificate_$certificateId.pdf';
      final file = File(filePath);

      // Si ya existe, devolverlo
      if (await file.exists()) {
        return file;
      }

      // Descargar el PDF
      final response = await _apiService.download(
        '/certificates/$certificateId/download',
        filePath,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Accept': 'application/pdf',
          },
        ),
      );

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.data);
        return file;
      }

      return null;
    } catch (e) {
      throw Exception('Error al descargar certificado: $e');
    }
  }

  /// Compartir certificado
  Future<void> shareCertificate(CertificateModel certificate) async {
    try {
      // Primero intentar descargar el PDF
      final pdfFile = await downloadCertificatePDF(certificate.id);

      final message = '''
¡He completado el curso "${certificate.courseName}"! 🎓

${certificate.achievementMessage}
Calificación Final: ${certificate.finalGrade.toStringAsFixed(1)}%
Fecha: ${certificate.formattedDate}

Verifica mi certificado en:
${certificate.shareUrl}

#EnfocadosEnDiosTV #CertificadoBíblico
      ''';

      if (pdfFile != null && await pdfFile.exists()) {
        // Compartir con el PDF adjunto
        await Share.shareXFiles(
          [XFile(pdfFile.path)],
          text: message,
        );
      } else {
        // Compartir solo el texto
        await Share.share(message);
      }

      // Registrar que se compartió
      await _apiService.post('/certificates/$certificate.id/shared');
    } catch (e) {
      // Si falla, compartir solo el enlace
      await Share.share(certificate.shareUrl);
    }
  }

  /// Obtener plantillas de certificados disponibles
  Future<List<CertificateTemplate>> getAvailableTemplates() async {
    try {
      final response = await _apiService.get('/certificates/templates');

      if (response.data['success']) {
        return (response.data['templates'] as List)
            .map((template) => CertificateTemplate.fromJson(template))
            .toList();
      }

      return [];
    } catch (e) {
      throw Exception('Error al obtener plantillas: $e');
    }
  }

  /// Generar vista previa del certificado
  Future<String> generateCertificatePreview({
    required String courseId,
    String? templateId,
  }) async {
    try {
      final response = await _apiService.post(
        '/certificates/preview',
        data: {
          'courseId': courseId,
          'templateId': templateId,
        },
      );

      if (response.data['success']) {
        return response.data['previewUrl'];
      }

      throw Exception('No se pudo generar vista previa');
    } catch (e) {
      throw Exception('Error al generar vista previa: $e');
    }
  }

  /// Obtener estadísticas de certificados
  Future<Map<String, dynamic>> getCertificateStats() async {
    try {
      final response = await _apiService.get('/certificates/stats');

      if (response.data['success']) {
        return response.data['stats'];
      }

      return {
        'total': 0,
        'byType': {},
        'byYear': {},
        'totalHours': 0,
        'averageGrade': 0.0,
      };
    } catch (e) {
      return {
        'total': 0,
        'byType': {},
        'byYear': {},
        'totalHours': 0,
        'averageGrade': 0.0,
      };
    }
  }

  /// Guardar certificado localmente para modo offline
  Future<void> cacheCertificate(CertificateModel certificate) async {
    try {
      final certificatesJson = await _secureStorage.read(key: 'cached_certificates') ?? '[]';
      final certificates = List<Map<String, dynamic>>.from(
        (certificatesJson as List).map((e) => Map<String, dynamic>.from(e)),
      );

      // Agregar o actualizar certificado
      final index = certificates.indexWhere((c) => c['id'] == certificate.id);
      if (index >= 0) {
        certificates[index] = certificate.toJson();
      } else {
        certificates.add(certificate.toJson());
      }

      await _secureStorage.write(
        key: 'cached_certificates',
        value: certificates.toString(),
      );
    } catch (e) {
      // Manejar error silenciosamente
    }
  }

  /// Obtener certificados desde caché local
  Future<List<CertificateModel>> getCachedCertificates() async {
    try {
      final certificatesJson = await _secureStorage.read(key: 'cached_certificates');

      if (certificatesJson != null && certificatesJson.isNotEmpty) {
        final certificates = List<Map<String, dynamic>>.from(
          (certificatesJson as List).map((e) => Map<String, dynamic>.from(e)),
        );

        return certificates
            .map((cert) => CertificateModel.fromJson(cert))
            .toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Limpiar caché de certificados
  Future<void> clearCertificateCache() async {
    try {
      await _secureStorage.delete(key: 'cached_certificates');

      // También limpiar PDFs descargados
      final dir = await getApplicationDocumentsDirectory();
      final files = dir.listSync();

      for (final file in files) {
        if (file.path.contains('certificate_') && file.path.endsWith('.pdf')) {
          await file.delete();
        }
      }
    } catch (e) {
      // Manejar error silenciosamente
    }
  }

  /// Reportar problema con certificado
  Future<bool> reportCertificateIssue({
    required String certificateId,
    required String issue,
    String? description,
  }) async {
    try {
      final response = await _apiService.post(
        '/certificates/$certificateId/report',
        data: {
          'issue': issue,
          'description': description,
        },
      );

      return response.data['success'] ?? false;
    } catch (e) {
      return false;
    }
  }
}