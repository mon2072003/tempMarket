import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/services/supabase_service.dart';

class CourierOrdersView extends StatefulWidget {
  const CourierOrdersView({super.key});

  @override
  State<CourierOrdersView> createState() => _CourierOrdersViewState();
}

class _CourierOrdersViewState extends State<CourierOrdersView> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _busyOrderId;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders({bool showLoader = true}) async {
    if (showLoader && mounted) setState(() => _isLoading = true);
    final rows = await SupabaseService().getOrdersWithItems();
    if (!mounted) return;
    setState(() {
      _orders = rows;
      _isLoading = false;
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _claimOrder(String orderId) async {
    final loc = AppLocalizations.of(context);
    setState(() => _busyOrderId = orderId);
    final service = SupabaseService();
    final success = await service.claimCourierOrder(orderId);
    if (!mounted) return;
    setState(() => _busyOrderId = null);
    _showMessage(
      success
          ? (loc.isArabic
                ? '\u{62a}\u{645}\u{20}\u{627}\u{633}\u{62a}\u{644}\u{627}\u{645}\u{20}\u{627}\u{644}\u{637}\u{644}\u{628}\u{20}\u{648}\u{625}\u{628}\u{644}\u{627}\u{63a}\u{20}\u{627}\u{644}\u{639}\u{645}\u{64a}\u{644}\u{2e}'
                : 'Order accepted. The customer has been notified of your contact details.')
          : (loc.isArabic
                ? '\u{646}\u{64a}\u{641}\u{20}\u{645}\u{646}\u{62f}\u{648}\u{628}\u{20}\u{622}\u{62e}\u{631}\u{20}\u{627}\u{644}\u{637}\u{644}\u{628}\u{20}\u{623}\u{648}\u{62a}\u{63a}\u{64a}\u{631}\u{62a}\u{20}\u{62d}\u{627}\u{644}\u{62a}\u{647}\u{2e}'
                : service.lastCourierActionError ??
                      'Could not accept this order.'),
      isError: !success,
    );
    await _loadOrders(showLoader: false);
  }

  Future<void> _updateStatus(String orderId, String status) async {
    final loc = AppLocalizations.of(context);
    setState(() => _busyOrderId = orderId);
    final service = SupabaseService();
    final success = await service.updateCourierOrderStatus(orderId, status);
    if (!mounted) return;
    setState(() => _busyOrderId = null);
    final successMessage = status == 'cancelled'
        ? (loc.isArabic
              ? '\u{62a}\u{645}\u{20}\u{625}\u{644}\u{63a}\u{627}\u{621}\u{20}\u{627}\u{644}\u{637}\u{644}\u{628}\u{20}\u{648}\u{625}\u{628}\u{644}\u{627}\u{63a}\u{20}\u{627}\u{644}\u{639}\u{645}\u{64a}\u{644}\u{2e}'
              : 'Order cancelled. The customer has been notified.')
        : (loc.isArabic
              ? '\u{62a}\u{645}\u{20}\u{62a}\u{62d}\u{62f}\u{64a}\u{62b}\u{20}\u{62d}\u{627}\u{644}\u{629}\u{20}\u{627}\u{644}\u{637}\u{644}\u{628}\u{2e}'
              : 'Order status updated.');
    _showMessage(
      success
          ? successMessage
          : (service.lastCourierActionError ??
                (loc.isArabic
                    ? '\u{62a}\u{639}\u{630}\u{631}\u{20}\u{62a}\u{62d}\u{62f}\u{64a}\u{62b}\u{20}\u{627}\u{644}\u{637}\u{644}\u{628}\u{2e}'
                    : 'Could not update this order.')),
      isError: !success,
    );
    await _loadOrders(showLoader: false);
  }

  Future<void> _confirmCancellation(String orderId) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.cancel_outlined, color: Colors.red),
        title: Text(
          loc.isArabic
              ? '\u{625}\u{644}\u{63a}\u{627}\u{621}\u{20}\u{627}\u{644}\u{637}\u{644}\u{628}'
              : 'Cancel order?',
        ),
        content: Text(
          loc.isArabic
              ? '\u{647}\u{644}\u{20}\u{62a}\u{631}\u{64a}\u{62f}\u{20}\u{625}\u{644}\u{63a}\u{627}\u{621}\u{20}\u{647}\u{630}\u{627}\u{20}\u{627}\u{644}\u{637}\u{644}\u{628}\u{61f}\u{20}\u{633}\u{64a}\u{62a}\u{645}\u{20}\u{625}\u{628}\u{644}\u{627}\u{63a}\u{20}\u{627}\u{644}\u{639}\u{645}\u{64a}\u{644}\u{2e}'
              : 'This will cancel the order and notify the customer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(loc.translate('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              loc.isArabic
                  ? '\u{625}\u{644}\u{63a}\u{627}\u{621}\u{20}\u{627}\u{644}\u{637}\u{644}\u{628}'
                  : 'Cancel order',
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _updateStatus(orderId, 'cancelled');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final service = SupabaseService();
    final courierId = service.isInitialized
        ? service.client.auth.currentUser?.id
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.isArabic
              ? '\u{637}\u{644}\u{628}\u{627}\u{62a}\u{20}\u{627}\u{644}\u{645}\u{646}\u{62f}\u{648}\u{628}'
              : 'Courier Orders',
        ),
        actions: [
          IconButton(
            onPressed: () => _loadOrders(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadOrders(showLoader: false),
              child: _orders.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 180),
                        Center(
                          child: Text(
                            loc.isArabic
                                ? '\u{644}\u{627}\u{20}\u{62a}\u{648}\u{62c}\u{62f}\u{20}\u{637}\u{644}\u{628}\u{627}\u{62a}\u{20}\u{645}\u{62a}\u{627}\u{62d}\u{629}\u{20}\u{627}\u{644}\u{622}\u{646}\u{2e}'
                                : 'No customer orders available.',
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        final status = order['status']?.toString() ?? 'placed';
                        final statusKey = status.toLowerCase();
                        final orderId = order['id']?.toString() ?? '';
                        final assignedCourierId = order['courier_id']
                            ?.toString();
                        final isMine =
                            courierId != null && assignedCourierId == courierId;
                        final isUnassigned =
                            assignedCourierId == null &&
                            (statusKey == 'placed' ||
                                statusKey == 'processing');
                        final isActive =
                            statusKey != 'delivered' &&
                            statusKey != 'cancelled';
                        final nextStatus = _nextStatus(status);
                        final isBusy = _busyOrderId == orderId;
                        final assignedName = order['courier_name']?.toString();

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.receipt_long_outlined),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Order $orderId',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Flexible(
                                      child: Chip(
                                        label: Text(
                                          _statusTitle(status, loc.isArabic),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  order['delivery_address']?.toString() ??
                                      (loc.isArabic
                                          ? '\u{644}\u{627}\u{20}\u{64a}\u{648}\u{62c}\u{62f}\u{20}\u{639}\u{646}\u{648}\u{627}\u{646}'
                                          : 'No address'),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${loc.isArabic ? '\u{627}\u{644}\u{625}\u{62c}\u{645}\u{627}\u{644}\u{64a}' : 'Total'}: ${(order['total'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'} ${loc.translate('sar')}',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isMine && isActive) ...[
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.end,
                                    children: [
                                      if (nextStatus != null)
                                        FilledButton.icon(
                                          onPressed: isBusy
                                              ? null
                                              : () => _updateStatus(
                                                  orderId,
                                                  nextStatus,
                                                ),
                                          icon: isBusy
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : const Icon(
                                                  Icons.update_rounded,
                                                  size: 18,
                                                ),
                                          label: Text(
                                            loc.isArabic
                                                ? '\u{62a}\u{62d}\u{62f}\u{64a}\u{62b}\u{20}\u{625}\u{644}\u{649}\u{20}${_statusTitle(nextStatus, true)}'
                                                : 'Mark ${_statusTitle(nextStatus, false)}',
                                          ),
                                        ),
                                      OutlinedButton.icon(
                                        onPressed: isBusy
                                            ? null
                                            : () =>
                                                  _confirmCancellation(orderId),
                                        icon: const Icon(
                                          Icons.cancel_outlined,
                                          color: Colors.red,
                                        ),
                                        label: Text(
                                          loc.isArabic
                                              ? '\u{625}\u{644}\u{63a}\u{627}\u{621}\u{20}\u{627}\u{644}\u{637}\u{644}\u{628}'
                                              : 'Cancel order',
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else if (isUnassigned && isActive) ...[
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: FilledButton.icon(
                                      onPressed: isBusy
                                          ? null
                                          : () => _claimOrder(orderId),
                                      icon: isBusy
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons
                                                  .assignment_turned_in_outlined,
                                              size: 18,
                                            ),
                                      label: Text(
                                        loc.isArabic
                                            ? '\u{627}\u{633}\u{62a}\u{644}\u{627}\u{645}\u{20}\u{627}\u{644}\u{637}\u{644}\u{628}'
                                            : 'Accept order',
                                      ),
                                    ),
                                  ),
                                ] else if (assignedCourierId != null &&
                                    !isMine &&
                                    isActive) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.lock_outline_rounded,
                                        size: 16,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          loc.isArabic
                                              ? '\u{627}\u{644}\u{637}\u{644}\u{628}\u{20}\u{645}\u{633}\u{62a}\u{644}\u{645}\u{20}\u{645}\u{646}\u{20}\u{645}\u{646}\u{62f}\u{648}\u{628}\u{20}${assignedName ?? ''}'
                                              : 'Accepted by ${assignedName ?? 'another courier'}',
                                          style: TextStyle(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  String? _nextStatus(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return 'onTheWay';
      case 'ontheway':
      case 'on_the_way':
        return 'delivered';
      default:
        return null;
    }
  }

  String _statusTitle(String status, bool isArabic) {
    if (!isArabic) {
      switch (status.toLowerCase()) {
        case 'ontheway':
        case 'on_the_way':
          return 'On the way';
        default:
          return status.isEmpty
              ? status
              : '${status[0].toUpperCase()}${status.substring(1)}';
      }
    }
    switch (status.toLowerCase()) {
      case 'placed':
        return '\u{62c}\u{62f}\u{64a}\u{62f}';
      case 'processing':
        return '\u{62c}\u{627}\u{631}\u{64a}\u{20}\u{627}\u{644}\u{62a}\u{62c}\u{647}\u{64a}\u{632}';
      case 'ontheway':
      case 'on_the_way':
        return '\u{641}\u{64a}\u{20}\u{627}\u{644}\u{637}\u{631}\u{64a}\u{642}';
      case 'delivered':
        return '\u{645}\u{633}\u{644}\u{645}';
      case 'cancelled':
        return '\u{645}\u{644}\u{63a}\u{649}';
      default:
        return status;
    }
  }
}
