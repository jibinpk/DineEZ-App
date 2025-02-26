import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../models/order_model.dart';
import '../../config/constants.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_display.dart';

class OrderDetailsScreen extends ConsumerWidget {
  final String restaurantId;
  final String orderId;

  const OrderDetailsScreen({
    super.key,
    required this.restaurantId,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailsProvider({
      'restaurantId': restaurantId,
      'orderId': orderId,
    }));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: orderAsync.when(
        data: (order) => _buildOrderDetails(context, order),
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stackTrace) => ErrorDisplay(
          message: 'Failed to load order details: $error',
          onRetry: () => ref.refresh(orderDetailsProvider({
            'restaurantId': restaurantId,
            'orderId': orderId,
          })),
        ),
      ),
    );
  }

  Widget _buildOrderDetails(BuildContext context, OrderModel order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderHeader(context, order),
          const Divider(height: 32.0),
          _buildRestaurantInfo(context, order),
          const SizedBox(height: 24.0),
          _buildOrderItems(context, order),
          const Divider(height: 32.0),
          _buildOrderSummary(context, order),
          if (order.specialInstructions?.isNotEmpty ?? false) ...[
            const SizedBox(height: 24.0),
            _buildSpecialInstructions(context, order),
          ],
          const SizedBox(height: 24.0),
          _buildOrderTimeline(context, order),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(BuildContext context, OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4.0),
                Text(
                  _formatDate(order.createdAt),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            _buildStatusChip(order.status),
          ],
        ),
      ],
    );
  }

  Widget _buildRestaurantInfo(BuildContext context, OrderModel order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restaurant Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8.0),
            Text(
              order.restaurantName,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (order.tableId != null) ...[
              const SizedBox(height: 4.0),
              Text(
                'Table: ${order.tableId}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems(BuildContext context, OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Items',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8.0),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            separatorBuilder: (context, index) => const Divider(height: 1.0),
            itemBuilder: (context, index) {
              final item = order.items[index];
              return ListTile(
                title: Text(item.name),
                subtitle: item.notes?.isNotEmpty ?? false
                    ? Text(item.notes!)
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('x${item.quantity}'),
                    const SizedBox(width: 16.0),
                    Text(
                      '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary(BuildContext context, OrderModel order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16.0),
            _buildSummaryRow(
              context,
              'Subtotal',
              '\$${order.subtotal.toStringAsFixed(2)}',
            ),
            if (order.taxAmount != null && order.taxAmount! > 0) ...[
              const SizedBox(height: 8.0),
              _buildSummaryRow(
                context,
                'Tax',
                '\$${order.taxAmount!.toStringAsFixed(2)}',
              ),
            ],
            if (order.tipAmount != null && order.tipAmount! > 0) ...[
              const SizedBox(height: 8.0),
              _buildSummaryRow(
                context,
                'Tip',
                '\$${order.tipAmount!.toStringAsFixed(2)}',
              ),
            ],
            const Divider(height: 24.0),
            _buildSummaryRow(
              context,
              'Total',
              '\$${order.totalAmount.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? Theme.of(context).textTheme.titleMedium
              : Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: isTotal
              ? Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )
              : Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildSpecialInstructions(BuildContext context, OrderModel order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Special Instructions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8.0),
            Text(
              order.specialInstructions!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTimeline(BuildContext context, OrderModel order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Timeline',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16.0),
            _buildTimelineItem(
              context,
              'Order Placed',
              order.createdAt,
              true,
            ),
            if (order.preparedAt != null)
              _buildTimelineItem(
                context,
                'Order Prepared',
                order.preparedAt!,
                true,
              ),
            if (order.servedAt != null)
              _buildTimelineItem(
                context,
                'Order Served',
                order.servedAt!,
                true,
              ),
            if (order.completedAt != null)
              _buildTimelineItem(
                context,
                'Order Completed',
                order.completedAt!,
                true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    String title,
    DateTime dateTime,
    bool isCompleted,
  ) {
    return Row(
      children: [
        Container(
          width: 20.0,
          height: 20.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
          child: isCompleted
              ? const Icon(
                  Icons.check,
                  size: 12.0,
                  color: Colors.white,
                )
              : null,
        ),
        const SizedBox(width: 16.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatDate(dateTime),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color chipColor;
    switch (status) {
      case OrderStatus.new_:
        chipColor = Colors.blue;
        break;
      case OrderStatus.preparing:
        chipColor = Colors.orange;
        break;
      case OrderStatus.ready:
        chipColor = Colors.green;
        break;
      case OrderStatus.served:
        chipColor = Colors.purple;
        break;
      case OrderStatus.completed:
        chipColor = Colors.grey;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Chip(
      label: Text(
        status.name.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.0,
        ),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
} 