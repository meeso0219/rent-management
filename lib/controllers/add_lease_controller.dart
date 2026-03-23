import 'package:rent_management/models/lease.dart';

class AddLeaseSubmissionResult {
  const AddLeaseSubmissionResult.success(this.lease) : errorMessage = null;
  const AddLeaseSubmissionResult.error(this.errorMessage) : lease = null;

  final Lease? lease;
  final String? errorMessage;

  bool get isSuccess => lease != null;
}

class AddLeaseController {
  const AddLeaseController({this.initialLease});

  final Lease? initialLease;

  bool get isEditMode => initialLease != null;
  String get title => isEditMode ? '계약 수정' : '계약 추가';
  String get submitLabel => isEditMode ? '수정 완료' : '계약 등록';

  AddLeaseSubmissionResult submit({
    required String buildingName,
    required String unitNumber,
    required String tenantName,
    required String tenantPhone,
    required DateTime? leaseStartDate,
    required DateTime? leaseEndDate,
  }) {
    if (leaseStartDate == null || leaseEndDate == null) {
      return const AddLeaseSubmissionResult.error(
        '계약 시작일과 종료일을 모두 선택해주세요.',
      );
    }

    if (leaseEndDate.isBefore(leaseStartDate)) {
      return const AddLeaseSubmissionResult.error(
        '계약 종료일은 시작일보다 늦어야 합니다.',
      );
    }

    if (isEditMode) {
      return AddLeaseSubmissionResult.success(
        initialLease!.copyWith(
          buildingName: buildingName,
          unitNumber: unitNumber,
          tenantName: tenantName,
          tenantPhone: tenantPhone,
          leaseStart: leaseStartDate,
          leaseEnd: leaseEndDate,
        ),
      );
    }

    return AddLeaseSubmissionResult.success(
      Lease(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        buildingName: buildingName,
        unitNumber: unitNumber,
        tenantName: tenantName,
        tenantPhone: tenantPhone,
        leaseStart: leaseStartDate,
        leaseEnd: leaseEndDate,
        status: LeaseStatus.active,
        nextFollowUpDate: null,
      ),
    );
  }
}
