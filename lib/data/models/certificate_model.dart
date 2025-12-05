import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'certificate_model.g.dart';

// ============= CERTIFICATE MODEL =============

@JsonSerializable()
class CertificateModel extends Equatable {
  final String id;
  final String courseId;
  final String courseName;
  final String studentId;
  final String studentName;
  final DateTime issuedDate;
  final String certificateNumber;
  final double finalGrade;
  final int completionHours;
  final String? instructorName;
  final String? instructorTitle;
  final String? signatureUrl;
  final String? badgeUrl;
  final String? qrCodeUrl;
  final String? verificationUrl;
  final Map<String, dynamic>? metadata;
  final CertificateStatus status;
  final CertificateType type;

  const CertificateModel({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.studentId,
    required this.studentName,
    required this.issuedDate,
    required this.certificateNumber,
    required this.finalGrade,
    required this.completionHours,
    this.instructorName,
    this.instructorTitle,
    this.signatureUrl,
    this.badgeUrl,
    this.qrCodeUrl,
    this.verificationUrl,
    this.metadata,
    this.status = CertificateStatus.active,
    this.type = CertificateType.completion,
  });

  factory CertificateModel.fromJson(Map<String, dynamic> json) =>
      _$CertificateModelFromJson(json);

  Map<String, dynamic> toJson() => _$CertificateModelToJson(this);

  /// Obtiene el formato del certificado
  String get formattedDate {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${issuedDate.day} de ${months[issuedDate.month - 1]} del ${issuedDate.year}';
  }

  /// Obtiene el mensaje de logro
  String get achievementMessage {
    if (finalGrade >= 95) {
      return 'Con Excelencia';
    } else if (finalGrade >= 90) {
      return 'Con Distinción';
    } else if (finalGrade >= 85) {
      return 'Con Honor';
    } else {
      return 'Completado Satisfactoriamente';
    }
  }

  /// Obtiene el color del certificado basado en el tipo
  String get certificateColor {
    switch (type) {
      case CertificateType.excellence:
        return '#FFD700'; // Oro
      case CertificateType.distinction:
        return '#C0C0C0'; // Plata
      case CertificateType.honor:
        return '#CD7F32'; // Bronce
      case CertificateType.completion:
      default:
        return '#CC0000'; // Rojo corporativo
    }
  }

  /// Verifica si el certificado está activo
  bool get isActive => status == CertificateStatus.active;

  /// Verifica si el certificado está verificado
  bool get isVerified => verificationUrl != null && verificationUrl!.isNotEmpty;

  /// Obtiene el enlace de descarga PDF
  String get downloadUrl => 'https://www.enfocadosendiostv.com/api/certificates/$id/download';

  /// Obtiene el enlace para compartir
  String get shareUrl => verificationUrl ?? 'https://www.enfocadosendiostv.com/certificate/$certificateNumber';

  CertificateModel copyWith({
    String? id,
    String? courseId,
    String? courseName,
    String? studentId,
    String? studentName,
    DateTime? issuedDate,
    String? certificateNumber,
    double? finalGrade,
    int? completionHours,
    String? instructorName,
    String? instructorTitle,
    String? signatureUrl,
    String? badgeUrl,
    String? qrCodeUrl,
    String? verificationUrl,
    Map<String, dynamic>? metadata,
    CertificateStatus? status,
    CertificateType? type,
  }) {
    return CertificateModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      issuedDate: issuedDate ?? this.issuedDate,
      certificateNumber: certificateNumber ?? this.certificateNumber,
      finalGrade: finalGrade ?? this.finalGrade,
      completionHours: completionHours ?? this.completionHours,
      instructorName: instructorName ?? this.instructorName,
      instructorTitle: instructorTitle ?? this.instructorTitle,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      badgeUrl: badgeUrl ?? this.badgeUrl,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      verificationUrl: verificationUrl ?? this.verificationUrl,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [
        id,
        courseId,
        courseName,
        studentId,
        studentName,
        issuedDate,
        certificateNumber,
        finalGrade,
        completionHours,
        instructorName,
        instructorTitle,
        signatureUrl,
        badgeUrl,
        qrCodeUrl,
        verificationUrl,
        metadata,
        status,
        type,
      ];
}

// ============= CERTIFICATE STATUS ENUM =============

enum CertificateStatus {
  @JsonValue('active')
  active,
  @JsonValue('revoked')
  revoked,
  @JsonValue('expired')
  expired,
  @JsonValue('pending')
  pending,
}

// ============= CERTIFICATE TYPE ENUM =============

enum CertificateType {
  @JsonValue('completion')
  completion,
  @JsonValue('excellence')
  excellence,
  @JsonValue('distinction')
  distinction,
  @JsonValue('honor')
  honor,
  @JsonValue('participation')
  participation,
}

// ============= CERTIFICATE VALIDATION =============

@JsonSerializable()
class CertificateValidation extends Equatable {
  final bool isValid;
  final CertificateModel? certificate;
  final String? message;
  final DateTime? validatedAt;

  const CertificateValidation({
    required this.isValid,
    this.certificate,
    this.message,
    this.validatedAt,
  });

  factory CertificateValidation.fromJson(Map<String, dynamic> json) =>
      _$CertificateValidationFromJson(json);

  Map<String, dynamic> toJson() => _$CertificateValidationToJson(this);

  @override
  List<Object?> get props => [isValid, certificate, message, validatedAt];
}

// ============= CERTIFICATE REQUEST =============

@JsonSerializable()
class CertificateRequest extends Equatable {
  final String courseId;
  final Map<String, dynamic>? customData;
  final bool requestBadge;
  final bool requestPrintVersion;

  const CertificateRequest({
    required this.courseId,
    this.customData,
    this.requestBadge = true,
    this.requestPrintVersion = false,
  });

  factory CertificateRequest.fromJson(Map<String, dynamic> json) =>
      _$CertificateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CertificateRequestToJson(this);

  @override
  List<Object?> get props => [courseId, customData, requestBadge, requestPrintVersion];
}

// ============= CERTIFICATE REQUIREMENTS =============

@JsonSerializable()
class CertificateRequirements extends Equatable {
  final double minimumGrade;
  final int minimumCompletionPercentage;
  final int minimumWatchTime;
  final bool requireQuizPass;
  final bool requireAllAssignments;
  final bool requireFinalExam;
  final Map<String, dynamic>? additionalRequirements;

  const CertificateRequirements({
    this.minimumGrade = 70.0,
    this.minimumCompletionPercentage = 100,
    this.minimumWatchTime = 0,
    this.requireQuizPass = false,
    this.requireAllAssignments = false,
    this.requireFinalExam = false,
    this.additionalRequirements,
  });

  factory CertificateRequirements.fromJson(Map<String, dynamic> json) =>
      _$CertificateRequirementsFromJson(json);

  Map<String, dynamic> toJson() => _$CertificateRequirementsToJson(this);

  /// Verifica si se cumplen los requisitos
  bool areMetBy({
    required double grade,
    required int completionPercentage,
    required int watchTime,
    required bool quizPassed,
    required bool assignmentsCompleted,
    required bool finalExamPassed,
  }) {
    if (grade < minimumGrade) return false;
    if (completionPercentage < minimumCompletionPercentage) return false;
    if (watchTime < minimumWatchTime) return false;
    if (requireQuizPass && !quizPassed) return false;
    if (requireAllAssignments && !assignmentsCompleted) return false;
    if (requireFinalExam && !finalExamPassed) return false;
    return true;
  }

  @override
  List<Object?> get props => [
        minimumGrade,
        minimumCompletionPercentage,
        minimumWatchTime,
        requireQuizPass,
        requireAllAssignments,
        requireFinalExam,
        additionalRequirements,
      ];
}

// ============= CERTIFICATE TEMPLATE =============

@JsonSerializable()
class CertificateTemplate extends Equatable {
  final String id;
  final String name;
  final String description;
  final String backgroundUrl;
  final String logoUrl;
  final Map<String, dynamic> textStyles;
  final Map<String, dynamic> layout;
  final List<String> availableLanguages;
  final bool isDefault;

  const CertificateTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.backgroundUrl,
    required this.logoUrl,
    required this.textStyles,
    required this.layout,
    this.availableLanguages = const ['es'],
    this.isDefault = false,
  });

  factory CertificateTemplate.fromJson(Map<String, dynamic> json) =>
      _$CertificateTemplateFromJson(json);

  Map<String, dynamic> toJson() => _$CertificateTemplateToJson(this);

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        backgroundUrl,
        logoUrl,
        textStyles,
        layout,
        availableLanguages,
        isDefault,
      ];
}