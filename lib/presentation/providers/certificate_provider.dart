import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/certificate_model.dart';
import '../../data/repositories/certificate_repository.dart';

/// Provider del repositorio de certificados
final certificateRepositoryProvider = Provider<CertificateRepository>((ref) {
  return CertificateRepository();
});

/// Provider de certificados del usuario
final userCertificatesProvider = StateNotifierProvider<UserCertificatesNotifier, AsyncValue<List<CertificateModel>>>((ref) {
  return UserCertificatesNotifier(ref);
});

/// Notifier para los certificados del usuario
class UserCertificatesNotifier extends StateNotifier<AsyncValue<List<CertificateModel>>> {
  final Ref _ref;
  late final CertificateRepository _repository;

  UserCertificatesNotifier(this._ref) : super(const AsyncValue.loading()) {
    _repository = _ref.read(certificateRepositoryProvider);
    loadCertificates();
  }

  /// Cargar certificados del usuario
  Future<void> loadCertificates() async {
    state = const AsyncValue.loading();

    try {
      // Intentar cargar desde el servidor
      final certificates = await _repository.getMyCertificates();
      state = AsyncValue.data(certificates);

      // Guardar en caché para modo offline
      for (final cert in certificates) {
        await _repository.cacheCertificate(cert);
      }
    } catch (error, stackTrace) {
      // Si falla, intentar cargar desde caché
      try {
        final cachedCertificates = await _repository.getCachedCertificates();
        if (cachedCertificates.isNotEmpty) {
          state = AsyncValue.data(cachedCertificates);
        } else {
          state = AsyncValue.error(error, stackTrace);
        }
      } catch (_) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  /// Agregar nuevo certificado
  void addCertificate(CertificateModel certificate) {
    final currentState = state;
    if (currentState is AsyncData<List<CertificateModel>>) {
      final updatedList = [certificate, ...currentState.value];
      state = AsyncValue.data(updatedList);
    }
  }

  /// Filtrar certificados por tipo
  List<CertificateModel> filterByType(CertificateType type) {
    final currentState = state;
    if (currentState is AsyncData<List<CertificateModel>>) {
      return currentState.value.where((cert) => cert.type == type).toList();
    }
    return [];
  }

  /// Obtener certificados del año actual
  List<CertificateModel> getCurrentYearCertificates() {
    final currentState = state;
    if (currentState is AsyncData<List<CertificateModel>>) {
      final currentYear = DateTime.now().year;
      return currentState.value
          .where((cert) => cert.issuedDate.year == currentYear)
          .toList();
    }
    return [];
  }
}

/// Provider de certificado específico
final certificateDetailProvider = FutureProvider.family<CertificateModel?, String>((ref, certificateId) async {
  final repository = ref.read(certificateRepositoryProvider);
  return repository.getCertificate(certificateId);
});

/// Provider de elegibilidad para certificado
final certificateEligibilityProvider = FutureProvider.family<CertificateRequirements, String>((ref, courseId) async {
  final repository = ref.read(certificateRepositoryProvider);
  return repository.checkCertificateEligibility(courseId);
});

/// Provider para solicitar certificado
final certificateRequestProvider = StateNotifierProvider<CertificateRequestNotifier, AsyncValue<CertificateModel?>>((ref) {
  return CertificateRequestNotifier(ref);
});

/// Notifier para solicitud de certificado
class CertificateRequestNotifier extends StateNotifier<AsyncValue<CertificateModel?>> {
  final Ref _ref;
  late final CertificateRepository _repository;

  CertificateRequestNotifier(this._ref) : super(const AsyncValue.data(null)) {
    _repository = _ref.read(certificateRepositoryProvider);
  }

  /// Solicitar certificado
  Future<void> requestCertificate(CertificateRequest request) async {
    state = const AsyncValue.loading();

    try {
      final certificate = await _repository.requestCertificate(request);
      state = AsyncValue.data(certificate);

      // Actualizar lista de certificados
      _ref.read(userCertificatesProvider.notifier).addCertificate(certificate);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Limpiar estado
  void clearRequest() {
    state = const AsyncValue.data(null);
  }
}

/// Provider para validación de certificado
final certificateValidationProvider = StateNotifierProvider<CertificateValidationNotifier, AsyncValue<CertificateValidation?>>((ref) {
  return CertificateValidationNotifier(ref);
});

/// Notifier para validación de certificado
class CertificateValidationNotifier extends StateNotifier<AsyncValue<CertificateValidation?>> {
  final Ref _ref;
  late final CertificateRepository _repository;

  CertificateValidationNotifier(this._ref) : super(const AsyncValue.data(null)) {
    _repository = _ref.read(certificateRepositoryProvider);
  }

  /// Validar certificado
  Future<void> validateCertificate(String certificateNumber) async {
    state = const AsyncValue.loading();

    try {
      final validation = await _repository.validateCertificate(certificateNumber);
      state = AsyncValue.data(validation);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Limpiar validación
  void clearValidation() {
    state = const AsyncValue.data(null);
  }
}

/// Provider para descarga de PDF
final certificatePdfProvider = FutureProvider.family<File?, String>((ref, certificateId) async {
  final repository = ref.read(certificateRepositoryProvider);
  return repository.downloadCertificatePDF(certificateId);
});

/// Provider de estadísticas de certificados
final certificateStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.read(certificateRepositoryProvider);
  return repository.getCertificateStats();
});

/// Provider de plantillas de certificados
final certificateTemplatesProvider = FutureProvider<List<CertificateTemplate>>((ref) async {
  final repository = ref.read(certificateRepositoryProvider);
  return repository.getAvailableTemplates();
});

/// Provider para compartir certificado
final certificateShareProvider = StateNotifierProvider<CertificateShareNotifier, AsyncValue<bool>>((ref) {
  return CertificateShareNotifier(ref);
});

/// Notifier para compartir certificado
class CertificateShareNotifier extends StateNotifier<AsyncValue<bool>> {
  final Ref _ref;
  late final CertificateRepository _repository;

  CertificateShareNotifier(this._ref) : super(const AsyncValue.data(false)) {
    _repository = _ref.read(certificateRepositoryProvider);
  }

  /// Compartir certificado
  Future<void> shareCertificate(CertificateModel certificate) async {
    state = const AsyncValue.loading();

    try {
      await _repository.shareCertificate(certificate);
      state = const AsyncValue.data(true);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider para vista previa de certificado
final certificatePreviewProvider = FutureProvider.family<String, CertificatePreviewParams>((ref, params) async {
  final repository = ref.read(certificateRepositoryProvider);
  return repository.generateCertificatePreview(
    courseId: params.courseId,
    templateId: params.templateId,
  );
});

/// Parámetros para vista previa de certificado
class CertificatePreviewParams {
  final String courseId;
  final String? templateId;

  CertificatePreviewParams({
    required this.courseId,
    this.templateId,
  });
}

/// Provider para reportar problema con certificado
final certificateIssueReportProvider = StateNotifierProvider<CertificateIssueReportNotifier, AsyncValue<bool>>((ref) {
  return CertificateIssueReportNotifier(ref);
});

/// Notifier para reportar problemas
class CertificateIssueReportNotifier extends StateNotifier<AsyncValue<bool>> {
  final Ref _ref;
  late final CertificateRepository _repository;

  CertificateIssueReportNotifier(this._ref) : super(const AsyncValue.data(false)) {
    _repository = _ref.read(certificateRepositoryProvider);
  }

  /// Reportar problema
  Future<void> reportIssue({
    required String certificateId,
    required String issue,
    String? description,
  }) async {
    state = const AsyncValue.loading();

    try {
      final success = await _repository.reportCertificateIssue(
        certificateId: certificateId,
        issue: issue,
        description: description,
      );
      state = AsyncValue.data(success);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}