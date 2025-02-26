import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';
import '../models/order_model.dart';
import '../models/payment_model.dart';
import '../models/user_model.dart';

class PaymentService {
  final Razorpay _razorpay = Razorpay();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Initialize Razorpay and attach listeners
  void initialize({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onError,
    required Function(ExternalWalletResponse) onWalletSelected,
  }) {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onWalletSelected);
  }
  
  // Clean up resources
  void dispose() {
    _razorpay.clear();
  }
  
  // Start payment process
  void startPayment({
    required String orderID,
    required double amount,
    required String restaurantName,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    String? description,
  }) {
    try {
      // Amount needs to be in paise (multiply by 100)
      final amountInPaise = (amount * 100).toInt();
      
      final options = {
        'key': AppConstants.razorpayKeyId,
        'amount': amountInPaise,
        'name': restaurantName,
        'description': description ?? 'Payment for Order #$orderID',
        'order_id': orderID, // For Razorpay internal reference
        'prefill': {
          'name': customerName,
          'email': customerEmail,
          'contact': customerPhone,
        },
        'theme': {
          'color': '#1E88E5',
        }
      };
      
      _razorpay.open(options);
    } catch (e) {
      if (kDebugMode) {
        print('Error starting payment: $e');
      }
      rethrow;
    }
  }
  
  // Record payment in Firestore
  Future<PaymentModel> recordPayment({
    required String orderId,
    required String restaurantId,
    required String? customerId,
    required double amount,
    required double? taxAmount,
    required double? tipAmount,
    required PaymentStatus status,
    required String? transactionId,
    required String paymentMethod,
    String? paymentGateway = 'razorpay',
    String? receiptUrl,
    Map<String, dynamic>? paymentResponse,
    String? error,
  }) async {
    try {
      final DateTime now = DateTime.now();
      
      final paymentData = PaymentModel(
        id: '', // Will be replaced with Firestore document ID
        orderId: orderId,
        restaurantId: restaurantId,
        customerId: customerId,
        amount: amount,
        taxAmount: taxAmount,
        tipAmount: tipAmount,
        status: status,
        transactionId: transactionId,
        paymentMethod: paymentMethod,
        paymentGateway: paymentGateway,
        receiptUrl: receiptUrl,
        paymentResponse: paymentResponse,
        error: error,
        createdAt: now,
        updatedAt: now,
      );
      
      // Add payment record to Firestore
      final docRef = await _firestore
          .collection('payments')
          .add(paymentData.toFirestore());
      
      // Update order payment status
      await _firestore
          .collection(AppConstants.restaurantsCollection)
          .doc(restaurantId)
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .update({
            'paymentStatus': status.name,
            'paymentId': docRef.id,
            'paymentMethod': paymentMethod,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      // Return payment model with generated ID
      return PaymentModel(
        id: docRef.id,
        orderId: orderId,
        restaurantId: restaurantId,
        customerId: customerId,
        amount: amount,
        taxAmount: taxAmount,
        tipAmount: tipAmount,
        status: status,
        transactionId: transactionId,
        paymentMethod: paymentMethod,
        paymentGateway: paymentGateway,
        receiptUrl: receiptUrl,
        paymentResponse: paymentResponse,
        error: error,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error recording payment: $e');
      }
      rethrow;
    }
  }
  
  // Process payment success
  Future<PaymentModel> processPaymentSuccess(
    PaymentSuccessResponse response, 
    OrderModel order,
    UserModel? customer,
    String restaurantName,
  ) async {
    try {
      return await recordPayment(
        orderId: order.id,
        restaurantId: order.restaurantId,
        customerId: order.customerId,
        amount: order.totalAmount,
        taxAmount: order.taxAmount,
        tipAmount: order.tipAmount,
        status: PaymentStatus.completed,
        transactionId: response.paymentId,
        paymentMethod: 'razorpay',
        paymentResponse: {
          'paymentId': response.paymentId,
          'orderId': response.orderId,
          'signature': response.signature,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error processing payment success: $e');
      }
      rethrow;
    }
  }
  
  // Process payment failure
  Future<PaymentModel> processPaymentFailure(
    PaymentFailureResponse response, 
    OrderModel order,
    UserModel? customer,
  ) async {
    try {
      return await recordPayment(
        orderId: order.id,
        restaurantId: order.restaurantId,
        customerId: order.customerId,
        amount: order.totalAmount,
        taxAmount: order.taxAmount,
        tipAmount: order.tipAmount,
        status: PaymentStatus.failed,
        transactionId: null,
        paymentMethod: 'razorpay',
        error: '${response.code}: ${response.message}',
        paymentResponse: {
          'code': response.code,
          'message': response.message,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error processing payment failure: $e');
      }
      rethrow;
    }
  }
  
  // Get payment history for a customer
  Future<List<PaymentModel>> getCustomerPayments(String customerId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('payments')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting customer payments: $e');
      }
      rethrow;
    }
  }
  
  // Get payment by ID
  Future<PaymentModel?> getPaymentById(String paymentId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('payments')
          .doc(paymentId)
          .get();
      
      if (doc.exists) {
        return PaymentModel.fromFirestore(doc);
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting payment: $e');
      }
      rethrow;
    }
  }
} 