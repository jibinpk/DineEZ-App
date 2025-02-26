import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:io';
import 'dart:developer';
import 'dart:convert';
import '../../config/constants.dart';
import '../../providers/providers.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_display.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isProcessing = false;
  bool _isFlashOn = false;
  bool _isCameraInitialized = false;
  String? _cameraError;

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  @override
  void dispose() {
    // Cancel any ongoing operations
    _isProcessing = false;
    
    // Clear scanned data
    ref.read(qrCodeProvider.notifier).clearScannedData();
    
    // Dispose of the controller
    controller?.dispose();
    super.dispose();
  }

  void _handleRetry() {
    if (_cameraError != null) {
      _retryCamera();
    } else {
      ref.invalidate(qrCodeProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrState = ref.watch(qrCodeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_off : Icons.flash_on),
            onPressed: _isCameraInitialized ? _toggleFlash : null,
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: _isCameraInitialized ? _flipCamera : null,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: _cameraError != null
                ? ErrorDisplay(
                    message: _cameraError!,
                    onRetry: _handleRetry,
                  )
                : !_isCameraInitialized
                    ? const Center(child: LoadingIndicator())
                    : _buildQrView(context),
          ),
          Expanded(
            flex: 1,
            child: _isProcessing
                ? const Center(child: LoadingIndicator())
                : qrState.errorMessage != null
                    ? ErrorDisplay(
                        message: qrState.errorMessage!,
                        onRetry: _handleRetry,
                      )
                    : qrState.scannedTable != null
                        ? _buildTableInfo(context, qrState)
                        : _buildInstructions(),
          ),
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 200.0
        : 300.0;
    // To ensure the Scanner view is properly sized after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: Theme.of(context).colorScheme.primary,
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 10,
        cutOutSize: scanArea,
      ),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
      _isCameraInitialized = true;
      _cameraError = null;
    });

    controller.scannedDataStream.listen(
      (scanData) {
        if (_isProcessing || scanData.code == null) return;
        _processQrCode(scanData.code!);
      },
      onError: (error) {
        setState(() {
          _cameraError = 'Camera error: $error';
          _isCameraInitialized = false;
        });
      },
    );
  }

  Future<void> _processQrCode(String qrCode) async {
    try {
      // Stop processing more QR codes while we handle this one
      setState(() => _isProcessing = true);
      
      // Pause camera to prevent multiple scans
      controller?.pauseCamera();
      
      // Process the QR code
      await ref.read(qrCodeProvider.notifier).processScannedQRCode(qrCode);
      
      // Get the current state after processing
      final qrState = ref.read(qrCodeProvider);
      
      if (qrState.scannedTable != null) {
        // This is a table QR code, navigate to restaurant menu
        if (mounted) {
          _navigateToRestaurantMenu(qrState);
        }
      } else if (qrState.decodedData != null) {
        // Show what was scanned but not recognized as a valid DineEZ table QR
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scanned code does not contain valid DineEZ table information.'),
              duration: Duration(seconds: 3),
            ),
          );
          
          // Resume camera after a short delay
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              controller?.resumeCamera();
              setState(() => _isProcessing = false);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing QR code: $e'),
            backgroundColor: Colors.red,
          ),
        );
        
        // Resume camera after error
        controller?.resumeCamera();
        setState(() => _isProcessing = false);
      }
    }
  }

  void _toggleFlash() {
    try {
      controller?.toggleFlash().then((_) async {
        final isFlashOn = await controller?.getFlashStatus() ?? false;
        if (mounted) {
          setState(() => _isFlashOn = isFlashOn);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isFlashOn ? 'Flash turned on' : 'Flash turned off'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to toggle flash'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _flipCamera() {
    try {
      controller?.flipCamera().then((_) {
        if (mounted) {
          setState(() => _isFlashOn = false);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera flipped'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to flip camera'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _retryCamera() {
    setState(() {
      _cameraError = null;
      _isCameraInitialized = false;
    });
    
    // Dispose of the old controller
    if (controller != null) {
      controller!.dispose();
      controller = null;
    }
    
    // The QRView will be rebuilt and _onQRViewCreated will be called again
  }

  void _navigateToRestaurantMenu(QRCodeState qrState) {
    if (qrState.scannedTable == null) return;
    
    Navigator.pushReplacementNamed(
      context,
      AppConstants.routeRestaurantDetails,
      arguments: {'restaurantId': qrState.scannedTable!.restaurantId},
    ).then((_) {
      // Clear the scanned data when returning from restaurant details
      ref.read(qrCodeProvider.notifier).clearScannedData();
      
      // Resume camera and processing
      if (mounted) {
        controller?.resumeCamera();
        setState(() => _isProcessing = false);
      }
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      setState(() {
        _cameraError = 'Camera permission is required to scan QR codes';
        _isCameraInitialized = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required to scan QR codes'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTableInfo(BuildContext context, QRCodeState qrState) {
    final table = qrState.scannedTable!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Table #${table.tableNumber}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Capacity: ${table.capacity} people',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _navigateToRestaurantMenu(qrState),
            child: const Text('View Menu'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text(
            'Scan a QR code on your table',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Position the QR code within the square',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 