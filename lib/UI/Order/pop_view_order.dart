import 'dart:developer';
import 'dart:io';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple/ModelClass/Order/Get_view_order_model.dart';
import 'package:simple/ModelClass/Location/get_location_details_model.dart';
import 'package:simple/data/repositories/order/order_repository.dart';
import 'package:simple/injector/injector.dart';
import 'package:simple/Reusable/color.dart';
import 'package:simple/Reusable/constant.dart';
import 'package:simple/Reusable/space.dart';
import 'package:simple/Reusable/text_styles.dart';
import 'package:simple/UI/Home_screen/Widget/another_imin_printer/imin_abstract.dart';
import 'package:simple/UI/Home_screen/Widget/another_imin_printer/mock_imin_printer_chrome.dart';
import 'package:simple/UI/Home_screen/Widget/another_imin_printer/real_device_printer.dart';
import 'package:simple/UI/IminHelper/printer_helper.dart';
import 'package:simple/UI/KOT_printer_helper/printer_kot_helper.dart';
import 'package:simple/services/tvse_printer_service.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

import '../../mobile_code/bluetooth_service.dart';

class ThermalReceiptDialog extends StatefulWidget {
  final GetViewOrderModel getViewOrderModel;

  const ThermalReceiptDialog(this.getViewOrderModel, {super.key});

  @override
  State<ThermalReceiptDialog> createState() => _ThermalReceiptDialogState();
}

class _ThermalReceiptDialogState extends State<ThermalReceiptDialog> {
  late IPrinterService printerService;
  late IPrinterService printerServiceThermal;
  GlobalKey normalReceiptKey = GlobalKey();
  GlobalKey kotReceiptKey = GlobalKey();

  List<BluetoothInfo> _devices = [];
  bool _isScanning = false;

  final TextEditingController ipController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String? storedIpAddress;
  String? _shopLogo;

  GetLocationDetailsModel? _locationDetails;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    // ipController.text = "192.168.1.123";
    if (kIsWeb) {
      printerService = MockPrinterService();
      printerServiceThermal = MockPrinterService();
    } else if (Platform.isAndroid) {
      printerService = RealPrinterService();
      printerServiceThermal = RealPrinterService();
    } else {
      printerService = MockPrinterService();
      printerServiceThermal = MockPrinterService();
    }
    _loadStoredIp();
    _loadShopLogo();
    _fetchLocationDetails();
  }

  Future<void> _fetchLocationDetails() async {
    try {
      final details = await injector<OrderRepository>().getLocationDetails();
      setState(() {
        _locationDetails = details;
        _isLoadingLocation = false;
        if (_locationDetails?.data?.posKotPrinterIpAddress != null &&
            _locationDetails!.data!.posKotPrinterIpAddress!.isNotEmpty) {
          ipController.text = _locationDetails!.data!.posKotPrinterIpAddress!;
        }
      });
    } catch (e) {
      debugPrint("Error fetching location details in dialog: $e");
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _loadStoredIp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      storedIpAddress = prefs.getString('thermal_printer_ip');
      if (storedIpAddress != null && storedIpAddress!.isNotEmpty) {
        ipController.text = storedIpAddress!;
      }
    });
  }

  Future<void> _loadShopLogo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _shopLogo = prefs.getString('shop_logo');
    });
  }

  Future<void> _ensureIminServiceReady() async {
    try {
      await printerService.init();
    } catch (e) {
      debugPrint("Error reinitializing IMIN service: $e");
    }
  }

  Future<void> _showPrinterIpDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("Thermal Printer Setup"),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: "Thermal Printer IP Address",
                hintText: "e.g. 192.168.1.96",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter printer IP";
                }
                final regex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
                if (!regex.hasMatch(value.trim())) {
                  return "Enter valid IP (e.g. 192.168.1.96)";
                }
                return null;
              },
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final ip = ipController.text.trim();
                  debugPrint("User entered IP: $ip");
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('thermal_printer_ip', ip);
                  setState(() {
                    storedIpAddress = ip;
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text("SUBMIT",
                  style: TextStyle(color: appPrimaryColor)),
            ),
          ],
        );
      },
    );
  }

  // Future<void> _scanBluetoothDevices() async {
  //   if (_isScanning) return;
  //
  //   setState(() {
  //     _isScanning = true;
  //     _devices.clear();
  //   });
  //
  //   try {
  //     // Check if Bluetooth is enabled
  //     final bool result = await PrintBluetoothThermal.bluetoothEnabled;
  //     if (!result) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text("Bluetooth is not enabled"),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //       setState(() => _isScanning = false);
  //       return;
  //     }
  //
  //     // Get paired Bluetooth devices
  //     final List<BluetoothInfo> bluetooths =
  //     await PrintBluetoothThermal.pairedBluetooths;
  //     setState(() {
  //       _devices = bluetooths;
  //       _isScanning = false;
  //     });
  //   } catch (e) {
  //     debugPrint("Error scanning Bluetooth devices: $e");
  //     setState(() => _isScanning = false);
  //   }
  // }


  final BluetoothPrintService _printService = BluetoothPrintService();

  static const String _bigLimit = '1000';
  Future<void> _scanBluetoothDevices() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _devices.clear();
    });

    try {
      // Request permissions
      await _printService.requestBluetoothPermissions();

      final bool result = await PrintBluetoothThermal.bluetoothEnabled;

      if (!result) {
        setState(() => _isScanning = false);
        return;
      }

      final List<BluetoothInfo> bluetooths =
      await PrintBluetoothThermal.pairedBluetooths;

      print("Found devices: ${bluetooths.length}");
      print(bluetooths);

      setState(() {
        _devices = bluetooths;
        _isScanning = false;
      });
    } catch (e) {
      print("Bluetooth Scan Error: $e");
      setState(() => _isScanning = false);
    }
  }
  Future<void> _selectBluetoothPrinter(BuildContext context) async {
    await _scanBluetoothDevices();

    if (_devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "No paired Bluetooth printers found. Please pair your printer first."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Select Bluetooth Printer",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _devices.length,
                itemBuilder: (_, index) {
                  final printer = _devices[index];
                  return ListTile(
                    leading: const Icon(Icons.print),
                    title: Text(
                        printer.name), // Changed from printer.name ?? "Unknown"
                    subtitle: Text(printer
                        .macAdress), // Changed from printer.address ?? ""
                    onTap: () {
                      Navigator.pop(context);
                      _startKOTPrintingBluetoothOnly(context, printer);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// BT KOT Print
  Future<void> _startKOTPrintingBluetoothOnly(
      BuildContext context, BluetoothInfo printer) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: appPrimaryColor),
              SizedBox(height: 16),
              Text("Preparing KOT for Bluetooth printer...",
                  style: TextStyle(color: whiteColor)),
            ],
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 300));
      await WidgetsBinding.instance.endOfFrame;

      Uint8List? imageBytes = await captureMonochromeKOTReceipt(kotReceiptKey);

      if (imageBytes != null) {
        final bool connectionResult = await PrintBluetoothThermal.connect(
            macPrinterAddress: printer.macAdress);

        if (!connectionResult) {
          throw Exception("Failed to connect to printer");
        }

        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm58, profile);

        final img.Image? decodedImage = img.decodeImage(imageBytes);
        if (decodedImage != null) {
          final img.Image resizedImage = img.copyResize(decodedImage, width: 360);

          List<int> resetBytes = generator.reset();
          await PrintBluetoothThermal.writeBytes(resetBytes);
          await Future.delayed(const Duration(milliseconds: 100));

          const int chunkHeight = 128;
          final int totalHeight = resizedImage.height;
          bool printResult = true;

          for (int y = 0; y < totalHeight; y += chunkHeight) {
            final int h = (y + chunkHeight > totalHeight) ? totalHeight - y : chunkHeight;
            final img.Image chunk = img.copyCrop(resizedImage, x: 0, y: y, width: resizedImage.width, height: h);

            List<int> chunkBytes = generator.imageRaster(chunk, align: PosAlign.center);
            printResult = await PrintBluetoothThermal.writeBytes(chunkBytes);
            if (!printResult) break;

            await Future.delayed(const Duration(milliseconds: 200));
          }

          if (printResult) {
            List<int> endBytes = [];
            endBytes += generator.cut();
            await PrintBluetoothThermal.writeBytes(endBytes);
          }

          await PrintBluetoothThermal.disconnect;

          Navigator.of(context).pop();

          if (printResult) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("KOT printed to Bluetooth printer!"),
                backgroundColor: greenColor,
              ),
            );
          }
          else
          {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Failed to send data to printer"),
                backgroundColor: redColor,
              ),
            );
          }
        }
      } else {
        Navigator.of(context).pop();
        throw Exception("Failed to capture KOT receipt image");
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("KOT Print failed: $e"),
          backgroundColor: redColor,
        ),
      );
    }
  }

  /// LAN KOT Print
  Future<void> _startKOTPrintingThermalOnly(
      BuildContext context, String printerIp) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: appPrimaryColor),
              SizedBox(height: 16),
              Text("Preparing KOT for thermal printer...",
                  style: TextStyle(color: whiteColor)),
            ],
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 300));
      await WidgetsBinding.instance.endOfFrame;

      Uint8List? imageBytes = await captureMonochromeKOTReceipt(kotReceiptKey);

      if (imageBytes != null) {
        final printer = PrinterNetworkManager(printerIp);
        final result = await printer.connect();

        if (result == PosPrintResult.success) {
          final profile = await CapabilityProfile.load();
          final generator = Generator(PaperSize.mm58, profile);

          final decodedImage = img.decodeImage(imageBytes);
          if (decodedImage != null) {
            final resizedImage = img.copyResize(
              decodedImage,
              width: 384, // 58mm = ~384 dots at 203 DPI
              maintainAspect: true,
            );
            List<int> bytes = [];
            bytes += generator.reset();
            bytes += generator.imageRaster(
              resizedImage,
              align: PosAlign.center,
              highDensityHorizontal: true, // Better quality
              highDensityVertical: true,
            );
            bytes += generator.feed(2);
            bytes += generator.cut();
            await printer.printTicket(bytes);
          }

          await printer.disconnect();

          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("KOT printed to thermal printer only!"),
              backgroundColor: greenColor,
            ),
          );
        } else {
          // ❌ Failed to connect
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to connect to printer (${result.msg})"),
              backgroundColor: redColor,
            ),
          );
        }
      } else {
        Navigator.of(context).pop();
        throw Exception("Failed to capture KOT receipt image");
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("KOT Print failed: $e"),
          backgroundColor: redColor,
        ),
      );
    }
  }

  Future<void> _printBillToThermalOnly(
      BuildContext context, String printerIp) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: appPrimaryColor),
              SizedBox(height: 16),
              Text("Preparing Bill for thermal printer...",
                  style: TextStyle(color: whiteColor)),
            ],
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 300));
      await WidgetsBinding.instance.endOfFrame;

      Uint8List? imageBytes = await captureMonochromeReceipt(normalReceiptKey);
      if (imageBytes != null) {
        final printer = PrinterNetworkManager(printerIp);
        final result = await printer.connect();

        if (result == PosPrintResult.success) {
          final profile = await CapabilityProfile.load();
          final generator = Generator(PaperSize.mm58, profile);

          final img.Image? decodedImage = img.decodeImage(imageBytes);
          if (decodedImage != null) {
            final resizedImage = img.copyResize(
              decodedImage,
              width: 384,
              maintainAspect: true,
            );
            List<int> bytes = [];
            bytes += generator.reset();
            bytes += generator.imageRaster(
              resizedImage,
              align: PosAlign.center,
              highDensityHorizontal: true,
              highDensityVertical: true,
            );
            bytes += generator.feed(2);
            bytes += generator.cut();
            await printer.printTicket(bytes);
          }

          await printer.disconnect();

          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Bill printed to thermal printer only!"),
              backgroundColor: greenColor,
            ),
          );
        } else {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to connect to printer (${result.msg})"),
              backgroundColor: redColor,
            ),
          );
        }
      } else {
        Navigator.of(context).pop();
        throw Exception("Failed to capture Bill receipt image");
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Bill Print failed: $e"),
          backgroundColor: redColor,
        ),
      );
    }
  }

  Future<void> _printBillToBluetoothOnly(
      BuildContext context, BluetoothInfo printer) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: appPrimaryColor),
              SizedBox(height: 16),
              Text("Preparing Bill for Bluetooth printer...",
                  style: TextStyle(color: whiteColor)),
            ],
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 300));
      await WidgetsBinding.instance.endOfFrame;

      Uint8List? imageBytes = await captureMonochromeReceipt(normalReceiptKey);

      if (imageBytes != null) {
        final bool connectionResult = await PrintBluetoothThermal.connect(
            macPrinterAddress: printer.macAdress);

        if (!connectionResult) {
          throw Exception("Failed to connect to printer");
        }

        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm58, profile);

        final img.Image? decodedImage = img.decodeImage(imageBytes);
        if (decodedImage != null) {
          final img.Image resizedImage = img.copyResize(decodedImage, width: 360);

          List<int> resetBytes = generator.reset();
          await PrintBluetoothThermal.writeBytes(resetBytes);
          await Future.delayed(const Duration(milliseconds: 100));

          const int chunkHeight = 128;
          final int totalHeight = resizedImage.height;
          bool printResult = true;

          for (int y = 0; y < totalHeight; y += chunkHeight) {
            final int h = (y + chunkHeight > totalHeight) ? totalHeight - y : chunkHeight;
            final img.Image chunk = img.copyCrop(resizedImage, x: 0, y: y, width: resizedImage.width, height: h);

            List<int> chunkBytes = generator.imageRaster(chunk, align: PosAlign.center);
            printResult = await PrintBluetoothThermal.writeBytes(chunkBytes);
            if (!printResult) break;

            await Future.delayed(const Duration(milliseconds: 200));
          }

          if (printResult) {
            List<int> endBytes = [];
            endBytes += generator.cut();
            await PrintBluetoothThermal.writeBytes(endBytes);
          }

          await PrintBluetoothThermal.disconnect;

          Navigator.of(context).pop();

          if (printResult) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Bill printed to Bluetooth printer!"),
                backgroundColor: greenColor,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Failed to send data to printer"),
                backgroundColor: redColor,
              ),
            );
          }
        }
      } else {
        Navigator.of(context).pop();
        throw Exception("Failed to capture receipt image");
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Bluetooth Print failed: $e"),
          backgroundColor: redColor,
        ),
      );
    }
  }

  Future<void> _selectBluetoothBillPrinter(BuildContext context) async {
    await _scanBluetoothDevices();

    if (_devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "No paired Bluetooth printers found. Please pair your printer first."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Select Bluetooth Printer for Bill",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _devices.length,
                itemBuilder: (_, index) {
                  final printer = _devices[index];
                  return ListTile(
                    leading: const Icon(Icons.print),
                    title: Text(printer.name),
                    subtitle: Text(printer.macAdress),
                    onTap: () {
                      Navigator.pop(context);
                      _printBillToBluetoothOnly(context, printer);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _printBillToTvsThermalOnly(
      BuildContext context,
      ) async {

    try {

      // 🔥 SELECT CUT MODE
      final cutMode = "FEED";
      /* await showModalBottomSheet<String>(
        context: context,
        builder: (context) {

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const SizedBox(height: 16),

                const Text(
                  "Select Printer Cut Mode",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                ListTile(
                  title: const Text("Normal Cut"),
                  onTap: () {
                    Navigator.pop(context, "NORMAL");
                  },
                ),

                ListTile(
                  title: const Text("Delay Cut"),
                  onTap: () {
                    Navigator.pop(context, "DELAY");
                  },
                ),

                ListTile(
                  title: const Text("Feed + Cut"),
                  onTap: () {
                    Navigator.pop(context, "FEED");
                  },
                ),

                ListTile(
                  title: const Text("Partial Cut"),
                  onTap: () {
                    Navigator.pop(context, "PARTIAL");
                  },
                ),

                ListTile(
                  title: const Text("ESC/POS Raw Cut"),
                  onTap: () {
                    Navigator.pop(context, "RAW");
                  },
                ),

                ListTile(
                  title: const Text("Large Feed Cut"),
                  onTap: () {
                    Navigator.pop(context, "LARGE_FEED");
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );*/

      // user cancelled
      // if (cutMode == null) {
      //   return;
      // }

      // 🔥 LOADING
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      Uint8List? imageBytes =
      await captureMonochromeReceipt(
        normalReceiptKey,
      );

      Navigator.pop(context);

      if (imageBytes == null) {
        throw Exception("Receipt image capture failed");
      }

      final printer = FlutterTvsPrinter();

      // 🔥 SEND CUT MODE
      final response =
      await printer.printReceipt(
        imageBytes,
        cutMode: cutMode,
      );

      String message = "";

      switch (response) {

        case "NORMAL_CUT_DONE":
          message =
          "Receipt printed using NORMAL CUT";
          break;

        case "DELAY_CUT_DONE":
          message =
          "Receipt printed using DELAY CUT";
          break;

        case "FEED_CUT_DONE":
          message =
          "Receipt printed using FEED + CUT";
          break;

        case "PARTIAL_CUT_DONE":
          message =
          "Receipt printed using PARTIAL CUT";
          break;

        case "RAW_CUT_DONE":
          message =
          "Receipt printed using ESC/POS RAW CUT";
          break;

        case "LARGE_FEED_CUT_DONE":
          message =
          "Receipt printed using LARGE FEED CUT";
          break;

        case "PAPER_OUT":
          message = "Printer paper out";
          break;

        case "PRINTER_BUSY":
          message = "Printer busy";
          break;

        case "PRINTER_FAULT":
          message = "Printer fault";
          break;

        case "PRINTER_OVERHEAT":
          message = "Printer overheated";
          break;

        case "PRINTER_NOT_AVAILABLE":
          message = "Printer not available";
          break;

        default:
          message = "Printing failed : $response";
      }

      /* ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );*/

    } catch (e) {

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Print failed: $e"),
        ),
      );
    }
  }

  Future<void> _printBillToSunmi(BuildContext context) async {

    debugPrint("_printBillToSunmi Pop view order");



    try {
      if (!context.mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: appPrimaryColor),
              SizedBox(height: 16),
              Text(
                "Printing to Sunmi device...",
                style: TextStyle(color: whiteColor),
              ),
            ],
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      await WidgetsBinding.instance.endOfFrame;

      // Capture the receipt with proper sizing for 58mm printer
      Uint8List? imageBytes = await captureMonochromeReceipt(normalReceiptKey);

      if (imageBytes == null) {
        Navigator.of(context).pop();
        throw Exception("Image capture failed: normalReceiptKey returned null");
      }

      // Initialize printer and print
      await SunmiPrinter.bindingPrinter();
      await SunmiPrinter.initPrinter();
      await SunmiPrinter.printImage(imageBytes);
      await SunmiPrinter.lineWrap(2);
      await SunmiPrinter.cutPaper();

      Navigator.of(context).pop();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bill printed successfully on Sunmi device!"),
            backgroundColor: greenColor,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Sunmi print failed: $e"),
            backgroundColor: redColor,
          ),
        );
      }
    }
  }


  /* Future<void> _printBillToTvsThermalOnly(
      BuildContext context,
      ) async {

    try {

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      Uint8List? imageBytes =
      await captureMonochromeReceipt(
        normalReceiptKey,
      );

      Navigator.pop(context);

      if (imageBytes == null) {
        throw Exception("Receipt image capture failed");
      }

      final printer = FlutterTvsPrinter();

      final response =
      await printer.printReceipt(imageBytes);

      String message = "";

      switch (response) {

        case "PRINT_SUCCESS_WITH_FULL_CUT":
          message =
          "Receipt printed with full cut";
          break;

        case "PRINT_SUCCESS_WITH_PARTIAL_CUT":
          message =
          "Receipt printed with partial cut";
          break;

        case "PRINT_SUCCESS_MANUAL_TEAR":
          message =
          "Receipt printed. Please tear manually.";
          break;

        case "PAPER_OUT":
          message = "Printer paper out";
          break;

        case "PRINTER_BUSY":
          message = "Printer busy";
          break;

        case "PRINTER_FAULT":
          message = "Printer fault";
          break;

        case "PRINTER_OVERHEAT":
          message = "Printer overheated";
          break;

        case "PRINTER_NOT_AVAILABLE":
          message = "Printer not available";
          break;

        default:
          message = "Printing failed";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

    } catch (e) {

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Print failed: $e"),
        ),
      );
    }
  }
*/
  Future<void> _printBillToIminOnly(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: appPrimaryColor,
              ),
              SizedBox(height: 16),
              Text("Printing to IMIN device...",
                  style: TextStyle(color: whiteColor)),
            ],
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      await WidgetsBinding.instance.endOfFrame;

      Uint8List? imageBytes = await captureMonochromeReceipt(normalReceiptKey);

      if (imageBytes != null) {

        final printer = FlutterTvsPrinter();

        final response = await printer.printReceipt(
          imageBytes,
          cutMode: "FEED",
        );

        debugPrint("Print Response: $response");
        // await printerService.init();
        // await printerService.printBitmap(imageBytes);
        // await printerService.fullCut();

        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bill printed successfully to IMIN device!"),
            backgroundColor: greenColor,
          ),
        );
      } else {
        throw Exception("Image capture failed: normalReceiptKey returned null");
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("IMIN Print failed: $e"),
          backgroundColor: redColor,
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.getViewOrderModel.data!;
    final invoice = order.invoice!;
    var size = MediaQuery.of(context).size;
    List<Map<String, dynamic>> items = order.items!
        .map((e) => {
      'name': e.name,
      'qty': e.quantity,
      'price': (e.unitPrice ?? 0).toDouble(),
      'total': ((e.quantity ?? 0) * (e.unitPrice ?? 0)).toDouble(),
    })
        .toList();
    List<Map<String, dynamic>> kotItems = invoice.kotItems!
        .map((e) => {
      'name': e.name,
      'qty': e.quantity,
    })
        .toList();
    List<Map<String, dynamic>> finalTax = order.finalTaxes!
        .map((e) => {
      'name': e.name,
      'amt': e.amount,
    })
        .toList();
    String businessName = invoice.businessName ?? '';
    String address = invoice.address ?? '';
    String gst = invoice.gstNumber ?? '';
    String description = invoice.description ?? '';
    double taxAmount = (order.tax ?? 0.0).toDouble();
    String orderNumber = order.orderNumber ?? 'N/A';
    String paymentMethod = invoice.paidBy ?? '';
    String phone = invoice.phone ?? '';
    double subTotal = (invoice.subtotal ?? 0.0).toDouble();
    double total = (invoice.total ?? 0.0).toDouble();
    String orderType = order.orderType ?? '';
    String orderStatus = order.orderStatus ?? '';
    String tableName = invoice.tableNum?.toString() ?? 'N/A';
    String waiterName = invoice.waiterNum?.toString() ?? 'N/A';
    String date = DateFormat('dd/MM/yyyy hh:mm a').format(
        DateFormat('M/d/yyyy, h:mm:ss a').parse(invoice.date.toString()));
    // Only set if not already set by stored IP or if stored IP is empty
    if (ipController.text.isEmpty) {
      ipController.text = invoice.thermalIp?.toString() ?? "";
    }
    debugPrint("ip:${ipController.text}");

    print("chekkk");
    print(_locationDetails?.data?.posKotPrinterConnectionType??"");
    return widget.getViewOrderModel.data == null
        ? Container(
        padding:
        EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.1),
        alignment: Alignment.center,
        child: Text(
          "No Orders found",
          style: MyTextStyle.f16(
            greyColor,
            weight: FontWeight.w500,
          ),
        ))
        : Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: SingleChildScrollView(
        child: Container(
          width: size.width * 0.4,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: whiteColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              if (_shopLogo != null && _shopLogo!.isNotEmpty) ...[
                Center(
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.center,
                      heightFactor: 0.65,
                      child: Image.network(
                        _shopLogo!,
                        height: 80,
                        width: 80,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Center(
                    child: const Text(
                      "Order Receipt",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              RepaintBoundary(
                key: normalReceiptKey,
                child: getThermalReceiptWidget(
                  businessName: businessName,
                  address: address,
                  gst: gst,
                  items: items,
                  finalTax: finalTax,
                  tax: taxAmount,
                  paidBy: paymentMethod,
                  tamilTagline: '',
                  phone: phone,
                  subtotal: subTotal,
                  total: total,
                  orderNumber: orderNumber,
                  tableName: tableName,
                  waiterName: waiterName,
                  orderType: orderType,
                  date: date,
                  status: orderStatus,
                  description: description,
                ),
              ),
              const SizedBox(height: 20),
              if (invoice.kotItems!.isNotEmpty)
                RepaintBoundary(
                  key: kotReceiptKey,
                  child: getThermalReceiptKOTWidget(
                    businessName: businessName,
                    address: address,
                    gst: gst,
                    items: kotItems,
                    paidBy: paymentMethod,
                    tamilTagline: '',
                    phone: phone,
                    subtotal: subTotal,
                    tax: taxAmount,
                    total: total,
                    orderNumber: orderNumber,
                    tableName: tableName,
                    waiterName: waiterName,
                    orderType: orderType,
                    date: date,
                    status: orderStatus,
                  ),
                ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoadingLocation)
                    const CircularProgressIndicator(color: appPrimaryColor)
                  else ...[
                    if ((_locationDetails?.data?.posPrinterName == "6a2847c1511210f35cbcd5b8") ||
                        (_locationDetails?.data?.posKotPrinterConnectionType != null &&
                            _locationDetails!.data!.posKotPrinterConnectionType!.isNotEmpty)) ...[
                      if (_locationDetails?.data?.posPrinterName == "6a2847c1511210f35cbcd5b8") ...[
                        ElevatedButton.icon(
                          onPressed: () async {
                            WidgetsBinding.instance.addPostFrameCallback((_) async {
                              await _printBillToTvsThermalOnly(context);
                            });
                          },
                          icon: const Icon(Icons.print),
                          label: const Text("Print"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: greenColor,
                            foregroundColor: whiteColor,
                          ),
                        ),
                        horizontalSpace(width: 10),
                      ],
                      if (_locationDetails?.data?.posKotPrinterConnectionType?.toUpperCase() == "WIFI") ...[
                        ElevatedButton.icon(
                          onPressed: () async {
                            WidgetsBinding.instance.addPostFrameCallback((_) async {
                              final String ip = (_locationDetails?.data?.posKotPrinterIpAddress != null &&
                                                  _locationDetails!.data!.posKotPrinterIpAddress!.isNotEmpty)
                                  ? _locationDetails!.data!.posKotPrinterIpAddress!
                                  : (storedIpAddress ?? (invoice.thermalIp?.toString() ?? ipController.text.trim()));
                              await _printBillToThermalOnly(context, ip);
                            });
                          },
                          icon: const Icon(Icons.wifi),
                          label: const Text("LAN/Wifi"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: greenColor,
                            foregroundColor: whiteColor,
                          ),
                        ),
                        horizontalSpace(width: 10),
                      ],
                      if (_locationDetails?.data?.posKotPrinterConnectionType?.toUpperCase() == "BLUETOOTH") ...[
                        // ElevatedButton.icon(
                        //   onPressed: () async {
                        //     WidgetsBinding.instance.addPostFrameCallback((_) async {
                        //       await _selectBluetoothBillPrinter(context);
                        //     });
                        //   },
                        //   icon: const Icon(Icons.bluetooth),
                        //   label: const Text("Bluetooth"),
                        //   style: ElevatedButton.styleFrom(
                        //     backgroundColor: greenColor,
                        //     foregroundColor: whiteColor,
                        //   ),
                        // ),
                        // horizontalSpace(width: 10),
                      ],
                    ] else ...[
                      // ElevatedButton.icon(
                      //   onPressed: () async {
                      //     WidgetsBinding.instance.addPostFrameCallback((_) async {
                      //       debugPrint("Current Printer Type: ${Constants.currentPrinter}");
                      //       if (Constants.currentPrinter == PrinterType.tvs) {
                      //         await _printBillToTvsThermalOnly(context);
                      //       } else if (Constants.currentPrinter == PrinterType.sunmi) {
                      //         await _printBillToSunmi(context);
                      //       } else if (Constants.currentPrinter == PrinterType.imin) {
                      //         await _ensureIminServiceReady();
                      //         await _printBillToIminOnly(context);
                      //       }
                      //     });
                      //   },
                      //   icon: const Icon(Icons.print),
                      //   label: const Text("Print"),
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: greenColor,
                      //     foregroundColor: whiteColor,
                      //   ),
                      // ),
                      // horizontalSpace(width: 10),
                    ],
                    ElevatedButton.icon(
                      onPressed: () async {
                        WidgetsBinding.instance.addPostFrameCallback((_) async {
                          await _selectBluetoothBillPrinter(context);
                        });
                      },
                      icon: const Icon(Icons.bluetooth),
                      label: const Text("Bluetooth"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: greenColor,
                        foregroundColor: whiteColor,
                      ),
                    ),
                    horizontalSpace(width: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        WidgetsBinding.instance.addPostFrameCallback((_) async {
                          debugPrint("Current Printer Type: ${Constants.currentPrinter}");
                          if (Constants.currentPrinter == PrinterType.tvs) {
                            await _printBillToTvsThermalOnly(context);
                          } else if (Constants.currentPrinter == PrinterType.sunmi) {
                            await _printBillToSunmi(context);
                          } else if (Constants.currentPrinter == PrinterType.imin) {
                            await _ensureIminServiceReady();
                            await _printBillToIminOnly(context);
                          }
                        });
                      },
                      icon: const Icon(Icons.print),
                      label: const Text("Print"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: greenColor,
                        foregroundColor: whiteColor,
                      ),
                    ),
                    horizontalSpace(width: 10),
                  ],
                  SizedBox(
                    width: size.width * 0.09,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "CLOSE",
                        style: TextStyle(color: appPrimaryColor),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Close Button
            ],
          ),
        ),
      ),
    );
  }
}
