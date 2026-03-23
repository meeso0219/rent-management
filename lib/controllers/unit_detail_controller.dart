import 'package:rent_management/models/lease.dart';
import 'package:rent_management/utils/lease_formatters.dart';

class UnitDetailController {
  UnitDetailController({required Lease initialLease}) : _lease = initialLease;

  Lease _lease;

  Lease get lease => _lease;

  void replaceLease(Lease lease) {
    _lease = lease;
  }

  String get shareMessage =>
      '안녕하세요 ${_lease.tenantName}님.\n'
      '${_lease.buildingName} ${_lease.unitNumber} 계약 안내드립니다.\n'
      '계약 종료일은 ${formatLeaseDate(_lease.leaseEnd)}입니다.';

  String countdownText() {
    final days = _lease.daysRemainingUntilLeaseEnd();
    if (days > 0) {
      return '$days일 남음';
    }
    if (days == 0) {
      return '오늘 만료';
    }
    return '${days.abs()}일 지남';
  }

  String renewTwoYears() {
    final end = _lease.leaseEnd;
    _lease = _lease.copyWith(
      leaseEnd: DateTime(end.year + 2, end.month, end.day),
      status: LeaseStatus.active,
      nextFollowUpDate: null,
    );
    return '계약을 2년 연장했습니다.';
  }

  String saveFollowUpDate(DateTime date) {
    _lease = _lease.copyWith(nextFollowUpDate: date);
    return '다음 연락일을 저장했습니다.';
  }

  String clearFollowUpDate() {
    _lease = _lease.copyWith(nextFollowUpDate: null);
    return '다음 연락일을 삭제했습니다.';
  }

  String setNegotiating() {
    _lease = _lease.copyWith(status: LeaseStatus.negotiating);
    return '상태를 협의중으로 변경했습니다.';
  }

  String setEnded() {
    _lease = _lease.copyWith(
      status: LeaseStatus.ended,
      nextFollowUpDate: null,
    );
    return '계약을 종료 상태로 변경했습니다.';
  }
}
