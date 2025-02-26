import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/payment_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../services/payment_service.dart';
import '../services/notification_service.dart';

// Payment service provider
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Payment by ID provider
final paymentByIdProvider = FutureProvider.family<PaymentModel?, String>((ref, paymentId) async {
  final paymentService = ref.watch(paymentServiceProvider);
  return await paymentService.getPaymentById(paymentId);
});

// Customer payments provider
final customerPaymentsProvider = FutureProvider.family<List<PaymentModel>, String>((ref, customerId) async {
  final paymentService = ref.watch(paymentServiceProvider);
  return await paymentService.getCustomerPayments(customerId);
});

// Payment state for operations
class PaymentState {
  final bool isLoading;
  final String? errorMessage;
  final PaymentModel? currentPayment;
  final List<PaymentModel> paymentHistory;
  final OrderModel? orderToPay;
  final double? tipAmount;
  
  PaymentState({
    this.isLoading = false,
    this.errorMessage,
    this.currentPayment,
    this.paymentHistory = const [],
    this.orderToPay,
    this.tipAmount,
  });
  
  PaymentState copyWith({
    bool? isLoading,
    String? errorMessage,
    PaymentModel? currentPayment,
    List<PaymentModel>? paymentHistory,
    OrderModel? orderToPay,
    double? tipAmount,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      currentPayment: currentPayment ?? this.currentPayment,
      paymentHistory: paymentHistory ?? this.paymentHistory,
      orderToPay: orderToPay ?? this.orderToPay,
      tipAmount: tipAmount ?? this.tipAmount,
    );
  }
  
  // Calculate total amount including tip
  double get totalAmount {
    if (orderToPay == null) return 0;
    
    double total = orderToPay!.totalAmount;
    
    if (orderToPay!.taxAmount != null) {
      total += orderToPay!.taxAmount!;
    }
    
    if (tipAmount != null && tipAmount! > 0) {
      total += tipAmount!;
    }
    
    return total;
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  final PaymentService _paymentService;
  final NotificationService _notificationService;
  final Razorpay _razorpay = Razorpay();
  
  PaymentNotifier(this._paymentService, this._notificationService) : super(PaymentState()) {
    _initializeRazorpay();
  }
  
  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }
  
  // Initialize Razorpay
  void _initializeRazorpay() {
    _paymentService.initialize(
      onSuccess: _handlePaymentSuccess,
      onError: _handlePaymentError,
      onWalletSelected: _handleExternalWallet,
    );
  }
  
  // Handle payment success
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      if (state.orderToPay != null) {
        // Record the payment in Firestore
        final payment = await _paymentService.processPaymentSuccess(
          response,
          state.orderToPay!,
          null, // Customer data would be passed here if available
          'Restaurant', // Ideally get the restaurant name
        );
        
        // Send success notification
        await _notificationService.sendPaymentNotification(
          orderId: state.orderToPay!.id,
          success: true,
          amount: payment.amount,
          restaurantName: 'Restaurant', // Ideally get the restaurant name
        );
        
        state = state.copyWith(
          isLoading: false,
          currentPayment: payment,
          orderToPay: null,
          tipAmount: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No order selected for payment',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
  
  // Handle payment error
  void _handlePaymentError(PaymentFailureResponse response) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      if (state.orderToPay != null) {
        // Record the failed payment
        final payment = await _paymentService.processPaymentFailure(
          response,
          state.orderToPay!,
          null, // Customer data
        );
        
        // Send failure notification
        await _notificationService.sendPaymentNotification(
          orderId: state.orderToPay!.id,
          success: false,
          amount: state.totalAmount,
          restaurantName: 'Restaurant', // Ideally get the restaurant name
        );
        
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Payment failed: ${response.message}',
          currentPayment: payment,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Payment failed: ${response.message}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
  
  // Handle external wallet
  void _handleExternalWallet(ExternalWalletResponse response) {
    state = state.copyWith(
      errorMessage: 'External wallet selected: ${response.walletName}',
    );
  }
  
  // Set order to pay
  void setOrderToPay(OrderModel order) {
    state = state.copyWith(
      orderToPay: order,
      tipAmount: 0.0,
    );
  }
  
  // Set tip amount
  void setTipAmount(double amount) {
    state = state.copyWith(tipAmount: amount);
  }
  
  // Start payment process
  void startPayment({
    required UserModel? customer,
    required String restaurantName,
  }) {
    try {
      if (state.orderToPay == null) {
        state = state.copyWith(errorMessage: 'No order selected for payment');
        return;
      }
      
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      // Get customer info
      final String customerName = customer?.name ?? 'Guest';
      final String customerEmail = customer?.email ?? 'guest@example.com';
      final String customerPhone = customer?.phone ?? '';
      
      // Start payment
      _paymentService.startPayment(
        orderID: state.orderToPay!.id,
        amount: state.totalAmount,
        restaurantName: restaurantName,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        description: 'Payment for order #${state.orderToPay!.id}',
      );
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
  
  // Record a direct payment (cash, etc.)
  Future<PaymentModel?> recordDirectPayment({
    required String paymentMethod,
  }) async {
    try {
      if (state.orderToPay == null) {
        state = state.copyWith(errorMessage: 'No order selected for payment');
        return null;
      }
      
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      // Record the payment
      final payment = await _paymentService.recordPayment(
        orderId: state.orderToPay!.id,
        restaurantId: state.orderToPay!.restaurantId,
        customerId: state.orderToPay!.customerId,
        amount: state.orderToPay!.totalAmount,
        taxAmount: state.orderToPay!.taxAmount,
        tipAmount: state.tipAmount,
        status: PaymentStatus.completed,
        transactionId: null,
        paymentMethod: paymentMethod,
        paymentGateway: null,
      );
      
      // Send success notification
      await _notificationService.sendPaymentNotification(
        orderId: state.orderToPay!.id,
        success: true,
        amount: payment.amount,
        restaurantName: 'Restaurant', // Ideally get the restaurant name
      );
      
      state = state.copyWith(
        isLoading: false,
        currentPayment: payment,
        orderToPay: null,
        tipAmount: null,
      );
      
      return payment;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }
  
  // Load payment by ID
  Future<void> loadPayment(String paymentId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final payment = await _paymentService.getPaymentById(paymentId);
      
      state = state.copyWith(
        isLoading: false,
        currentPayment: payment,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
  
  // Load payment history for a customer
  Future<void> loadCustomerPayments(String customerId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final payments = await _paymentService.getCustomerPayments(customerId);
      
      state = state.copyWith(
        isLoading: false,
        paymentHistory: payments,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
  
  // Clear current payment
  void clearCurrentPayment() {
    state = state.copyWith(
      currentPayment: null,
      orderToPay: null,
      tipAmount: null,
    );
  }
}

// Payment notifier provider
final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier(
    ref.watch(paymentServiceProvider),
    ref.watch(notificationServiceProvider),
  );
}); 