import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../providers/qr_provider.dart';
import '../services/haptic_service.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  final Function(String) onScanComplete;

  const QrScannerScreen({super.key, required this.onScanComplete});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    facing: CameraFacing.back,
  );
  bool _isProcessing = false;
  bool _hasTorch = false;

  @override
  void initState() {
    super.initState();
    _initTorch();
  }

  void _initTorch() async {
    try {
      _hasTorch = await _controller.hasTorch;
      if (mounted) setState(() {});
    } catch (_) {}
  }


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(qrScannerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Scanner QR Code'),
        actions: [
          if (_hasTorch)
            IconButton(
              icon: const Icon(Icons.flash_on, color: Colors.white),
              onPressed: () async { await _controller.toggleTorch(); setState(() {}); },
            ),

          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              ref.read(qrScannerProvider.notifier).reset();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) async {
              if (_isProcessing) return;
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;
              final code = barcodes.first.rawValue;
              if (code == null) return;

              _isProcessing = true;
              HapticService.medium();

              final notifier = ref.read(qrScannerProvider.notifier);
              notifier.onScanComplete(code);

              final currentState = ref.read(qrScannerProvider);
              if (currentState.scannedData != null) {
                widget.onScanComplete(currentState.scannedData!);
                if (mounted) Navigator.pop(context);
              } else if (currentState.error != null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(currentState.error!), backgroundColor: Colors.red),
                  );
                }
              }

              _isProcessing = false;
            },
          ),
          Center(child: _buildOverlay()),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                borderRadius: 20,
                opacity: 0.2,
                child: const Column(
                  children: [
                    Text('📷 Scannez une facture Lightning', style: TextStyle(color: Colors.white, fontSize: 16)),
                    SizedBox(height: 4),
                    Text('Ou un code Crypto-Pay', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            border: Border.all(color: LiquidGlassTheme.accent, width: 3),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
