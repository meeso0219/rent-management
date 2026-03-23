import 'package:rent_management/models/lease.dart';

abstract class LeaseLocalDataSource {
  Future<List<Lease>?> loadLeases();
  Future<void> saveLeases(List<Lease> leases);
}
