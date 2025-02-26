import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_model.dart';

class PaymentModel {
  final String id;
  final String orderId;
  final String restaurantId;
  final String? customerId;
  final double amount;
  final double? taxAmount;
  final double? tipAmount;
  final PaymentStatus status;
  final String? transactionId;
  final String paymentMethod; // e.g., "credit_card", "debit_card", "upi", "wallet"
  final String? paymentGateway; // e.g., "razorpay", "stripe"
  final String? receiptUrl;
  final Map<String, dynamic>? paymentResponse;
  final String? error;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  PaymentModel({
    required this.id,
    required this.orderId,
    required this.restaurantId,
    this.customerId,
    required this.amount,
    this.taxAmount,
    this.tipAmount,
    required this.status,
    this.transactionId,
    required this.paymentMethod,
    this.paymentGateway,
    this.receiptUrl,
    this.paymentResponse,
    this.error,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return PaymentModel(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      customerId: data['customerId'],
      amount: (data['amount'] ?? 0).toDouble(),
      taxAmount: data['taxAmount']?.toDouble(),
      tipAmount: data['tipAmount']?.toDouble(),
      status: PaymentStatusExtension.fromString(data['status'] ?? 'pending'),
      transactionId: data['transactionId'],
      paymentMethod: data['paymentMethod'] ?? 'unknown',
      paymentGateway: data['paymentGateway'],
      receiptUrl: data['receiptUrl'],
      paymentResponse: data['paymentResponse'],
      error: data['error'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'orderId': orderId,
      'restaurantId': restaurantId,
      'customerId': customerId,
      'amount': amount,
      'taxAmount': taxAmount,
      'tipAmount': tipAmount,
      'status': status.name,
      'transactionId': transactionId,
      'paymentMethod': paymentMethod,
      'paymentGateway': paymentGateway,
      'receiptUrl': receiptUrl,
      'paymentResponse': paymentResponse,
      'error': error,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
  
  PaymentModel copyWith({
    String? id,
    String? orderId,
    String? restaurantId,
    String? customerId,
    double? amount,
    double? taxAmount,
    double? tipAmount,
    PaymentStatus? status,
    String? transactionId,
    String? paymentMethod,
    String? paymentGateway,
    String? receiptUrl,
    Map<String, dynamic>? paymentResponse,
    String? error,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      restaurantId: restaurantId ?? this.restaurantId,
      customerId: customerId ?? this.customerId,
      amount: amount ?? this.amount,
      taxAmount: taxAmount ?? this.taxAmount,
      tipAmount: tipAmount ?? this.tipAmount,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentGateway: paymentGateway ?? this.paymentGateway,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      paymentResponse: paymentResponse ?? this.paymentResponse,
      error: error ?? this.error,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  // Helper getters
  bool get isSuccessful => status == PaymentStatus.completed;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isPending => status == PaymentStatus.pending;
  bool get isRefunded => status == PaymentStatus.refunded;
  
  double get totalAmount {
    double total = amount;
    if (taxAmount != null) total += taxAmount!;
    if (tipAmount != null) total += tipAmount!;
    return total;
  }
} 