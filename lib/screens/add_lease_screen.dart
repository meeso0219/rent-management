import 'package:flutter/material.dart';
import 'package:rent_management/controllers/add_lease_controller.dart';
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

  late final AddLeaseController _controller;
  late final TextEditingController _buildingController;
  late final TextEditingController _unitController;
  late final TextEditingController _tenantController;
  late final TextEditingController _phoneController;

  DateTime? _leaseStartDate;
  DateTime? _leaseEndDate;

  @override
  void initState() {
    super.initState();
    _controller = AddLeaseController(initialLease: widget.initialLease);
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

    final result = _controller.submit(
      buildingName: _buildingController.text.trim(),
      unitNumber: _unitController.text.trim(),
      tenantName: _tenantController.text.trim(),
      tenantPhone: _phoneController.text.trim(),
      leaseStartDate: _leaseStartDate,
      leaseEndDate: _leaseEndDate,
    );

    if (!result.isSuccess) {
      _showMessage(result.errorMessage!);
      return;
    }

    Navigator.of(context).pop(result.lease);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_controller.title)),
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
                  child: Text(_controller.submitLabel),
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
