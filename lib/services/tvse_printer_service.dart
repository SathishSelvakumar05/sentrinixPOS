import 'package:flutter/services.dart';

class TvsePrinterService {
  // Define the channel name
  static const platform = MethodChannel('com.tvs.pos/printer');

  /// Sends a string to the native side to be printed
  Future<void> printText(String content) async {
    try {
      final String result = await platform.invokeMethod('printText', {
        "content": content,
      });
      print("Printer Status: $result");
    } on PlatformException catch (e) {
      print("Failed to print: '${e.message}'.");
    }
  }

  /// Commands the printer to cut the paper
  Future<void> cutPaper() async {
    try {
      await platform.invokeMethod('cutPaper');
    } on PlatformException catch (e) {
      print("Failed to cut: '${e.message}'.");
    }
  }
}

class FlutterTvsPrinter {

  static const MethodChannel _channel =
  MethodChannel('tvs_printer');

  Future<String?> printReceipt(
      Uint8List bytes, {
        required String cutMode,
      }) async {

    return await _channel.invokeMethod(
      "printBitmap",
      {
        "bytes": bytes,
        "cutMode": cutMode,
      },
    );
  }
}