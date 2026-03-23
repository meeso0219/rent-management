enum LeaseStatus { active, negotiating, ended }

const Object nextFollowUpDateNotProvided = Object();

class Lease {
  const Lease({
    required this.id,
    required this.buildingName,
    required this.unitNumber,
    required this.tenantName,
    required this.tenantPhone,
    required this.leaseStart,
    required this.leaseEnd,
    required this.status,
    this.nextFollowUpDate,
  });

  final String id;
  final String buildingName;
  final String unitNumber;
  final String tenantName;
  final String tenantPhone;
  final DateTime leaseStart;
  final DateTime leaseEnd;
  final LeaseStatus status;
  final DateTime? nextFollowUpDate;

  int daysRemainingUntilLeaseEnd({DateTime? fromDate}) {
    final base = fromDate ?? DateTime.now();
    final startOfBase = DateTime(base.year, base.month, base.day);
    final endOfLease = DateTime(leaseEnd.year, leaseEnd.month, leaseEnd.day);
    return endOfLease.difference(startOfBase).inDays;
  }

  factory Lease.fromJson(Map<String, dynamic> json) {
    return Lease(
      id: json['id'] as String,
      buildingName: json['buildingName'] as String,
      unitNumber: json['unitNumber'] as String,
      tenantName: json['tenantName'] as String,
      tenantPhone: json['tenantPhone'] as String,
      leaseStart: DateTime.parse(json['leaseStart'] as String),
      leaseEnd: DateTime.parse(json['leaseEnd'] as String),
      status: LeaseStatus.values.byName(json['status'] as String),
      nextFollowUpDate: json['nextFollowUpDate'] == null
          ? null
          : DateTime.parse(json['nextFollowUpDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buildingName': buildingName,
      'unitNumber': unitNumber,
      'tenantName': tenantName,
      'tenantPhone': tenantPhone,
      'leaseStart': leaseStart.toIso8601String(),
      'leaseEnd': leaseEnd.toIso8601String(),
      'status': status.name,
      'nextFollowUpDate': nextFollowUpDate?.toIso8601String(),
    };
  }

  Lease copyWith({
    String? id,
    String? buildingName,
    String? unitNumber,
    String? tenantName,
    String? tenantPhone,
    DateTime? leaseStart,
    DateTime? leaseEnd,
    LeaseStatus? status,
    Object? nextFollowUpDate = nextFollowUpDateNotProvided,
  }) {
    return Lease(
      id: id ?? this.id,
      buildingName: buildingName ?? this.buildingName,
      unitNumber: unitNumber ?? this.unitNumber,
      tenantName: tenantName ?? this.tenantName,
      tenantPhone: tenantPhone ?? this.tenantPhone,
      leaseStart: leaseStart ?? this.leaseStart,
      leaseEnd: leaseEnd ?? this.leaseEnd,
      status: status ?? this.status,
      nextFollowUpDate: identical(nextFollowUpDate, nextFollowUpDateNotProvided)
          ? this.nextFollowUpDate
          : nextFollowUpDate as DateTime?,
    );
  }
}
