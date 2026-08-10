// lib/services/bluetooth_service.dart
// Version complète avec protocole Crypto-Pay

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// ════════════════════════════════════════════════════════════════
// PROTOCOLE CRYPTO-PAY BLE
// ════════════════════════════════════════════════════════════════

/// UUIDs du protocole Crypto-Pay
class CryptoPayBleUuid {
  static const String serviceUuid = "0000AFEE-0000-1000-8000-00805F9B34FB";
  static const String requestChar = "0000AFE1-0000-1000-8000-00805F9B34FB";
  static const String responseChar = "0000AFE2-0000-1000-8000-00805F9B34FB";
  static const String statusChar = "0000AFE3-0000-1000-8000-00805F9B34FB";
}

/// Types de messages
class BleMessageType {
  static const String handshake = "HANDSHAKE";
  static const String handshakeAck = "HANDSHAKE_ACK";
  static const String paymentRequest = "PAYMENT_REQUEST";
  static const String paymentResponse = "PAYMENT_RESPONSE";
  static const String paymentConfirmed = "PAYMENT_CONFIRMED";
  static const String paymentFailed = "PAYMENT_FAILED";
  static const String ack = "ACK";
  static const String error = "ERROR";
  static const String disconnect = "DISCONNECT";
}

/// Statuts de réponse
class BleResponseStatus {
  static const String confirmed = "CONFIRMED";
  static const String rejected = "REJECTED";
  static const String invoiceReady = "INVOICE_READY";
  static const String pending = "PENDING";
  static const String failed = "FAILED";
}

/// État Bluetooth
enum BleState {
  idle,
  scanning,
  connecting,
  handshake,
  requesting,
  waiting,
  processing,
  success,
  failure,
  timeout,
  cancelled,
}

// ════════════════════════════════════════════════════════════════
// MESSAGE STRUCTURÉ
// ════════════════════════════════════════════════════════════════

class BleMessage {
  final String type;
  final String version;
  final String? requestId;
  final Map<String, dynamic> payload;
  final String? signature;
  final int timestamp;

  BleMessage({
    required this.type,
    this.version = "1.0",
    this.requestId,
    this.payload = const {},
    this.signature,
    required this.timestamp,
  });

  String toJson() {
    return jsonEncode({
      'type': type,
      'version': version,
      'requestId': requestId,
      'payload': payload,
      'signature': signature,
      'timestamp': timestamp,
    });
  }

  factory BleMessage.fromJson(String json) {
    final data = jsonDecode(json);
    return BleMessage(
      type: data['type'] ?? 'UNKNOWN',
      version: data['version'] ?? '1.0',
      requestId: data['requestId'],
      payload: data['payload'] ?? {},
      signature: data['signature'],
      timestamp: data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  // ════════════════════════════════════════════════════════════
  // CONSTRUCTEURS PAR TYPE
  // ════════════════════════════════════════════════════════════

  static BleMessage handshake(String clientId, String publicKey) {
    return BleMessage(
      type: BleMessageType.handshake,
      requestId: _generateRequestId(),
      payload: {
        'clientId': clientId,
        'publicKey': publicKey,
      },
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  static BleMessage handshakeAck(String serverId, String publicKey, String sessionId) {
    return BleMessage(
      type: BleMessageType.handshakeAck,
      requestId: _generateRequestId(),
      payload: {
        'serverId': serverId,
        'publicKey': publicKey,
        'sessionId': sessionId,
      },
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  static BleMessage paymentRequest({
    required String bolt11,
    required int amountSats,
    required String senderId,
    String? memo,
    String? signature,
  }) {
    return BleMessage(
      type: BleMessageType.paymentRequest,
      requestId: _generateRequestId(),
      payload: {
        'bolt11': bolt11,
        'amount': amountSats,
        'senderId': senderId,
        'memo': memo ?? '',
        'currency': 'USD',
      },
      signature: signature,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  static BleMessage paymentResponse({
    required String requestId,
    required String status,
    String? bolt11,
    String? paymentHash,
    String? error,
  }) {
    return BleMessage(
      type: BleMessageType.paymentResponse,
      requestId: requestId,
      payload: {
        'status': status,
        'bolt11': bolt11,
        'paymentHash': paymentHash,
        'error': error,
      },
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  static BleMessage paymentConfirmed({
    required String requestId,
    required String paymentHash,
  }) {
    return BleMessage(
      type: BleMessageType.paymentConfirmed,
      requestId: requestId,
      payload: {
        'paymentHash': paymentHash,
      },
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  static BleMessage ack(String requestId) {
    return BleMessage(
      type: BleMessageType.ack,
      requestId: requestId,
      payload: {},
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  static BleMessage error(String requestId, String errorMsg) {
    return BleMessage(
      type: BleMessageType.error,
      requestId: requestId,
      payload: {'error': errorMsg},
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  static BleMessage disconnect() {
    return BleMessage(
      type: BleMessageType.disconnect,
      payload: {},
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  static String _generateRequestId() {
    return 'req_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }
}

// ════════════════════════════════════════════════════════════════
// RÉSULTAT
// ════════════════════════════════════════════════════════════════

class BleResult {
  final bool success;
  final String? bolt11;
  final String? paymentHash;
  final int? amountSats;
  final String? counterpartyName;
  final String? error;
  final BleState state;
  final BleMessage? message;

  BleResult({
    required this.success,
    this.bolt11,
    this.paymentHash,
    this.amountSats,
    this.counterpartyName,
    this.error,
    this.state = BleState.idle,
    this.message,
  });

  factory BleResult.success({
    required String bolt11,
    required String paymentHash,
    required int amountSats,
    String? counterpartyName,
    BleMessage? message,
  }) {
    return BleResult(
      success: true,
      bolt11: bolt11,
      paymentHash: paymentHash,
      amountSats: amountSats,
      counterpartyName: counterpartyName,
      state: BleState.success,
      message: message,
    );
  }

  factory BleResult.failure(String error, {BleState state = BleState.failure}) {
    return BleResult(
      success: false,
      error: error,
      state: state,
    );
  }

  factory BleResult.timeout() {
    return BleResult(
      success: false,
      error: 'Temps de connexion dépassé',
      state: BleState.timeout,
    );
  }

  factory BleResult.cancelled() {
    return BleResult(
      success: false,
      error: 'Opération annulée',
      state: BleState.cancelled,
    );
  }
}

// ════════════════════════════════════════════════════════════════
// SERVICE BLUETOOTH
// ════════════════════════════════════════════════════════════════

class BluetoothService {
  BluetoothService._internal();
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;

  // ════════════════════════════════════════════════════════════
  // STREAMS
  // ════════════════════════════════════════════════════════════

  final _devicesStreamController = StreamController<List<BluetoothDevice>>.broadcast();
  Stream<List<BluetoothDevice>> get devicesStream => _devicesStreamController.stream;

  final _messageStreamController = StreamController<BleMessage>.broadcast();
  Stream<BleMessage> get messageStream => _messageStreamController.stream;

  final _stateController = StreamController<BleState>.broadcast();
  Stream<BleState> get stateStream => _stateController.stream;

  // ════════════════════════════════════════════════════════════
  // ÉTAT
  // ════════════════════════════════════════════════════════════

  BleState _state = BleState.idle;
  BleState get state => _state;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _requestCharacteristic;
  BluetoothCharacteristic? _responseCharacteristic;

  // ════════════════════════════════════════════════════════════
  // INITIALISATION
  // ════════════════════════════════════════════════════════════

  Future<bool> checkAvailability() async {
    try {
      return await FlutterBluePlus.isSupported;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isBluetoothEnabled() async {
    try {
      final status = await FlutterBluePlus.adapterState.first;
      return status == BluetoothAdapterState.on;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestEnable() async {
    try {
      await FlutterBluePlus.turnOn();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // SCAN
  // ════════════════════════════════════════════════════════════

  Future<void> startScan({int timeout = 15}) async {
    if (_isScanning) return;
    if (!await checkAvailability()) {
      throw Exception('Bluetooth non disponible');
    }

    _isScanning = true;
    _setState(BleState.scanning);
    _devicesStreamController.add([]);

    final scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      final devices = results.map((result) => result.device).toList();
      _devicesStreamController.add(devices);
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: timeout),
        withServices: [Guid(CryptoPayBleUuid.serviceUuid)],
      );
    } finally {
      await scanSubscription.cancel();
      _isScanning = false;
      _setState(BleState.idle);
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint('Erreur stop scan: $e');
    }
    _isScanning = false;
    _setState(BleState.idle);
  }

  Stream<BluetoothDevice> scanCryptoPayDevices({
    Duration timeout = const Duration(seconds: 15),
  }) {
    final controller = StreamController<BluetoothDevice>();
    _setState(BleState.scanning);
    _isScanning = true;

    FlutterBluePlus.startScan(
      timeout: timeout,
      withServices: [Guid(CryptoPayBleUuid.serviceUuid)],
    ).catchError((e) {
      debugPrint('Erreur startScan: $e');
    });

    final subscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        controller.add(result.device);
      }
    });

    Timer(timeout, () {
      subscription.cancel();
      FlutterBluePlus.stopScan();
      _isScanning = false;
      _setState(BleState.idle);
      if (!controller.isClosed) {
        controller.close();
      }
    });

    return controller.stream;
  }

  // ════════════════════════════════════════════════════════════
  // CONNEXION AVEC HANDSHAKE
  // ════════════════════════════════════════════════════════════

  Future<BleResult> connectSecurely({
    required BluetoothDevice device,
    required String clientId,
    required String publicKey,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    _setState(BleState.connecting);
    final completer = Completer<BleResult>();
    Timer? timeoutTimer;

    timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        _setState(BleState.timeout);
        completer.complete(BleResult.timeout());
      }
    });

    try {
      // 1. Connexion
      await device.connect(
        license: fbp.License.nonprofit,
        timeout: timeout,
      );
      _connectedDevice = device;

      // 2. Découverte des services
      final services = await device.discoverServices();
      fbp.BluetoothService? cryptoService;

      for (final service in services) {
        if (service.uuid.toString().toUpperCase().contains(
            CryptoPayBleUuid.serviceUuid.toUpperCase().substring(0, 8))) {
          cryptoService = service;
          break;
        }
      }

      if (cryptoService == null) {
        throw Exception('Appareil non compatible Crypto-Pay');
      }

      // 3. Récupération des caractéristiques
      for (final char in cryptoService.characteristics) {
        final uuid = char.uuid.toString().toUpperCase();
        if (uuid.contains(CryptoPayBleUuid.requestChar.toUpperCase().substring(0, 8))) {
          _requestCharacteristic = char;
        } else if (uuid.contains(CryptoPayBleUuid.responseChar.toUpperCase().substring(0, 8))) {
          _responseCharacteristic = char;
        }
      }

      if (_requestCharacteristic == null || _responseCharacteristic == null) {
        throw Exception('Caractéristiques manquantes');
      }

      // 4. Souscription aux notifications
      await _responseCharacteristic!.setNotifyValue(true);
      _responseCharacteristic!.lastValueStream.listen((value) {
        _handleIncomingMessage(value);
      });

      // 5. Handshake
      _setState(BleState.handshake);
      final handshakeMsg = BleMessage.handshake(clientId, publicKey);
      await _sendMessage(handshakeMsg);

      // 6. Attente du handshake ACK
      final ack = await _waitForMessage(
        BleMessageType.handshakeAck,
        timeout: Duration(seconds: 10),
      );

      if (ack == null) {
        throw Exception('Handshake échoué');
      }

      _isConnected = true;
      _setState(BleState.idle);

      timeoutTimer.cancel();
      if (!completer.isCompleted) {
        completer.complete(BleResult.success(
          bolt11: '',
          paymentHash: '',
          amountSats: 0,
          counterpartyName: device.platformName,
        ));
      }

      return await completer.future;
    } catch (e) {
      _setState(BleState.failure);
      await _disconnect();
      timeoutTimer.cancel();
      if (!completer.isCompleted) {
        completer.complete(BleResult.failure('Erreur de connexion: $e'));
      }
      return await completer.future;
    }
  }

  // ════════════════════════════════════════════════════════════
  // ENVOI DE PAIEMENT (Payer)
  // ════════════════════════════════════════════════════════════

  Future<BleResult> sendPaymentRequest({
    required String bolt11,
    required int amountSats,
    required String senderId,
    String? memo,
    String? signature,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    if (!_isConnected) {
      return BleResult.failure('Aucun appareil connecté');
    }

    _setState(BleState.requesting);
    final completer = Completer<BleResult>();
    Timer? timeoutTimer;

    timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        _setState(BleState.timeout);
        completer.complete(BleResult.timeout());
      }
    });

    try {
      final requestMsg = BleMessage.paymentRequest(
        bolt11: bolt11,
        amountSats: amountSats,
        senderId: senderId,
        memo: memo,
        signature: signature,
      );

      await _sendMessage(requestMsg);

      final response = await _waitForMessage(
        BleMessageType.paymentResponse,
        timeout: timeout,
        requestId: requestMsg.requestId,
      );

      if (response == null) {
        throw Exception('Pas de réponse du destinataire');
      }

      final status = response.payload['status'] ?? '';
      final paymentHash = response.payload['paymentHash'];

      if (status == BleResponseStatus.confirmed) {
        _setState(BleState.success);
        timeoutTimer.cancel();
        if (!completer.isCompleted) {
          completer.complete(BleResult.success(
            bolt11: bolt11,
            paymentHash: paymentHash ?? '',
            amountSats: amountSats,
            counterpartyName: _connectedDevice?.platformName,
            message: response,
          ));
        }
      } else if (status == BleResponseStatus.rejected) {
        if (!completer.isCompleted) {
          completer.complete(BleResult.failure('Paiement rejeté'));
        }
      } else if (status == BleResponseStatus.failed) {
        final error = response.payload['error'] ?? 'Erreur inconnue';
        if (!completer.isCompleted) {
          completer.complete(BleResult.failure(error));
        }
      } else {
        if (!completer.isCompleted) {
          completer.complete(BleResult.failure('Statut inconnu: $status'));
        }
      }

      return await completer.future;
    } catch (e) {
      _setState(BleState.failure);
      timeoutTimer.cancel();
      if (!completer.isCompleted) {
        completer.complete(BleResult.failure('Erreur: $e'));
      }
      return await completer.future;
    }
  }

  // ════════════════════════════════════════════════════════════
  // RÉCEPTION DE PAIEMENT (Être payé)
  // ════════════════════════════════════════════════════════════

  Future<BleResult> receivePaymentRequest({
    required String serverId,
    required String serverPublicKey,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    _setState(BleState.waiting);
    final completer = Completer<BleResult>();
    Timer? timeoutTimer;

    timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        _setState(BleState.timeout);
        completer.complete(BleResult.timeout());
      }
    });

    try {
      final request = await _waitForMessage(
        BleMessageType.paymentRequest,
        timeout: timeout,
      );

      if (request == null) {
        throw Exception('Aucune demande reçue');
      }

      final bolt11 = request.payload['bolt11'] as String?;
      final amount = request.payload['amount'] as int?;
      final senderId = request.payload['senderId'] as String?;
      final _ = request.payload['memo'] as String?;

      if (bolt11 == null || amount == null) {
        await _sendMessage(BleMessage.error(
          request.requestId ?? 'unknown',
          'Données de paiement invalides',
        ));
        if (!completer.isCompleted) {
          completer.complete(BleResult.failure('Données de paiement invalides'));
        }
        return await completer.future;
      }

      final response = BleMessage.paymentResponse(
        requestId: request.requestId!,
        status: BleResponseStatus.confirmed,
        paymentHash: '',
      );
      await _sendMessage(response);

      _setState(BleState.success);
      timeoutTimer.cancel();
      if (!completer.isCompleted) {
        completer.complete(BleResult.success(
          bolt11: bolt11,
          paymentHash: '',
          amountSats: amount,
          counterpartyName: senderId,
          message: request,
        ));
      }

      return await completer.future;
    } catch (e) {
      _setState(BleState.failure);
      timeoutTimer.cancel();
      if (!completer.isCompleted) {
        completer.complete(BleResult.failure('Erreur: $e'));
      }
      return await completer.future;
    }
  }

  // ════════════════════════════════════════════════════════════
  // COMMUNICATION
  // ════════════════════════════════════════════════════════════

  Future<void> _sendMessage(BleMessage message) async {
    if (_requestCharacteristic == null) {
      throw Exception('Caractéristique non disponible');
    }

    final json = message.toJson();
    final bytes = utf8.encode(json);

    // Envoi par paquets (MTU typique: 20 octets)
    const mtu = 20;
    for (var i = 0; i < bytes.length; i += mtu) {
      final end = (i + mtu < bytes.length) ? i + mtu : bytes.length;
      final packet = bytes.sublist(i, end);
      await _requestCharacteristic!.write(packet, withoutResponse: false);
    }
  }

  Future<BleMessage?> _waitForMessage(
    String type, {
    Duration timeout = const Duration(seconds: 30),
    String? requestId,
  }) {
    final completer = Completer<BleMessage?>();
    Timer? timer;

    final subscription = _messageStreamController.stream.listen((message) {
      if (message.type == type && (requestId == null || message.requestId == requestId)) {
        if (!completer.isCompleted) {
          timer?.cancel();
          completer.complete(message);
        }
      }
    });

    timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        subscription.cancel();
        completer.complete(null);
      }
    });

    return completer.future;
  }

  void _handleIncomingMessage(List<int> value) {
    try {
      final json = utf8.decode(value);
      final message = BleMessage.fromJson(json);
      _messageStreamController.add(message);
    } catch (e) {
      // Ignore les messages invalides
    }
  }

  // ════════════════════════════════════════════════════════════
  // MÉTHODES DE COMPATIBILITÉ (pour l'existant)
  // ════════════════════════════════════════════════════════════

  /// Méthode de compatibilité avec l'ancienne interface
  Future<BleResult> connectAndSend(
    dynamic device,
    List<int> payload, {
    Duration timeout = const Duration(seconds: 10),
    String? serviceUuid,
    String? characteristicUuid,
  }) async {
    try {
      final targetDevice = device is BluetoothDevice
          ? device
          : (device as ScanResult).device;

      await targetDevice.connect(
        license: License.nonprofit,
        timeout: timeout,
      );
      final services = await targetDevice.discoverServices();

      BluetoothCharacteristic? characteristic;
      for (final service in services) {
        for (final candidate in service.characteristics) {
          final candidateUuid = candidate.uuid.toString().toLowerCase();
          final targetUuid = characteristicUuid?.toLowerCase();
          if (targetUuid != null) {
            if (candidateUuid == targetUuid) {
              characteristic = candidate;
              break;
            }
          } else if (candidate.properties.write ||
              candidate.properties.writeWithoutResponse) {
            characteristic = candidate;
            break;
          }
        }
        if (characteristic != null) break;
      }

      if (characteristic == null) {
        await targetDevice.disconnect();
        return BleResult.failure('Characteristic writable not found');
      }

      await characteristic.write(payload, withoutResponse: true);
      await targetDevice.disconnect();
      return BleResult.success(
        bolt11: utf8.decode(payload),
        paymentHash: '',
        amountSats: 0,
        counterpartyName: targetDevice.platformName,
      );
    } catch (e) {
      return BleResult.failure('Error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════
  // VALIDATION
  // ════════════════════════════════════════════════════════════

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

  // ════════════════════════════════════════════════════════════
  // DÉCONNEXION
  // ════════════════════════════════════════════════════════════

  Future<void> disconnect() async {
    try {
      if (_isConnected) {
        await _sendMessage(BleMessage.disconnect());
      }
    } catch (_) {}
    await _disconnect();
  }

  Future<void> _disconnect() async {
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _requestCharacteristic = null;
    _responseCharacteristic = null;
    _isConnected = false;
    _setState(BleState.idle);
  }

  // ════════════════════════════════════════════════════════════
  // UTILITAIRES
  // ════════════════════════════════════════════════════════════

  void _setState(BleState state) {
    _state = state;
    _stateController.add(state);
  }

  void dispose() {
    _devicesStreamController.close();
    _messageStreamController.close();
    _stateController.close();
    _disconnect();
  }
}