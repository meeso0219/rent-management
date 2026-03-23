import 'package:flutter/material.dart';
import 'package:rent_management/models/lease.dart';
import 'package:rent_management/repositories/lease_repository.dart';
import 'package:rent_management/screens/add_lease_screen.dart';
import 'package:rent_management/screens/unit_detail_screen.dart';
import 'package:rent_management/screens/units_list_screen.dart';
import 'package:rent_management/utils/lease_formatters.dart';
import 'package:rent_management/view_models/home_dashboard_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});

  final LeaseRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _openAddLeaseScreen() async {
    final created = await Navigator.of(context).push<Lease>(
      MaterialPageRoute<Lease>(builder: (_) => const AddLeaseScreen()),
    );
    if (created == null || !mounted) {
      return;
    }
    setState(() {
      widget.repository.addLease(created);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('계약이 추가되었습니다.')));
  }

  Future<void> _openFilteredList({
    required String title,
    required LeaseFilter filter,
    required String emptyMessage,
  }) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => UnitsListScreen(
          repository: widget.repository,
          title: title,
          filter: filter,
          emptyMessage: emptyMessage,
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = HomeDashboardData.fromRepository(widget.repository);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('임대 관리')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddLeaseScreen,
        icon: const Icon(Icons.add),
        label: const Text('계약 추가'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
        children: [
          Text(
            '오늘 확인할 내용',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text('연락 일정, 협의 중인 계약, 만료 예정 계약을 한눈에 볼 수 있습니다.'),
          const SizedBox(height: 18),
          _SummaryCard(
            title: '오늘 연락할 계약',
            countText: '${dashboard.followUpTodayCount}',
            helperText: '오늘 연락이 필요한 계약입니다.',
            accentColor: const Color(0xFF0E7490),
            onTap: () => _openFilteredList(
              title: '오늘 연락할 계약',
              filter: (_) => dashboard.todayFollowUps,
              emptyMessage: '오늘 연락할 계약이 없습니다.',
            ),
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            title: '협의 중',
            countText: '${dashboard.negotiatingCount}',
            helperText: '현재 조율 중인 계약입니다.',
            accentColor: const Color(0xFFB45309),
            onTap: () => _openFilteredList(
              title: '협의 중인 계약',
              filter: (_) => dashboard.negotiatingLeases,
              emptyMessage: '협의 중인 계약이 없습니다.',
            ),
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            title: '이번 달 만료',
            countText: '${dashboard.expiringThisMonthCount}',
            helperText: '이번 달 안에 끝나는 계약입니다.',
            accentColor: const Color(0xFF0B6E4F),
            onTap: () => _openFilteredList(
              title: '이번 달 만료 계약',
              filter: (_) => dashboard.expiringThisMonth,
              emptyMessage: '이번 달 만료되는 계약이 없습니다.',
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '오늘 연락 목록',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (dashboard.top3TodayFollowUps.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('오늘 연락할 계약이 없습니다.'),
              ),
            ),
          ...dashboard.top3TodayFollowUps.map(
            (lease) => _LeaseTile(
              lease: lease,
              subtitle:
                  '${lease.tenantName} · ${leaseStatusText(lease.status)}',
              trailing: const Icon(Icons.chevron_right),
              onUpdated: (updated) =>
                  setState(() => widget.repository.updateLease(updated)),
              onDeleted: (id) =>
                  setState(() => widget.repository.deleteLeaseById(id)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '만료 임박 계약',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...dashboard.topExpiringLeases.map(
            (lease) => _LeaseTile(
              lease: lease,
              subtitle:
                  '${lease.tenantName} · 만료일 ${formatLeaseDate(lease.leaseEnd)}',
              trailing: Text(
                formatLeaseCountdown(lease.daysRemainingUntilLeaseEnd()),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              onUpdated: (updated) =>
                  setState(() => widget.repository.updateLease(updated)),
              onDeleted: (id) =>
                  setState(() => widget.repository.deleteLeaseById(id)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        UnitsListScreen(repository: widget.repository),
                  ),
                );
                if (mounted) {
                  setState(() {});
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('전체 계약 보기'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.countText,
    required this.helperText,
    required this.accentColor,
    required this.onTap,
  });

  final String title;
  final String countText;
  final String helperText;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      countText,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(helperText),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaseTile extends StatelessWidget {
  const _LeaseTile({
    required this.lease,
    required this.subtitle,
    required this.trailing,
    required this.onUpdated,
    required this.onDeleted,
  });

  final Lease lease;
  final String subtitle;
  final Widget trailing;
  final ValueChanged<Lease> onUpdated;
  final ValueChanged<String> onDeleted;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () async {
          final result = await Navigator.of(context).push<LeaseDetailResult>(
            MaterialPageRoute<LeaseDetailResult>(
              builder: (_) => UnitDetailScreen(lease: lease),
            ),
          );
          if (result == null) {
            return;
          }
          if (result.deleted) {
            onDeleted(lease.id);
            return;
          }
          if (result.lease != null) {
            onUpdated(result.lease!);
          }
        },
        title: Text(
          '${lease.buildingName} ${lease.unitNumber}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: trailing,
      ),
    );
  }
}
