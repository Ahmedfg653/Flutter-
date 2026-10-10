import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;
  String _studentName = '';
  String _studentId = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _studentName = prefs.getString('full_name') ?? '';
      _studentId = prefs.getString('student_id') ?? '';
    });
  }

  void _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final decoded = jsonDecode(rawValue);
      final String? serverUrl = decoded['server_url'];
      final String? token = decoded['token'];

      if (serverUrl == null || token == null) {
        _showDialog('Invalid QR Code', 'The scanned QR code is not recognized by the attendance system.', false);
        return;
      }

      final result = await ApiService.submitAttendance(
        targetUrl: serverUrl,
        token: token,
      );

      _showDialog(
        result['success'] ? 'Attendance Confirmed' : 'Verification Failed',
        result['message'],
        result['success'],
      );
    } catch (e) {
      _showDialog('Scan Error', 'Could not parse QR code data format.', false);
    }
  }

  void _showDialog(String title, String message, bool isSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          isSuccess ? Icons.check_circle : Icons.error,
          color: isSuccess ? Colors.green : Colors.red,
          size: 50,
        ),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (mounted) setState(() => _isProcessing = false);
              });
            },
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecture Scanner'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Disables back button
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
          ),
          // Viewfinder Target Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // Bottom Student Identity Ribbon (Read-Only)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black.withOpacity(0.85),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _studentName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Student ID: $_studentId (Device Bound)',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Point camera at the projector screen',
                    style: TextStyle(color: Colors.blueAccent, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
