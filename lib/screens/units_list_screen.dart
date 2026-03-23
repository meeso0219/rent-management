import 'package:flutter/material.dart';
import 'package:rent_management/models/lease.dart';
import 'package:rent_management/repositories/lease_repository.dart';
import 'package:rent_management/screens/unit_detail_screen.dart';
import 'package:rent_management/utils/lease_formatters.dart';

typedef LeaseFilter = List<Lease> Function(LeaseRepository repository);

class UnitsListScreen extends StatefulWidget {
  const UnitsListScreen({
    super.key,
    required this.repository,
    this.title = '전체 계약',
    this.filter,
    this.emptyMessage = '등록된 계약이 없습니다.',
  });

  final LeaseRepository repository;
  final String title;
  final LeaseFilter? filter;
  final String emptyMessage;

  @override
  State<UnitsListScreen> createState() => _UnitsListScreenState();
}

class _UnitsListScreenState extends State<UnitsListScreen> {
  @override
  Widget build(BuildContext context) {
    final leases =
        widget.filter?.call(widget.repository) ??
        widget.repository.getLeasesSortedByLeaseEnd();

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: leases.isEmpty
          ? Center(child: Text(widget.emptyMessage))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              itemCount: leases.length,
              itemBuilder: (context, index) {
                final lease = leases[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    onTap: () async {
                      final result = await Navigator.of(context)
                          .push<LeaseDetailResult>(
                            MaterialPageRoute<LeaseDetailResult>(
                              builder: (_) => UnitDetailScreen(lease: lease),
                            ),
                          );
                      if (result == null) {
                        return;
                      }
                      setState(() {
                        if (result.deleted) {
                          widget.repository.deleteLeaseById(lease.id);
                          return;
                        }
                        if (result.lease != null) {
                          widget.repository.updateLease(result.lease!);
                        }
                      });
                    },
                    title: Text(
                      '${lease.buildingName} ${lease.unitNumber}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${lease.tenantName} · ${leaseStatusText(lease.status)} · ${formatLeaseDate(lease.leaseEnd)}',
                    ),
                    trailing: Text(
                      formatLeaseCountdown(lease.daysRemainingUntilLeaseEnd()),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
