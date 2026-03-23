import 'dart:async';

import 'package:rent_management/data_sources/lease_local_data_source.dart';
import 'package:rent_management/models/lease.dart';
import 'package:rent_management/repositories/lease_repository.dart';
import 'package:rent_management/services/notification_service.dart';

class InMemoryLeaseRepository implements LeaseRepository {
  InMemoryLeaseRepository({
    List<Lease>? initialLeases,
    LeaseLocalDataSource? localDataSource,
  }) : _leases = [...(initialLeases ?? const [])],
       _localDataSource = localDataSource;

  final List<Lease> _leases;
  final LeaseLocalDataSource? _localDataSource;

  static Future<InMemoryLeaseRepository> create({
    required LeaseLocalDataSource localDataSource,
    List<Lease>? fallbackSampleLeases,
  }) async {
    final savedLeases = await localDataSource.loadLeases();
    final initialLeases = (savedLeases != null && savedLeases.isNotEmpty)
        ? savedLeases
        : (fallbackSampleLeases ?? buildSampleLeases());

    final repository = InMemoryLeaseRepository(
      initialLeases: initialLeases,
      localDataSource: localDataSource,
    );
    unawaited(NotificationService.instance.syncAllNotifications(initialLeases));
    return repository;
  }

  static List<Lease> buildSampleLeases() {
    final now = DateTime.now();
    return [
      Lease(
        id: 'l1',
        buildingName: '해담빌라',
        unitNumber: '101',
        tenantName: '김민지',
        tenantPhone: '010-1234-5678',
        leaseStart: DateTime(now.year - 1, 3, 1),
        leaseEnd: now.add(const Duration(days: 12)),
        status: LeaseStatus.active,
        nextFollowUpDate: now,
      ),
      Lease(
        id: 'l2',
        buildingName: '해담빌라',
        unitNumber: '203',
        tenantName: '박준호',
        tenantPhone: '010-2211-4589',
        leaseStart: DateTime(now.year - 1, 5, 10),
        leaseEnd: now.add(const Duration(days: 3)),
        status: LeaseStatus.active,
        nextFollowUpDate: now.add(const Duration(days: 2)),
      ),
      Lease(
        id: 'l3',
        buildingName: '한강하우스',
        unitNumber: '502',
        tenantName: '이소라',
        tenantPhone: '010-9000-7777',
        leaseStart: DateTime(now.year - 1, 8, 21),
        leaseEnd: now.add(const Duration(days: 8)),
        status: LeaseStatus.negotiating,
        nextFollowUpDate: now.add(const Duration(days: 1)),
      ),
      Lease(
        id: 'l4',
        buildingName: '푸른아파트',
        unitNumber: 'B01',
        tenantName: '정현우',
        tenantPhone: '010-7777-2222',
        leaseStart: DateTime(now.year - 2, 1, 5),
        leaseEnd: now.add(const Duration(days: 25)),
        status: LeaseStatus.active,
        nextFollowUpDate: null,
      ),
    ];
  }

  void _persist() {
    final localDataSource = _localDataSource;
    if (localDataSource == null) {
      return;
    }
    unawaited(localDataSource.saveLeases(_leases));
  }

  void _syncNotifications(Lease lease) {
    unawaited(NotificationService.instance.syncFollowUpNotification(lease));
    unawaited(
      NotificationService.instance.syncLeaseExpirationNotification(lease),
    );
  }

  @override
  List<Lease> getLeases() => [..._leases];

  @override
  List<Lease> getLeasesSortedByLeaseEnd() {
    final sorted = [..._leases];
    sorted.sort((a, b) => a.leaseEnd.compareTo(b.leaseEnd));
    return sorted;
  }

  @override
  List<Lease> getTopExpiringLeases(int count) {
    return getLeasesSortedByLeaseEnd().take(count).toList();
  }

  @override
  void addLease(Lease lease) {
    _leases.add(lease);
    _persist();
    _syncNotifications(lease);
  }

  @override
  void updateLease(Lease lease) {
    final index = _leases.indexWhere((item) => item.id == lease.id);
    if (index == -1) {
      return;
    }
    _leases[index] = lease;
    _persist();
    _syncNotifications(lease);
  }

  @override
  void deleteLeaseById(String id) {
    final removedLeases = _leases.where((lease) => lease.id == id).toList();
    _leases.removeWhere((lease) => lease.id == id);
    _persist();
    for (final lease in removedLeases) {
      unawaited(
        NotificationService.instance.cancelNotificationsByLeaseId(lease.id),
      );
    }
  }
}
