import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/table_model.dart';
import '../services/firestore_service.dart';

// Reuse the firestore service provider from restaurant_provider.dart
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// QR code state for operations
class QRCodeState {
  final bool isLoading;
  final String? errorMessage;
  final String? scannedCode;
  final Map<String, dynamic>? decodedData;
  final String? generatedQRUrl;
  final TableModel? scannedTable;
  
  QRCodeState({
    this.isLoading = false,
    this.errorMessage,
    this.scannedCode,
    this.decodedData,
    this.generatedQRUrl,
    this.scannedTable,
  });
  
  QRCodeState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? scannedCode,
    Map<String, dynamic>? decodedData,
    String? generatedQRUrl,
    TableModel? scannedTable,
  }) {
    return QRCodeState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      scannedCode: scannedCode ?? this.scannedCode,
      decodedData: decodedData ?? this.decodedData,
      generatedQRUrl: generatedQRUrl ?? this.generatedQRUrl,
      scannedTable: scannedTable ?? this.scannedTable,
    );
  }
}

class QRCodeNotifier extends StateNotifier<QRCodeState> {
  final FirestoreService _firestoreService;
  
  QRCodeNotifier(this._firestoreService) : super(QRCodeState());
  
  // Process a scanned QR code
  Future<void> processScannedQRCode(String qrData) async {
    try {
      state = state.copyWith(
        isLoading: true, 
        errorMessage: null,
        scannedCode: qrData,
      );
      
      // Try to decode the QR data as JSON
      Map<String, dynamic> decodedData;
      try {
        decodedData = jsonDecode(qrData) as Map<String, dynamic>;
      } catch (e) {
        // If not valid JSON, create a simple map with raw value
        decodedData = {'raw': qrData};
      }
      
      // Check if it contains restaurant and table IDs
      final String? restaurantId = decodedData['restaurantId'];
      final String? tableId = decodedData['tableId'];
      
      if (restaurantId != null && tableId != null) {
        // This is a table QR code, fetch the table data
        final table = await _firestoreService.getTableById(restaurantId, tableId);
        
        if (table != null) {
          state = state.copyWith(
            isLoading: false,
            decodedData: decodedData,
            scannedTable: table,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            decodedData: decodedData,
            errorMessage: 'Table not found',
          );
        }
      } else {
        // Just store the decoded data without fetching a table
        state = state.copyWith(
          isLoading: false,
          decodedData: decodedData,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
  
  // Generate QR code data for a table
  String generateTableQRData(String restaurantId, String tableId) {
    final Map<String, dynamic> qrData = {
      'restaurantId': restaurantId,
      'tableId': tableId,
      'type': 'table',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    return jsonEncode(qrData);
  }
  
  // Save QR code URL for a table
  Future<bool> saveTableQRCodeUrl(String restaurantId, String tableId, String qrCodeUrl) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      await _firestoreService.updateTable(
        restaurantId, 
        tableId, 
        {'qrCodeUrl': qrCodeUrl},
      );
      
      state = state.copyWith(
        isLoading: false,
        generatedQRUrl: qrCodeUrl,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
  
  // Validate a table QR code
  bool isValidTableQR(Map<String, dynamic> decodedData) {
    return decodedData.containsKey('restaurantId') && 
           decodedData.containsKey('tableId') &&
           decodedData.containsKey('type') &&
           decodedData['type'] == 'table';
  }
  
  // Clear scanned data
  void clearScannedData() {
    state = state.copyWith(
      scannedCode: null,
      decodedData: null,
      scannedTable: null,
      errorMessage: null,
    );
  }
}

// QR code notifier provider
final qrCodeProvider = StateNotifierProvider<QRCodeNotifier, QRCodeState>((ref) {
  return QRCodeNotifier(ref.watch(firestoreServiceProvider));
}); 