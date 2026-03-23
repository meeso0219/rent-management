import 'package:flutter/material.dart';
import 'package:rent_management/controllers/unit_detail_controller.dart';
import 'package:rent_management/models/lease.dart';
import 'package:rent_management/screens/add_lease_screen.dart';
import 'package:rent_management/utils/lease_formatters.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class LeaseDetailResult {
  const LeaseDetailResult.updated(this.lease) : deleted = false;
  const LeaseDetailResult.deleted() : lease = null, deleted = true;

  final Lease? lease;
  final bool deleted;
}

class UnitDetailScreen extends StatefulWidget {
  const UnitDetailScreen({super.key, required this.lease});

  final Lease lease;

  @override
  State<UnitDetailScreen> createState() => _UnitDetailScreenState();
}

class _UnitDetailScreenState extends State<UnitDetailScreen> {
  late final UnitDetailController _controller;
  bool _isClosing = false;

  Lease get _lease => _controller.lease;

  @override
  void initState() {
    super.initState();
    _controller = UnitDetailController(initialLease: widget.lease);
  }

  void _runMutation(String Function() mutation) {
    setState(() {
      final message = mutation();
      _showMessage(message);
    });
  }

  Future<void> _pickNextFollowUpDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lease.nextFollowUpDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) {
      return;
    }
    _runMutation(() => _controller.saveFollowUpDate(picked));
  }

  Future<void> _callTenant() async {
    final uri = Uri(scheme: 'tel', path: _lease.tenantPhone.trim());
    final launched = await launchUrl(uri);
    if (!launched && mounted) {
      _showMessage('이 기기에서는 전화를 연결할 수 없습니다.');
    }
  }

  Future<void> _shareMessage() async {
    await Share.share(_controller.shareMessage);
  }

  Future<void> _openEditScreen() async {
    final updated = await Navigator.of(context).push<Lease>(
      MaterialPageRoute<Lease>(
        builder: (_) => AddLeaseScreen(initialLease: _lease),
      ),
    );
    if (updated == null) {
      return;
    }
    setState(() {
      _controller.replaceLease(updated);
    });
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(LeaseDetailResult.updated(_lease));
  }

  Future<void> _deleteLease() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('계약 삭제'),
          content: const Text('이 계약을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    Navigator.of(context).pop(const LeaseDetailResult.deleted());
  }

  void _closeWithResult() {
    if (_isClosing || !mounted) {
      return;
    }
    _isClosing = true;
    Navigator.of(context).pop(LeaseDetailResult.updated(_lease));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        _closeWithResult();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _closeWithResult,
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text('${_lease.unitNumber} 상세 정보'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryCard(),
              const SizedBox(height: 16),
              _sectionTitle('빠른 작업'),
              const SizedBox(height: 4),
              Text(
                '아래 버튼으로 바로 연락하거나 일정을 정할 수 있습니다.',
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              _actionButton(label: '전화하기', onPressed: _callTenant),
              const SizedBox(height: 10),
              _actionButton(label: '문자/공유', onPressed: _shareMessage),
              const SizedBox(height: 10),
              _actionButton(
                label: _lease.nextFollowUpDate == null
                    ? '다음 연락일 정하기'
                    : '다음 연락일 수정',
                onPressed: _pickNextFollowUpDate,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '정한 연락일은 홈 화면의 연락 목록에 표시됩니다.',
                  style: textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 10),
              _actionButton(
                label: '다음 연락일 삭제',
                onPressed: _lease.nextFollowUpDate == null
                    ? null
                    : () => _runMutation(_controller.clearFollowUpDate),
              ),
              const SizedBox(height: 10),
              _actionButton(
                label: '협의중으로 변경',
                onPressed: () => _runMutation(_controller.setNegotiating),
              ),
              const SizedBox(height: 24),
              _sectionTitle('계약 처리'),
              const SizedBox(height: 4),
              Text('계약 내용을 반영합니다.', style: textTheme.bodyLarge),
              const SizedBox(height: 12),
              _actionButton(
                label: '갱신 (+2년)',
                onPressed: () => _runMutation(_controller.renewTwoYears),
              ),
              const SizedBox(height: 10),
              _actionButton(
                label: '종료/퇴거',
                onPressed: () => _runMutation(_controller.setEnded),
              ),
              const SizedBox(height: 24),
              _sectionTitle('정보 관리'),
              const SizedBox(height: 12),
              _actionButton(label: '정보 수정', onPressed: _openEditScreen),
              const SizedBox(height: 10),
              _actionButton(label: '삭제', onPressed: _deleteLease),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '상단 요약 정보 카드',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            _summaryRow('건물', _lease.buildingName),
            _summaryRow('호실', _lease.unitNumber),
            _summaryRow('세입자', _lease.tenantName),
            _summaryRow('연락처', _lease.tenantPhone),
            const SizedBox(height: 10),
            _highlightRow(
              label: '계약 종료일',
              value: formatLeaseDate(_lease.leaseEnd),
              toneColor: const Color(0xFFB45309),
            ),
            const SizedBox(height: 8),
            _highlightRow(
              label: '만료까지',
              value: _controller.countdownText(),
              toneColor: colorScheme.primary,
            ),
            const SizedBox(height: 8),
            _highlightRow(
              label: '상태',
              value: leaseStatusText(_lease.status),
              toneColor: const Color(0xFF0E7490),
            ),
            const SizedBox(height: 8),
            _highlightRow(
              label: '다음 연락일',
              value: _lease.nextFollowUpDate == null
                  ? '미정'
                  : formatLeaseDate(_lease.nextFollowUpDate!),
              toneColor: const Color(0xFF0B6E4F),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlightRow({
    required String label,
    required String value,
    required Color toneColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: toneColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: toneColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: toneColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    );
  }

  Widget _actionButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonal(
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
