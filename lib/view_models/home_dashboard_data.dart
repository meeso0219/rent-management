import 'package:rent_management/models/lease.dart';
import 'package:rent_management/repositories/lease_repository.dart';
import 'package:rent_management/utils/lease_formatters.dart';

class HomeDashboardData {
  HomeDashboardData({
    required this.todayFollowUps,
    required this.negotiatingLeases,
    required this.expiringThisMonth,
    required this.topExpiringLeases,
  });

  factory HomeDashboardData.fromRepository(
    LeaseRepository repository, {
    DateTime? now,
  }) {
    final currentDate = now ?? DateTime.now();
    final leases = repository.getLeasesSortedByLeaseEnd();

    final todayFollowUps = leases.where((lease) {
      final followUpDate = lease.nextFollowUpDate;
      return followUpDate != null &&
          isSameCalendarDate(followUpDate, currentDate);
    }).toList();

    final negotiatingLeases = leases
        .where((lease) => lease.status == LeaseStatus.negotiating)
        .toList();

    final expiringThisMonth = leases.where((lease) {
      return lease.leaseEnd.year == currentDate.year &&
          lease.leaseEnd.month == currentDate.month;
    }).toList();

    return HomeDashboardData(
      todayFollowUps: todayFollowUps,
      negotiatingLeases: negotiatingLeases,
      expiringThisMonth: expiringThisMonth,
      topExpiringLeases: repository.getTopExpiringLeases(3),
    );
  }

  final List<Lease> todayFollowUps;
  final List<Lease> negotiatingLeases;
  final List<Lease> expiringThisMonth;
  final List<Lease> topExpiringLeases;

  int get followUpTodayCount => todayFollowUps.length;
  int get negotiatingCount => negotiatingLeases.length;
  int get expiringThisMonthCount => expiringThisMonth.length;
  List<Lease> get top3TodayFollowUps => todayFollowUps.take(3).toList();
}
