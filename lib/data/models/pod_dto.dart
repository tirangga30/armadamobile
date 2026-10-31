/// Response received after uploading a file via POST /v1/files/upload
class UploadedFileResponse {
  final String fileId;
  final String objectKey;
  final String mediaType;
  final int sizeBytes;
  final String? url;

  UploadedFileResponse({
    required this.fileId,
    required this.objectKey,
    required this.mediaType,
    required this.sizeBytes,
    this.url,
  });

  factory UploadedFileResponse.fromJson(Map<String, dynamic> json) {
    return UploadedFileResponse(
      fileId: json['fileId']?.toString() ?? '',
      objectKey: json['objectKey']?.toString() ?? '',
      mediaType: json['mediaType']?.toString() ?? '',
      sizeBytes: (json['sizeBytes'] is num)
          ? (json['sizeBytes'] as num).toInt()
          : int.tryParse(json['sizeBytes']?.toString() ?? '0') ?? 0,
      url: json['url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileId': fileId,
      'objectKey': objectKey,
      'mediaType': mediaType,
      'sizeBytes': sizeBytes,
      if (url != null) 'url': url,
    };
  }
}

/// Request body for submitting Proof of Delivery via POST /v1/me/stops/:id/pod
class SubmitPodDto {
  final String receiverName;
  final String photoFileId;
  final String signatureFileId;
  final String? notes;
  final String idempotencyKey;

  SubmitPodDto({
    required this.receiverName,
    required this.photoFileId,
    required this.signatureFileId,
    this.notes,
    required this.idempotencyKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'receiverName': receiverName,
      'photoFileId': photoFileId,
      'signatureFileId': signatureFileId,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      'idempotencyKey': idempotencyKey,
    };
  }
}

/// Request body for reporting stop delivery failure via POST /v1/me/stops/:id/fail
class FailStopDto {
  final String reason;
  final String? notes;

  FailStopDto({
    required this.reason,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'reason': reason,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
    };
  }

  factory FailStopDto.fromJson(Map<String, dynamic> json) {
    return FailStopDto(
      reason: json['reason']?.toString() ?? 'LAINNYA',
      notes: json['notes']?.toString(),
    );
  }
}

/// Proof of Delivery domain model stored or returned with completed stop
class PodModel {
  final String receiverName;
  final String photoFileId;
  final String signatureFileId;
  final String? photoUrl;
  final String? signatureUrl;
  final String? notes;
  final DateTime? submittedAt;

  PodModel({
    required this.receiverName,
    required this.photoFileId,
    required this.signatureFileId,
    this.photoUrl,
    this.signatureUrl,
    this.notes,
    this.submittedAt,
  });

  factory PodModel.fromJson(Map<String, dynamic> json) {
    return PodModel(
      receiverName: json['receiverName']?.toString() ?? '',
      photoFileId: json['photoFileId']?.toString() ?? '',
      signatureFileId: json['signatureFileId']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString(),
      signatureUrl: json['signatureUrl']?.toString(),
      notes: json['notes']?.toString(),
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString())
          : (json['completedAt'] != null
              ? DateTime.tryParse(json['completedAt'].toString())
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receiverName': receiverName,
      'photoFileId': photoFileId,
      'signatureFileId': signatureFileId,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (signatureUrl != null) 'signatureUrl': signatureUrl,
      if (notes != null) 'notes': notes,
      if (submittedAt != null) 'submittedAt': submittedAt!.toIso8601String(),
    };
  }
}
