import 'package:rent_management/models/lease.dart';

abstract class LeaseRepository {
  List<Lease> getLeases();
  List<Lease> getLeasesSortedByLeaseEnd();
  List<Lease> getTopExpiringLeases(int count);
  void addLease(Lease lease);
  void updateLease(Lease lease);
  void deleteLeaseById(String id);
}
