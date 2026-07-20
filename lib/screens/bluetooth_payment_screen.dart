import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';
import '../core/widgets/payment_confirm_slider.dart';
import '../core/widgets/water_drop_success_overlay.dart';
import '../providers/payment_provider.dart';
import '../providers/user_provider.dart';
import '../services/haptic_service.dart';
import '../core/utils/ui_utils.dart';
import 'payment_success_screen.dart';

class BluetoothPaymentScreen extends ConsumerStatefulWidget {
  final bool initialReceiving;
  const BluetoothPaymentScreen({super.key, this.initialReceiving = false});

  @override
  ConsumerState<BluetoothPaymentScreen> createState() => _BluetoothPaymentScreenState();
}

class _BluetoothPaymentScreenState extends ConsumerState<BluetoothPaymentScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  BluetoothDevice? _selectedDevice;
  late bool _isReceiving;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _isReceiving = widget.initialReceiving;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isReceiving) {
        _startScan();
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    if (_isScanning) return;

    setState(() => _isScanning = true);

    try {
      final bluetoothService = ref.read(bluetoothServiceProvider);
      ref.read(bluetoothDevicesProvider.notifier).state = [];

      final devices = <BluetoothDevice>[];
      await for (final device in bluetoothService.scanCryptoPayDevices(
        timeout: const Duration(seconds: 15),
      )) {
        if (!devices.contains(device)) {
          devices.add(device);
          ref.read(bluetoothDevicesProvider.notifier).state = List.from(devices);
        }
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showErrorDialog(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _submitPayment() async {
    if (_isReceiving) {
      HapticService.medium();
      await ref.read(bluetoothPaymentProvider.notifier).receiveWithBluetooth(
            note: _noteController.text.isNotEmpty ? _noteController.text : null,
          );
      _checkPaymentSuccess();
    } else {
      final amount = int.tryParse(_amountController.text);
      if (amount == null || amount <= 0) {
        UIUtils.showErrorDialog(context, 'Veuillez saisir un montant en sats valide.');
        return;
      }

      if (_selectedDevice == null) {
        UIUtils.showErrorDialog(context, 'Sélectionnez un appareil.');
        return;
      }

      HapticService.medium();
      await ref.read(bluetoothPaymentProvider.notifier).payWithBluetooth(
            amountSats: amount,
            device: _selectedDevice!,
            note: _noteController.text.isNotEmpty ? _noteController.text : null,
          );
      _checkPaymentSuccess();
    }
  }

  void _checkPaymentSuccess() {
    final paymentState = ref.read(bluetoothPaymentProvider);
    if (paymentState.status == BluetoothStatus.success) {
      if (mounted) {
        final amount = (paymentState.amountSats ?? 0).toDouble();
        final counterparty = paymentState.counterpartyName ?? 'Bluetooth';
        WaterDropSuccessOverlay.show(context, () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentSuccessScreen(
                amount: amount,
                recipient: counterparty,
              ),
            ),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(bluetoothPaymentProvider);
    final devices = ref.watch(bluetoothDevicesProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Bluetooth'),
        actions: [
          ToggleButtons(
            isSelected: [!_isReceiving, _isReceiving],
            onPressed: (index) {
              setState(() {
                _isReceiving = index == 1;
                _selectedDevice = null;
              });
              ref.read(bluetoothPaymentProvider.notifier).reset();
              if (index == 0) {
                _startScan();
              }
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Payer'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Recevoir'),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isReceiving
                  ? 'En attente d\'une demande de paiement Bluetooth...'
                  : 'Sélectionnez un appareil pour envoyer un paiement',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            if (!_isReceiving) ...[
              _buildAmountInput(),
              const SizedBox(height: 20),
              _buildNoteInput(),
              const SizedBox(height: 24),
              _buildDeviceList(devices),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      isPrimary: false,
                      onPressed: _isScanning ? null : _startScan,
                      child: Text(_isScanning ? 'Recherche en cours...' : '🔄 Rechercher les appareils'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_selectedDevice != null) ...[
                PaymentConfirmSlider(
                  isLoading: paymentState.isLoading,
                  onConfirm: _submitPayment,
                  label: 'Glisser pour payer via Bluetooth',
                ),
                const SizedBox(height: 24),
              ]
            ] else ...[
              _buildNoteInput(),
              const SizedBox(height: 24),
              GlassButton(
                onPressed: paymentState.isLoading ? null : _submitPayment,
                child: Text(paymentState.isLoading ? 'En attente...' : 'Démarrer la réception'),
              ),
              const SizedBox(height: 24),
            ],
            _buildStatusCard(paymentState),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList(List<BluetoothDevice> devices) {
    if (devices.isEmpty && !_isScanning) {
      return GlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.all(16),
        child: const Text(
          'Aucun appareil Crypto-Pay trouvé. Vérifiez que l\'autre appareil est en mode réception.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    if (devices.isEmpty && _isScanning) {
      return GlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.all(16),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: LiquidGlassTheme.accent),
            ),
            SizedBox(width: 12),
            Text('Recherche en cours...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: devices.map((device) {
          final isSelected = _selectedDevice?.remoteId == device.remoteId;
          return ListTile(
            title: Text(
              device.platformName.isNotEmpty ? device.platformName : 'Appareil inconnu',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              device.remoteId.str.substring(0, min(8, device.remoteId.str.length)),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: Colors.greenAccent)
                : null,
            onTap: () => setState(() => _selectedDevice = device),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAmountInput() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 20,
      child: TextField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: false),
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Montant en sats',
          hintStyle: TextStyle(color: Colors.white38),
          prefixIcon: Icon(Icons.payments_outlined, color: Colors.white38),
        ),
      ),
    );
  }

  Widget _buildNoteInput() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 20,
      child: TextField(
        controller: _noteController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Note (optionnel)',
          hintStyle: TextStyle(color: Colors.white38),
          prefixIcon: Icon(Icons.sticky_note_2_outlined, color: Colors.white38),
        ),
      ),
    );
  }

  Widget _buildStatusCard(BluetoothPaymentState state) {
    if (state.status == BluetoothStatus.success) {
      return GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                SizedBox(width: 8),
                Text('Paiement réussi', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            if (state.paymentHash != null && state.paymentHash!.isNotEmpty)
              Text('Hash: ${state.paymentHash}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            if (state.amountSats != null)
              Text('Montant: ${state.amountSats} sats', style: const TextStyle(color: Colors.white70)),
            if (state.counterpartyName != null)
              Text('De/Vers: ${state.counterpartyName}', style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 8),
            GlassButton(
              onPressed: () => ref.read(bluetoothPaymentProvider.notifier).reset(),
              child: const Text('Nouvelle opération'),
            ),
          ],
        ),
      );
    }

    if (state.status == BluetoothStatus.failure) {
      return GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                SizedBox(width: 8),
                Text('Erreur', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(state.error ?? 'Erreur inconnue', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            GlassButton(
              onPressed: () => ref.read(bluetoothPaymentProvider.notifier).reset(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (state.isLoading) {
      return GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircularProgressIndicator(color: LiquidGlassTheme.accent),
            const SizedBox(height: 12),
            Text(
              _isReceiving ? 'Mode visibilité activé, en attente...' : 'Connexion et paiement en cours...',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
