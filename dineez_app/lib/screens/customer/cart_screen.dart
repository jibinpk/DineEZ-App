import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../models/menu_item_model.dart';
import '../../screens/customer/menu_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  
  const CartScreen({
    Key? key,
    required this.restaurantId,
  }) : super(key: key);

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final priceFormatter = NumberFormat.currency(symbol: '\$');
  final _specialInstructionsController = TextEditingController();
  
  @override
  void dispose() {
    _specialInstructionsController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Watch cart state
    final cartState = ref.watch(cartProvider);
    final cartItems = cartState.items.values.toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear cart',
              onPressed: () => _showClearCartConfirmation(),
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCart()
          : _buildCartItems(cartItems),
      bottomNavigationBar: cartItems.isEmpty
          ? null
          : _buildCheckoutBar(cartState),
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
            'Add items from the menu to get started',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Browse Menu'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCartItems(List<CartItem> cartItems) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cartItems.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final item = cartItems[index];
              return _buildCartItemTile(item);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _specialInstructionsController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Special Instructions',
              hintText: 'Allergies, preferences, etc.',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCartItemTile(CartItem cartItem) {
    final menuItem = cartItem.menuItem;
    
    return Dismissible(
      key: Key('cart-item-${menuItem.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) => ref.read(cartProvider.notifier).removeItem(menuItem.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: menuItem.image != null && menuItem.image!.isNotEmpty
                ? Image.network(
                    menuItem.image!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                      Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.restaurant, size: 30),
                      ),
                  )
                : Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.restaurant, size: 30),
                  ),
            ),
            const SizedBox(width: 16),
            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menuItem.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    priceFormatter.format(menuItem.effectivePrice),
                    style: TextStyle(
                      color: menuItem.hasDiscount ? Colors.red.shade700 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Quantity controls
                  Row(
                    children: [
                      _buildQuantityButton(
                        icon: Icons.remove,
                        onPressed: cartItem.quantity > 1
                            ? () => ref.read(cartProvider.notifier).updateQuantity(menuItem.id, cartItem.quantity - 1)
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          '${cartItem.quantity}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      _buildQuantityButton(
                        icon: Icons.add,
                        onPressed: () => ref.read(cartProvider.notifier).updateQuantity(menuItem.id, cartItem.quantity + 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Item subtotal
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  priceFormatter.format(cartItem.subtotal),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => ref.read(cartProvider.notifier).removeItem(menuItem.id),
                  iconSize: 20,
                  color: Colors.red.shade400,
                  tooltip: 'Remove item',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        color: onPressed == null ? Colors.grey.shade100 : Colors.white,
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
        iconSize: 18,
      ),
    );
  }
  
  Widget _buildCheckoutBar(CartState cartState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Price breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text(priceFormatter.format(cartState.total)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tax (18%)'),
                Text(priceFormatter.format(cartState.total * 0.18)),
              ],
            ),
            const Divider(height: 24),
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
                  priceFormatter.format(cartState.total * 1.18),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Checkout button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _proceedToCheckout(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Proceed to Checkout',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showClearCartConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
  
  void _proceedToCheckout() {
    // Save special instructions if any
    final specialInstructions = _specialInstructionsController.text.trim();
    
    // Navigate to checkout screen
    Navigator.pushNamed(
      context,
      AppConstants.routeCheckout,
      arguments: {
        'restaurantId': widget.restaurantId,
        'specialInstructions': specialInstructions,
      },
    );
  }
} 