import 'dart:typed_data';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
// import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

class BluetoothPrintService {
  static final BluetoothPrintService _instance = BluetoothPrintService._internal();
  factory BluetoothPrintService() => _instance;
  BluetoothPrintService._internal();

  static const String _lastDeviceKey = 'last_bluetooth_printer_mac';
  static const String _lastLanIpKey = 'last_lan_printer_ip';

  Future<bool> isBluetoothEnabled() async {
    return await PrintBluetoothThermal.bluetoothEnabled;
  }

  Future<bool> isConnected() async {
    return await PrintBluetoothThermal.connectionStatus;
  }

  Future<List<BluetoothInfo>> getPairedDevices() async {
    return await PrintBluetoothThermal.pairedBluetooths;
  }

  Future<bool> connect(String? macAddress) async {
    try {
      if (macAddress == null || macAddress.isEmpty) return false;

      // Ensure Bluetooth is enabled before connecting
      final bool enabled = await PrintBluetoothThermal.bluetoothEnabled;
      if (!enabled) return false;

      final bool connected = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      if (connected) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastDeviceKey, macAddress);
      }
      return connected;
    } catch (e) {
      debugPrint('Bluetooth Connect Error: $e');
      return false;
    }
  }

  Future<String?> getLastDevice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastDeviceKey);
  }

  Future<void> saveLastLanIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLanIpKey, ip);
  }

  Future<String?> getLastLanIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastLanIpKey);
  }

  Future<bool> printImage(Uint8List imageBytes) async {
    try {
      final CapabilityProfile profile = await CapabilityProfile.load();
      final Generator generator = Generator(PaperSize.mm58, profile);

      final img.Image? decoded = img.decodeImage(imageBytes);
      if (decoded == null) return false;

      // Resize to fit 58mm paper width (360px for cleaner output)
      final img.Image resized = img.copyResize(decoded, width: 360);

      // First, send a reset command to clear any leftover buffer data
      List<int> resetBytes = generator.reset();
      await PrintBluetoothThermal.writeBytes(resetBytes);
      await Future.delayed(const Duration(milliseconds: 100));

      // Split the image into small chunks to prevent buffer overflow
      const int chunkHeight = 128;
      final int totalHeight = resized.height;

      for (int y = 0; y < totalHeight; y += chunkHeight) {
        final int h = (y + chunkHeight > totalHeight) ? totalHeight - y : chunkHeight;
        // final img.Image chunk = img.copyCrop(resized, 0, y, resized.width, h);
        final img.Image chunk = img.copyCrop(
          resized,
          x: 0,
          y: y,
          width: resized.width,
          height: h,
        );

        List<int> chunkBytes = generator.imageRaster(chunk, align: PosAlign.center);
        final bool sent = await PrintBluetoothThermal.writeBytes(chunkBytes);
        if (!sent) return false;

        // Give the printer time to process each chunk
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // Feed paper and cut
      List<int> endBytes = [];
      // endBytes += generator.feed(0);
      endBytes += generator.cut();
      await PrintBluetoothThermal.writeBytes(endBytes);

      return true;
    } catch (e) {
      debugPrint('Bluetooth Print Error: $e');
      return false;
    }
  }

  Future<bool> autoConnect() async {
    try {
      final String? lastMac = await getLastDevice();
      if (lastMac != null) {
        return await connect(lastMac);
      }
    } catch (_) {}
    return false;
  }

  Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
    } catch (_) {}
  }

  Future<bool> requestBluetoothPermissions() async {
    if (Platform.isAndroid) {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

      if (androidInfo.version.sdkInt >= 31) {

        Map<Permission, PermissionStatus> statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
        ].request();

        bool granted = (statuses[Permission.bluetoothScan]?.isGranted ?? false) &&
            (statuses[Permission.bluetoothConnect]?.isGranted ?? false);

        if (!granted) {
          PermissionStatus locStatus = await Permission.location.request();
          granted = locStatus.isGranted;
        }
        return granted;
      } else {
        Map<Permission, PermissionStatus> statuses = await [
          Permission.location,
          Permission.bluetooth,
        ].request();
        return statuses[Permission.location]?.isGranted ?? false;
      }
    }
    return true;
  }

}
