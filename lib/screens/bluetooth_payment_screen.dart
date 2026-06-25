import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';
import '../providers/payment_provider.dart';
import '../services/haptic_service.dart';

class BluetoothPaymentScreen extends ConsumerStatefulWidget {
  const BluetoothPaymentScreen({super.key});

  @override
  ConsumerState<BluetoothPaymentScreen> createState() => _BluetoothPaymentScreenState();
}

class _BluetoothPaymentScreenState extends ConsumerState<BluetoothPaymentScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  BluetoothDevice? _selectedDevice;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    final bluetoothService = ref.read(bluetoothServiceProvider);
    try {
      await bluetoothService.startScan(timeout: 8);
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur scan Bluetooth : $e')),
        );
      }
    }
  }

  Future<void> _submitPayment() async {
    final amount = int.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un montant en sats valide.')),
      );
      return;
    }
    if (_selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un appareil Bluetooth.')),
      );
      return;
    }

    HapticService.medium();
    await ref.read(bluetoothPaymentProvider.notifier).payWithBluetooth(
          amountSats: amount,
          device: _selectedDevice!,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(bluetoothPaymentProvider);
    final devices = ref.watch(bluetoothDevicesProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Paiement Bluetooth'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sélectionnez un appareil et envoyez la facture sur le canal Bluetooth.', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            _buildAmountInput(),
            const SizedBox(height: 20),
            _buildNoteInput(),
            const SizedBox(height: 24),
            _buildDeviceList(devices),
            const SizedBox(height: 24),
            GlassButton(
              onPressed: paymentState.isLoading
                  ? () {}
                  : () {
                      _submitPayment();
                    },








              child: Text(paymentState.isLoading ? 'Appel en cours...' : 'Envoyer le paiement Bluetooth'),
            ),
            const SizedBox(height: 24),
            if (paymentState.status == PaymentStatus.success)
              GlassContainer(
                borderRadius: 24,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Paiement réussi', style: TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Hash : ${paymentState.paymentHash}', style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text('Sats envoyés : ${paymentState.amountSats}', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            if (paymentState.status == PaymentStatus.failure)
              GlassContainer(
                borderRadius: 24,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Erreur : ${paymentState.error}', style: const TextStyle(color: Colors.redAccent)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList(List<BluetoothDevice> devices) {
    if (devices.isEmpty) {
      return GlassContainer(
        borderRadius: 20,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Aucun appareil trouvé. Assurez-vous que votre appareil Bluetooth est en mode découverte.', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return GlassContainer(
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: devices.map((device) {
          final isSelected = _selectedDevice?.id == device.id;
          return ListTile(
            title: Text(device.name.isNotEmpty ? device.name : 'Appareil inconnu', style: const TextStyle(color: Colors.white)),
            subtitle: Text(device.id.id, style: const TextStyle(color: Colors.white54)),
            trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.greenAccent) : null,
            onTap: () { setState(() => _selectedDevice = device); },
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
}
