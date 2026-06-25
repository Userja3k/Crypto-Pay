import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:flutter/material.dart';


class BluetoothService {
  BluetoothService._internal();
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;

  final _devicesStreamController =
      StreamController<List<fbp.BluetoothDevice>>.broadcast();

  Stream<List<fbp.BluetoothDevice>> get devicesStream =>
      _devicesStreamController.stream;


  final _messageStreamController = StreamController<String>.broadcast();
  Stream<String> get messageStream => _messageStreamController.stream;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  fbp.BluetoothDevice? _connectedDevice;
  fbp.BluetoothCharacteristic? _characteristic;


  Future<bool> checkAvailability() async {
    try {
      final state = await fbp.FlutterBluePlus.instance.state.first;
      return state == fbp.BluetoothState.on;
    } catch (e) {
      debugPrint('Erreur Bluetooth: $e');
      return false;
    }
  }

  Future<void> startScan({int timeout = 10}) async {
    if (_isScanning) return;
    if (!await checkAvailability()) {
      throw Exception('Bluetooth non disponible');
    }

    _isScanning = true;
    _devicesStreamController.add([]);

    fbp.FlutterBluePlus.instance.scanResults.listen((results) {
      final devices = results.map((r) => r.device).toList();
      _devicesStreamController.add(devices);
    });

    await fbp.FlutterBluePlus.instance.startScan(timeout: Duration(seconds: timeout));
    _isScanning = false;
  }

  Future<void> stopScan() async {
    try {
      await fbp.FlutterBluePlus.instance.stopScan();
    } catch (e) {
      debugPrint('Erreur stop scan Bluetooth: $e');
    }
    _isScanning = false;
  }

  Future<void> connect(fbp.BluetoothDevice device) async {

    try {
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;
      _isConnected = true;

      final services = await device.discoverServices();
      const serviceUuid = '0000FFE0-0000-1000-8000-00805F9B34FB';
      const charUuid = '0000FFE1-0000-1000-8000-00805F9B34FB';

      final service = services.firstWhere(
        (s) => s.uuid.toString().toUpperCase() == serviceUuid.toUpperCase(),
        orElse: () => throw Exception('Service non trouvé'),
      );

      _characteristic = service.characteristics.firstWhere(
        (c) => c.uuid.toString().toUpperCase() == charUuid.toUpperCase(),
        orElse: () => throw Exception('Caractéristique non trouvée'),
      );

      await _characteristic!.setNotifyValue(true);
      _characteristic!.value.listen((value) {
        final message = utf8.decode(value);
        _messageStreamController.add(message);
      });
    } catch (e) {
      _isConnected = false;
      _connectedDevice = null;
      _characteristic = null;
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (e) {
        debugPrint('Erreur déconnexion Bluetooth: $e');
      }
    }
    _isConnected = false;
    _connectedDevice = null;
    _characteristic = null;
  }

  Future<void> sendMessage(String message) async {
    if (_characteristic == null) {
      throw Exception('Non connecté');
    }

    final bytes = utf8.encode(message);
    await _characteristic!.write(bytes, withoutResponse: true);
  }

  bool validatePayment(String message) {
    if (message.startsWith('lnbc') ||
        message.startsWith('lntb') ||
        message.startsWith('lnsb') ||
        message.startsWith('lnbcrt')) {
      return true;
    }
    if (message.startsWith('PAYMENT_SUCCESS')) {
      return true;
    }
    return false;
  }

  void dispose() {
    _devicesStreamController.close();
    _messageStreamController.close();
    // ignore: unawaited_futures
    disconnect();
  }
}

