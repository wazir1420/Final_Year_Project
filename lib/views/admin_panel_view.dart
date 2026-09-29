import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../routes/app_routes.dart';
import '../widgets/dashboard_widgets.dart';

class AdminPanelView extends GetView<AdminController> {
  const AdminPanelView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kCard,
        elevation: 0,
        title: const Text('Admin panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: kBlue));
        }
        return RefreshIndicator(
          onRefresh: controller.loadData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatsCard(
                totalCustomers: controller.customers.length,
                totalMeters: controller.totalMeters,
              ),
              const SizedBox(height: 20),
              const SectionLabel('Customers'),
              _SearchField(controller: controller.searchController),
              const SizedBox(height: 10),
              Obx(() {
                final list = controller.filteredCustomers;
                if (list.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Koi customer nahi mila',
                      style: TextStyle(color: kMuted),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return Column(
                  children: list
                      .map(
                        (c) => _CustomerTile(
                          key: ValueKey(c.uid),
                          customer: c,
                          onSave: (name) =>
                              controller.updateCustomerName(c, name),
                          onReset: () =>
                              controller.sendCustomerPasswordReset(c),
                          onDelete: () => controller.removeCustomer(c),
                          isBusy:
                              controller.resettingPasswordForUid.value ==
                                  c.uid ||
                              controller.deletingCustomerForUid.value == c.uid,
                        ),
                      )
                      .toList(),
                );
              }),
              Obx(() {
                if (controller.pendingRequests.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('Pending requests'),
                    ...controller.pendingRequests.map(
                      (r) => _RequestTile(
                        request: r,
                        onFulfil: () => _showFulfilDialog(context, r),
                        onAddCustomer: () => _addCustomerFromRequest(r),
                        onDelete: () => _confirmDeleteRequest(r),
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    controller.prepareNewCustomerForm();
                    await Get.toNamed(AppRoutes.addCustomer);
                    controller.loadData();
                  },
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Add customer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Kya aap logout karna chahte hain?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await AuthService().clearSession();
              if (context.mounted) Get.offAllNamed(AppRoutes.login);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showFulfilDialog(BuildContext context, MeterRequest request) {
    final meterIdCtrl = TextEditingController();
    final meterNameCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('${request.customerName} ko meter dein'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: meterIdCtrl,
              decoration: const InputDecoration(labelText: 'Meter ID'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: meterNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Meter naam (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final meterId = meterIdCtrl.text.trim();
              if (meterId.isEmpty) return;
              Get.back();
              await controller.fulfilRequest(
                request,
                meterId,
                meterNameCtrl.text.trim(),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _addCustomerFromRequest(MeterRequest request) async {
    controller.prepareCustomerFromRequest(request);
    await Get.toNamed(AppRoutes.addCustomer);
    await controller.loadData();
  }

  Future<void> _confirmDeleteRequest(MeterRequest request) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete request?'),
        content: Text(
          'Delete the pending request from ${request.customerName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true &&
        await controller.deletePendingRequest(request.id)) {
      Get.snackbar('Request deleted', 'The pending request was removed.');
    }
  }
}

class _StatsCard extends StatelessWidget {
  final int totalCustomers;
  final int totalMeters;
  const _StatsCard({required this.totalCustomers, required this.totalMeters});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: kNavy,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total customers',
                style: TextStyle(fontSize: 12, color: Color(0xB3FFFFFF)),
              ),
              const SizedBox(height: 6),
              Text(
                '$totalCustomers',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total meters',
                style: TextStyle(fontSize: 12, color: Color(0xB3FFFFFF)),
              ),
              const SizedBox(height: 6),
              Text(
                '$totalMeters',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    decoration: InputDecoration(
      hintText: 'Search customer by name',
      hintStyle: TextStyle(color: kMuted, fontSize: 13),
      prefixIcon: Icon(Icons.search_rounded, color: kMuted, size: 20),
      filled: true,
      fillColor: kCard,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: kBorder, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: kBorder, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBlue),
      ),
    ),
  );
}

class _CustomerTile extends StatefulWidget {
  final AdminCustomer customer;
  final Future<bool> Function(String name) onSave;
  final Future<void> Function() onReset;
  final Future<bool> Function() onDelete;
  final bool isBusy;

  const _CustomerTile({
    super.key,
    required this.customer,
    required this.onSave,
    required this.onReset,
    required this.onDelete,
    required this.isBusy,
  });

  @override
  State<_CustomerTile> createState() => _CustomerTileState();
}

class _CustomerTileState extends State<_CustomerTile> {
  late final TextEditingController _nameController;
  bool _isEditing = false;
  bool _confirmingDelete = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final saved = await widget.onSave(_nameController.text);
    if (saved && mounted) setState(() => _isEditing = false);
  }

  void _cancel() {
    _nameController.text = widget.customer.name;
    setState(() {
      _isEditing = false;
      _confirmingDelete = false;
    });
  }

  Future<void> _delete() async {
    final deleted = await widget.onDelete();
    if (!deleted && mounted) {
      setState(() => _confirmingDelete = false);
    }
  }

  String get _initials {
    final parts = widget.customer.name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kBorder, width: 0.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: kBlueTint,
              child: Text(
                _initials,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: kBlue,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.customer.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.customer.meterIds.length} meter${widget.customer.meterIds.length == 1 ? '' : 's'} · '
                    '${widget.customer.isOnline ? 'online' : 'offline'}',
                    style: TextStyle(fontSize: 12, color: kMuted),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: widget.isBusy
                  ? null
                  : () => setState(() => _isEditing = !_isEditing),
              tooltip: _isEditing ? 'Close customer editor' : 'Edit customer',
              icon: widget.isBusy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _isEditing ? Icons.close_rounded : Icons.edit_outlined,
                    ),
            ),
          ],
        ),
        if (_isEditing) ...[
          const Divider(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: widget.customer.email,
            readOnly: true,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: widget.customer.meterIds.isEmpty
                ? 'No meters assigned'
                : widget.customer.meterIds.join(', '),
            readOnly: true,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Assigned meters'),
          ),
          const SizedBox(height: 8),
          if (_confirmingDelete)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFCEBEB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Permanently delete ${widget.customer.name}? Their account access will be removed. Meter data will be preserved.',
                    style: const TextStyle(
                      color: Color(0xFF791F1F),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: widget.isBusy
                            ? null
                            : () => setState(() => _confirmingDelete = false),
                        child: const Text('Keep customer'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: widget.isBusy ? null : _delete,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFB42318),
                        ),
                        icon: widget.isBusy
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.delete_forever_outlined),
                        label: const Text('Delete permanently'),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: widget.isBusy
                    ? null
                    : () => setState(() => _confirmingDelete = true),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFB42318),
                ),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete customer'),
              ),
            ),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: widget.isBusy ? null : widget.onReset,
                icon: const Icon(Icons.lock_reset_rounded),
                label: const Text('Send password reset email'),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(onPressed: _cancel, child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: widget.isBusy ? null : _save,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _RequestTile extends StatelessWidget {
  final MeterRequest request;
  final VoidCallback onFulfil;
  final VoidCallback onAddCustomer;
  final VoidCallback onDelete;

  const _RequestTile({
    required this.request,
    required this.onFulfil,
    required this.onAddCustomer,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: kAmberTint,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.customerName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (request.customerEmail.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  request.customerEmail,
                  style: TextStyle(fontSize: 12, color: kMuted),
                ),
              ],
              const SizedBox(height: 2),
              if (request.requestType == 'account_access')
                const Text(
                  'Account access request',
                  style: TextStyle(fontSize: 12, color: kBlue),
                ),
              const SizedBox(height: 2),
              Text(request.note, style: TextStyle(fontSize: 12, color: kMuted)),
            ],
          ),
        ),
        if (request.requestType == 'meter')
          ElevatedButton(
            onPressed: onFulfil,
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Fulfil', style: TextStyle(fontSize: 12)),
          ),
        if (request.requestType == 'account_access')
          ElevatedButton(
            onPressed: onAddCustomer,
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Add', style: TextStyle(fontSize: 12)),
          ),
        IconButton(
          onPressed: onDelete,
          tooltip: 'Delete request',
          icon: Icon(Icons.delete_outline_rounded, color: kMuted),
        ),
      ],
    ),
  );
}
