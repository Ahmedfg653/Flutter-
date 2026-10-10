import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  static const _storage = FlutterSecureStorage();
  static const _keyDeviceUuid = 'device_immutable_uuid';

  /// Retrieves a persistent, hardware-linked UUID.
  /// Generates and permanently locks it into secure hardware-backed storage on first run.
  static Future<String> getDeviceUuid() async {
    String? storedUuid = await _storage.read(key: _keyDeviceUuid);
    if (storedUuid != null && storedUuid.isNotEmpty) {
      return storedUuid;
    }

    // Derive hardware identifier
    final deviceInfo = DeviceInfoPlugin();
    String hardwareSeed = '';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // Combines Android ID, hardware model, fingerprint
        hardwareSeed = '${androidInfo.id}_${androidInfo.hardware}_${androidInfo.brand}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        hardwareSeed = iosInfo.identifierForVendor ?? const Uuid().v4();
      }
    } catch (e) {
      hardwareSeed = const Uuid().v4();
    }

    // Fallback if hardware seed is blank
    if (hardwareSeed.isEmpty) {
      hardwareSeed = const Uuid().v4();
    }

    final newUuid = const Uuid().v5(Uuid.NAMESPACE_OID, hardwareSeed);
    await _storage.write(key: _keyDeviceUuid, value: newUuid);
    return newUuid;
  }
}
