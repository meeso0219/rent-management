import 'package:flutter/material.dart';
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
  late Lease _lease;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _lease = widget.lease;
  }

  void _updateLease(Lease updated) {
    setState(() {
      _lease = updated;
    });
  }

  void _renewTwoYears() {
    final end = _lease.leaseEnd;
    _updateLease(
      _lease.copyWith(
        leaseEnd: DateTime(end.year + 2, end.month, end.day),
        status: LeaseStatus.active,
        nextFollowUpDate: null,
      ),
    );
    _showMessage('계약을 2년 연장했습니다.');
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
    _updateLease(_lease.copyWith(nextFollowUpDate: picked));
    _showMessage('다음 연락일을 저장했습니다.');
  }

  void _clearFollowUpDate() {
    _updateLease(_lease.copyWith(nextFollowUpDate: null));
    _showMessage('다음 연락일을 지웠습니다.');
  }

  void _setNegotiating() {
    _updateLease(_lease.copyWith(status: LeaseStatus.negotiating));
    _showMessage('상태를 협의 중으로 변경했습니다.');
  }

  void _setEnded() {
    _updateLease(
      _lease.copyWith(status: LeaseStatus.ended, nextFollowUpDate: null),
    );
    _showMessage('계약을 종료 상태로 변경했습니다.');
  }

  Future<void> _callTenant() async {
    final uri = Uri(scheme: 'tel', path: _lease.tenantPhone.trim());
    final launched = await launchUrl(uri);
    if (!launched && mounted) {
      _showMessage('이 기기에서는 전화 앱을 열 수 없습니다.');
    }
  }

  Future<void> _shareMessage() async {
    await Share.share(
      '안녕하세요 ${_lease.tenantName}님.\n'
      '${_lease.buildingName} ${_lease.unitNumber} 계약 안내드립니다.\n'
      '계약 종료일은 ${formatLeaseDate(_lease.leaseEnd)} 입니다.',
    );
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
    _updateLease(updated);
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryCard(),
              const SizedBox(height: 20),
              _sectionTitle('빠른 작업'),
              const SizedBox(height: 12),
              _actionButton(label: '전화하기', onPressed: _callTenant),
              const SizedBox(height: 10),
              _actionButton(label: '문자 공유', onPressed: _shareMessage),
              const SizedBox(height: 10),
              _actionButton(
                label: _lease.nextFollowUpDate == null
                    ? '다음 연락일 정하기'
                    : '다음 연락일 수정',
                onPressed: _pickNextFollowUpDate,
              ),
              const SizedBox(height: 10),
              _actionButton(
                label: '다음 연락일 지우기',
                onPressed: _lease.nextFollowUpDate == null
                    ? null
                    : _clearFollowUpDate,
              ),
              const SizedBox(height: 10),
              _actionButton(label: '협의 중으로 변경', onPressed: _setNegotiating),
              const SizedBox(height: 24),
              _sectionTitle('계약 처리'),
              const SizedBox(height: 12),
              _actionButton(label: '2년 연장', onPressed: _renewTwoYears),
              const SizedBox(height: 10),
              _actionButton(label: '계약 종료', onPressed: _setEnded),
              const SizedBox(height: 24),
              _sectionTitle('관리'),
              const SizedBox(height: 12),
              _actionButton(label: '계약 수정', onPressed: _openEditScreen),
              const SizedBox(height: 10),
              _actionButton(label: '계약 삭제', onPressed: _deleteLease),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _summaryRow('건물명', _lease.buildingName),
            _summaryRow('호실', _lease.unitNumber),
            _summaryRow('세입자', _lease.tenantName),
            _summaryRow('전화번호', _lease.tenantPhone),
            _summaryRow('시작일', formatLeaseDate(_lease.leaseStart)),
            _summaryRow('종료일', formatLeaseDate(_lease.leaseEnd)),
            _summaryRow(
              '남은 기간',
              formatLeaseCountdown(_lease.daysRemainingUntilLeaseEnd()),
            ),
            _summaryRow('상태', leaseStatusText(_lease.status)),
            _summaryRow(
              '다음 연락',
              _lease.nextFollowUpDate == null
                  ? '미정'
                  : formatLeaseDate(_lease.nextFollowUpDate!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(label),
        ),
      ),
    );
  }
}
