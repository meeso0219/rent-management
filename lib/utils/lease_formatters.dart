import 'package:rent_management/models/lease.dart';

String formatLeaseDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String formatLeaseCountdown(int days) {
  if (days > 0) {
    return '$days일 남음';
  }
  if (days == 0) {
    return '오늘 만료';
  }
  return '${days.abs()}일 지남';
}

String leaseStatusText(LeaseStatus status) {
  switch (status) {
    case LeaseStatus.active:
      return '진행 중';
    case LeaseStatus.negotiating:
      return '협의 중';
    case LeaseStatus.ended:
      return '종료';
  }
}

bool isSameCalendarDate(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
