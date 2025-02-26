import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../models/order_model.dart';
import '../../screens/customer/menu_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  final String? specialInstructions;
  
  const CheckoutScreen({
    Key? key,
    required this.restaurantId,
    this.specialInstructions,
  }) : super(key: key);

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final priceFormatter = NumberFormat.currency(symbol: '\$');
  
  // Payment method selection
  String _selectedPaymentMethod = 'Credit Card';
  final List<String> _paymentMethods = [
    'Credit Card',
    'Debit Card',
    'UPI',
    'Wallet',
    'Cash',
  ];
  
  // Credit card form fields
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  
  // Delivery mode selection
  String _deliveryMode = 'Dine In'; // Default to dine-in
  
  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: cartState.items.isEmpty
          ? _buildEmptyCart()
          : _buildCheckoutForm(cartState),
    );
  }
  
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Add items from the menu to proceed with checkout',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Back to Cart'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCheckoutForm(CartState cartState) {
    // Calculate totals
    final subtotal = cartState.total;
    final tax = subtotal * 0.18; // 18% tax
    final total = subtotal + tax;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order summary section
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Item count and subtotal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Items (${cartState.items.length})'),
                      Text(priceFormatter.format(subtotal)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Tax
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tax (18%)'),
                      Text(priceFormatter.format(tax)),
                    ],
                  ),
                  
                  const Divider(height: 24),
                  
                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        priceFormatter.format(total),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  
                  if (widget.specialInstructions != null && widget.specialInstructions!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Special Instructions:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(widget.specialInstructions!),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Delivery Mode Section
          const Text(
            'Delivery Mode',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Dine In'),
                  value: 'Dine In',
                  groupValue: _deliveryMode,
                  onChanged: (value) {
                    setState(() {
                      _deliveryMode = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Takeaway'),
                  value: 'Takeaway',
                  groupValue: _deliveryMode,
                  onChanged: (value) {
                    setState(() {
                      _deliveryMode = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Payment Method Section
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Payment Method Selection
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _paymentMethods.map((method) {
              final isSelected = _selectedPaymentMethod == method;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedPaymentMethod = method;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getPaymentIcon(method),
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        method,
                        style: TextStyle(
                          color: isSelected ? Theme.of(context).primaryColor : Colors.black,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          
          // Payment details form based on selected method
          if (_selectedPaymentMethod == 'Credit Card' || _selectedPaymentMethod == 'Debit Card') ...[
            const SizedBox(height: 24),
            const Text(
              'Card Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Card holder name
            TextFormField(
              controller: _cardHolderController,
              decoration: const InputDecoration(
                labelText: 'Card Holder Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            
            // Card number
            TextFormField(
              controller: _cardNumberController,
              decoration: const InputDecoration(
                labelText: 'Card Number',
                border: OutlineInputBorder(),
                hintText: 'XXXX XXXX XXXX XXXX',
              ),
              keyboardType: TextInputType.number,
              maxLength: 19,
            ),
            
            // Expiry and CVV row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryDateController,
                    decoration: const InputDecoration(
                      labelText: 'Expiry Date',
                      border: OutlineInputBorder(),
                      hintText: 'MM/YY',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      border: OutlineInputBorder(),
                      hintText: 'XXX',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                    obscureText: true,
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Place order button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _placeOrder(total),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Place Order - ${priceFormatter.format(total)}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'Credit Card':
        return Icons.credit_card;
      case 'Debit Card':
        return Icons.credit_card;
      case 'UPI':
        return Icons.account_balance;
      case 'Wallet':
        return Icons.account_balance_wallet;
      case 'Cash':
        return Icons.money;
      default:
        return Icons.payment;
    }
  }
  
  void _placeOrder(double total) {
    final cartState = ref.read(cartProvider);
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    // Simulate order placement
    Future.delayed(const Duration(seconds: 2), () {
      // Close loading dialog
      Navigator.pop(context);
      
      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Order Placed Successfully!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text('Your order of ${priceFormatter.format(total)} has been placed.'),
              const SizedBox(height: 8),
              const Text('You will receive a confirmation shortly.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Clear cart
                ref.read(cartProvider.notifier).clearCart();
                
                // Navigate to order tracking screen
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppConstants.routeOrderTracking,
                  (route) => route.settings.name == AppConstants.routeDashboard,
                  arguments: {
                    'orderId': 'ORD${DateTime.now().millisecondsSinceEpoch}',
                    'restaurantId': widget.restaurantId,
                  },
                );
              },
              child: const Text('Track Order'),
            ),
          ],
        ),
      );
    });
  }
} 