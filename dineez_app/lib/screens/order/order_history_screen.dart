import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../models/order_model.dart';
import '../../config/constants.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_display.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Load initial orders
    Future.microtask(() {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        ref.read(orderProvider.notifier).loadOrders(user.id);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    const threshold = 200.0; // Load more when user scrolls to this many pixels from bottom

    if (maxScroll - currentScroll <= threshold) {
      _loadMoreOrders();
    }
  }

  Future<void> _loadMoreOrders() async {
    final orderState = ref.read(orderProvider);
    
    if (!orderState.hasMoreOrders || orderState.isLoading) return;

    setState(() {
      _isLoadingMore = true;
    });

    await ref.read(orderProvider.notifier).loadMoreOrders();

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        actions: [
          PopupMenuButton<OrderStatus>(
            onSelected: (status) {
              ref.read(orderProvider.notifier).filterByStatus(status);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Orders'),
              ),
              PopupMenuItem(
                value: OrderStatus.new_,
                child: const Text('New Orders'),
              ),
              PopupMenuItem(
                value: OrderStatus.preparing,
                child: const Text('Preparing'),
              ),
              PopupMenuItem(
                value: OrderStatus.ready,
                child: const Text('Ready'),
              ),
              PopupMenuItem(
                value: OrderStatus.served,
                child: const Text('Served'),
              ),
              PopupMenuItem(
                value: OrderStatus.completed,
                child: const Text('Completed'),
              ),
            ],
          ),
        ],
      ),
      body: orderState.isLoading && !_isLoadingMore
          ? const Center(
              child: LoadingIndicator(),
            )
          : orderState.errorMessage != null
              ? ErrorDisplay(message: orderState.errorMessage!)
              : _buildOrderList(context, orderState),
    );
  }

  Widget _buildOrderList(BuildContext context, OrderState state) {
    if (state.orders.isEmpty) {
      return const Center(
        child: Text('No orders found'),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      itemCount: state.orders.length + (state.hasMoreOrders ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.orders.length) {
          if (_isLoadingMore) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: LoadingIndicator(size: 30.0),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final order = state.orders[index];
        return _buildOrderCard(context, order);
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppConstants.routeOrderDetails,
            arguments: {
              'restaurantId': order.restaurantId,
              'orderId': order.id,
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 8)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                'Restaurant: ${order.restaurantName}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4.0),
              Text(
                'Table: ${order.tableId ?? 'N/A'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4.0),
              Text(
                'Total: \$${order.totalAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Date: ${_formatDate(order.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
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