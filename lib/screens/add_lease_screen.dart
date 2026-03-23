import 'package:flutter/material.dart';
import 'package:rent_management/models/lease.dart';
import 'package:rent_management/utils/lease_formatters.dart';

class AddLeaseScreen extends StatefulWidget {
  const AddLeaseScreen({super.key, this.initialLease});

  final Lease? initialLease;

  @override
  State<AddLeaseScreen> createState() => _AddLeaseScreenState();
}

class _AddLeaseScreenState extends State<AddLeaseScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _buildingController;
  late final TextEditingController _unitController;
  late final TextEditingController _tenantController;
  late final TextEditingController _phoneController;

  DateTime? _leaseStartDate;
  DateTime? _leaseEndDate;

  bool get _isEditMode => widget.initialLease != null;

  @override
  void initState() {
    super.initState();
    _buildingController = TextEditingController(
      text: widget.initialLease?.buildingName ?? '',
    );
    _unitController = TextEditingController(
      text: widget.initialLease?.unitNumber ?? '',
    );
    _tenantController = TextEditingController(
      text: widget.initialLease?.tenantName ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.initialLease?.tenantPhone ?? '',
    );
    _leaseStartDate = widget.initialLease?.leaseStart;
    _leaseEndDate = widget.initialLease?.leaseEnd;
  }

  @override
  void dispose() {
    _buildingController.dispose();
    _unitController.dispose();
    _tenantController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_leaseStartDate == null || _leaseEndDate == null) {
      _showMessage('계약 시작일과 종료일을 모두 선택해주세요.');
      return;
    }
    if (_leaseEndDate!.isBefore(_leaseStartDate!)) {
      _showMessage('계약 종료일은 시작일보다 뒤여야 합니다.');
      return;
    }

    if (_isEditMode) {
      final updated = widget.initialLease!.copyWith(
        buildingName: _buildingController.text.trim(),
        unitNumber: _unitController.text.trim(),
        tenantName: _tenantController.text.trim(),
        tenantPhone: _phoneController.text.trim(),
        leaseStart: _leaseStartDate!,
        leaseEnd: _leaseEndDate!,
      );
      Navigator.of(context).pop(updated);
      return;
    }

    final lease = Lease(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      buildingName: _buildingController.text.trim(),
      unitNumber: _unitController.text.trim(),
      tenantName: _tenantController.text.trim(),
      tenantPhone: _phoneController.text.trim(),
      leaseStart: _leaseStartDate!,
      leaseEnd: _leaseEndDate!,
      status: LeaseStatus.active,
      nextFollowUpDate: null,
    );
    Navigator.of(context).pop(lease);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? '계약 수정' : '계약 추가')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _textField(controller: _buildingController, label: '건물명'),
              const SizedBox(height: 14),
              _textField(controller: _unitController, label: '호실'),
              const SizedBox(height: 14),
              _textField(controller: _tenantController, label: '세입자 이름'),
              const SizedBox(height: 14),
              _textField(
                controller: _phoneController,
                label: '전화번호',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _dateButton(
                label: '계약 시작일',
                value: _leaseStartDate,
                onTap: () => _pickDate(
                  current: _leaseStartDate,
                  onPicked: (value) => setState(() => _leaseStartDate = value),
                ),
              ),
              const SizedBox(height: 10),
              _dateButton(
                label: '계약 종료일',
                value: _leaseEndDate,
                onTap: () => _pickDate(
                  current: _leaseEndDate,
                  onPicked: (value) => setState(() => _leaseEndDate = value),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(_isEditMode ? '수정 완료' : '계약 등록'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '필수 입력 항목입니다.';
        }
        return null;
      },
    );
  }

  Widget _dateButton({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            value == null ? label : '$label: ${formatLeaseDate(value)}',
          ),
        ),
      ),
    );
  }
}
