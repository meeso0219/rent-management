import 'dart:convert';

import 'package:rent_management/data_sources/lease_local_data_source.dart';
import 'package:rent_management/models/lease.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsLeaseLocalDataSource implements LeaseLocalDataSource {
  SharedPrefsLeaseLocalDataSource(this._prefs);

  static const _leasesKey = 'leases_v1';

  final SharedPreferences _prefs;

  static Future<SharedPrefsLeaseLocalDataSource> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPrefsLeaseLocalDataSource(prefs);
  }

  @override
  Future<List<Lease>?> loadLeases() async {
    final raw = _prefs.getString(_leasesKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return null;
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(Lease.fromJson)
        .toList();
  }

  @override
  Future<void> saveLeases(List<Lease> leases) async {
    final encoded = jsonEncode(leases.map((lease) => lease.toJson()).toList());
    await _prefs.setString(_leasesKey, encoded);
  }
}
