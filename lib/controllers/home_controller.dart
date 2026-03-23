import 'package:rent_management/models/lease.dart';
import 'package:rent_management/repositories/lease_repository.dart';
import 'package:rent_management/view_models/home_dashboard_data.dart';

class HomeController {
  HomeController(this._repository);

  final LeaseRepository _repository;

  HomeDashboardData get dashboard => HomeDashboardData.fromRepository(_repository);

  LeaseRepository get repository => _repository;

  void addLease(Lease lease) {
    _repository.addLease(lease);
  }

  void updateLease(Lease lease) {
    _repository.updateLease(lease);
  }

  void deleteLeaseById(String id) {
    _repository.deleteLeaseById(id);
  }
}
