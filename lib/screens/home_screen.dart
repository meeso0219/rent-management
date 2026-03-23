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
    ).showSnackBar(const SnackBar(content: Text('계약을 추가했습니다.')));
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

  Future<void> _openAllContracts() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => UnitsListScreen(repository: widget.repository),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  String _countdownText(int days) {
    if (days > 0) {
      return '$days일 남음';
    }
    if (days == 0) {
      return '오늘 만료';
    }
    return '${days.abs()}일 지남';
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
            '오늘 할 일',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '연락이 필요한 계약과 곧 끝나는 계약을 먼저 확인하세요.',
            style: textTheme.titleMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 20),
          _PrioritySummaryCard(
            title: '오늘 연락할 항목',
            countText: '${dashboard.followUpTodayCount}건',
            helperText: dashboard.followUpTodayCount == 0
                ? '오늘 바로 연락할 계약이 없습니다.'
                : '오늘 연락할 계약을 먼저 확인하세요.',
            accentColor: const Color(0xFF0E7490),
            icon: Icons.phone_in_talk_rounded,
            onTap: () => _openFilteredList(
              title: '오늘 연락할 항목',
              filter: (_) => dashboard.todayFollowUps,
              emptyMessage: '오늘 연락할 항목이 없습니다.',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _CompactSummaryCard(
                  title: '협의중',
                  countText: '${dashboard.negotiatingCount}건',
                  helperText: '지금 협의 중인 계약',
                  accentColor: const Color(0xFFB45309),
                  onTap: () => _openFilteredList(
                    title: '협의중',
                    filter: (_) => dashboard.negotiatingLeases,
                    emptyMessage: '협의중인 계약이 없습니다.',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CompactSummaryCard(
                  title: '이번 달 만료',
                  countText: '${dashboard.expiringThisMonthCount}건',
                  helperText: '이번 달 안에 끝남',
                  accentColor: const Color(0xFF0B6E4F),
                  onTap: () => _openFilteredList(
                    title: '이번 달 만료',
                    filter: (_) => dashboard.expiringThisMonth,
                    emptyMessage: '이번 달 만료 계약이 없습니다.',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const _SectionHeader(
            title: '오늘 연락할 항목',
            subtitle: '오늘 먼저 확인할 계약 3건을 보여드립니다.',
          ),
          const SizedBox(height: 12),
          if (dashboard.top3TodayFollowUps.isEmpty)
            const _EmptySectionCard(
              message: '오늘 연락할 계약이 없습니다.',
            ),
          ...dashboard.top3TodayFollowUps.map(
            (lease) => _LeaseTile(
              lease: lease,
              subtitle: '${lease.tenantName} · ${leaseStatusText(lease.status)}',
              trailing: const Icon(Icons.chevron_right),
              onUpdated: (updated) =>
                  setState(() => widget.repository.updateLease(updated)),
              onDeleted: (id) =>
                  setState(() => widget.repository.deleteLeaseById(id)),
            ),
          ),
          const SizedBox(height: 28),
          const _SectionHeader(
            title: '만료 임박 TOP 3',
            subtitle: '종료일이 가까운 계약부터 확인하세요.',
          ),
          const SizedBox(height: 12),
          if (dashboard.topExpiringLeases.isEmpty)
            const _EmptySectionCard(
              message: '곧 끝나는 계약이 없습니다.',
            ),
          ...dashboard.topExpiringLeases.map(
            (lease) => _LeaseTile(
              lease: lease,
              subtitle:
                  '${lease.tenantName} · 종료일 ${formatLeaseDate(lease.leaseEnd)}',
              trailing: Text(
                _countdownText(lease.daysRemainingUntilLeaseEnd()),
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
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _openAllContracts,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('전체 계약 보기'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrioritySummaryCard extends StatelessWidget {
  const _PrioritySummaryCard({
    required this.title,
    required this.countText,
    required this.helperText,
    required this.accentColor,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String countText;
  final String helperText;
  final Color accentColor;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [accentColor.withValues(alpha: 0.14), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: accentColor, size: 28),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                countText,
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                helperText,
                style: textTheme.titleMedium?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 16),
              _TapHintRow(accentColor: accentColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactSummaryCard extends StatelessWidget {
  const _CompactSummaryCard({
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
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                countText,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                helperText,
                style: textTheme.bodyLarge?.copyWith(height: 1.35),
              ),
              const SizedBox(height: 14),
              _TapHintRow(accentColor: accentColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _TapHintRow extends StatelessWidget {
  const _TapHintRow({required this.accentColor});

  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '눌러서 보기',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: accentColor,
          ),
        ),
        const Spacer(),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 18,
            color: accentColor,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: textTheme.bodyLarge?.copyWith(height: 1.4),
        ),
      ],
    );
  }
}

class _EmptySectionCard extends StatelessWidget {
  const _EmptySectionCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          message,
          style: Theme.of(context).textTheme.titleMedium,
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
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.35),
          ),
        ),
        trailing: trailing,
      ),
    );
  }
}
