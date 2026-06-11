import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simple/ModelClass/Report/Get_report_with_ordertype_model.dart';
import 'package:simple/Reusable/color.dart';
import 'package:simple/Reusable/constant.dart';
import 'package:simple/Reusable/space.dart';
import 'package:simple/Reusable/text_styles.dart';
import 'package:simple/UI/Home_screen/Widget/another_imin_printer/imin_abstract.dart';
import 'package:simple/UI/Home_screen/Widget/another_imin_printer/mock_imin_printer_chrome.dart';
import 'package:simple/UI/Home_screen/Widget/another_imin_printer/real_device_printer.dart';
import 'package:simple/UI/IminHelper/Report_helper.dart';
import 'package:simple/UI/IminHelper/printer_helper.dart';
import 'package:simple/services/tvse_printer_service.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

class ThermalReportReceiptDialog extends StatefulWidget {
  final GetReportModel getReportModel;
  final bool showItems;
  const ThermalReportReceiptDialog(this.getReportModel,
      {super.key, required this.showItems});

  @override
  State<ThermalReportReceiptDialog> createState() =>
      _ThermalReportReceiptDialogState();
}

class _ThermalReportReceiptDialogState
    extends State<ThermalReportReceiptDialog> {
  late IPrinterService printerService;
  final GlobalKey reportKey = GlobalKey();
  String? storedIpAddress;
  final TextEditingController ipController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadStoredIp();
    if (kIsWeb) {
      printerService = MockPrinterService();
    } else if (Platform.isAndroid) {
      printerService = RealPrinterService();
    } else {
      printerService = MockPrinterService();
    }
  }

  Future<void> _loadStoredIp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      storedIpAddress = prefs.getString('thermal_printer_ip');
      if (storedIpAddress != null) {
        ipController.text = storedIpAddress!;
      }
    });
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

  List<Data> _getAllItems(dynamic orderType) {
    List<Data> allItems = [];
    if (orderType == null) return allItems;

    if (orderType.data != null) {
      allItems.addAll(orderType.data!);
    }

    if (orderType.categories != null) {
      orderType.categories!.forEach((key, category) {
        if (category.data != null) {
          allItems.addAll(category.data!);
        }
      });
    }
    return allItems;
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    final reportLine = _getAllItems(widget.getReportModel.orderTypes?.line);
    final reportParcel = _getAllItems(widget.getReportModel.orderTypes?.parcel);
    final reportAc = _getAllItems(widget.getReportModel.orderTypes?.ac);
    final reportHd = _getAllItems(widget.getReportModel.orderTypes?.hd);
    final reportSwiggy = _getAllItems(widget.getReportModel.orderTypes?.swiggy);

    List<Map<String, dynamic>> itemsLine = reportLine
        .map((e) => {
              'name': e.productName,
              'qty': e.totalQty,
              'price': (e.unitPrice ?? 0).toDouble(),
              'total': (e.totalAmount ?? 0).toDouble(),
            })
        .toList();
    List<Map<String, dynamic>> itemsParcel = reportParcel
        .map((e) => {
              'name': e.productName,
              'qty': e.totalQty,
              'price': (e.unitPrice ?? 0).toDouble(),
              'total': (e.totalAmount ?? 0).toDouble(),
            })
        .toList();
    List<Map<String, dynamic>> itemsAc = reportAc
        .map((e) => {
              'name': e.productName,
              'qty': e.totalQty,
              'price': (e.unitPrice ?? 0).toDouble(),
              'total': (e.totalAmount ?? 0).toDouble(),
            })
        .toList();
    List<Map<String, dynamic>> itemsHd = reportHd
        .map((e) => {
              'name': e.productName,
              'qty': e.totalQty,
              'price': (e.unitPrice ?? 0).toDouble(),
              'total': (e.totalAmount ?? 0).toDouble(),
            })
        .toList();
    List<Map<String, dynamic>> itemsSwiggy = reportSwiggy
        .map((e) => {
              'name': e.productName,
              'qty': e.totalQty,
              'price': (e.unitPrice ?? 0).toDouble(),
              'total': (e.totalAmount ?? 0).toDouble(),
            })
        .toList();
    String businessName = widget.getReportModel.businessName ?? '';
    String userName = widget.getReportModel.userName ?? '';
    String address = widget.getReportModel.address ?? '';
    String location = widget.getReportModel.location ?? '';
    String tableName = widget.getReportModel.tableName ?? '';
    String waiterName = widget.getReportModel.waiterName ?? '';
    String fromDate = "";
    try {
      fromDate = DateFormat('dd/MM/yyyy').format(
        DateTime.parse(widget.getReportModel.fromDate.toString()),
      );
    } catch (e) {
      fromDate = widget.getReportModel.fromDate ?? "";
    }

    String toDate = "";
    try {
      toDate = DateFormat('dd/MM/yyyy').format(
        DateTime.parse(widget.getReportModel.toDate.toString()),
      );
    } catch (e) {
      toDate = widget.getReportModel.toDate ?? "";
    }
    String phone = widget.getReportModel.phone ?? '';
    double lineAmount =
        (widget.getReportModel.orderTypes?.line?.totalAmount ?? 0.0).toDouble();
    int lineQty =
        (widget.getReportModel.orderTypes?.line?.totalQty ?? 0.0).toInt();
    double parcelAmount =
        (widget.getReportModel.orderTypes?.parcel?.totalAmount ?? 0.0)
            .toDouble();
    int parcelQty =
        (widget.getReportModel.orderTypes?.parcel?.totalQty ?? 0.0).toInt();
    double acAmount =
        (widget.getReportModel.orderTypes?.ac?.totalAmount ?? 0.0).toDouble();
    int acQty = (widget.getReportModel.orderTypes?.ac?.totalQty ?? 0.0).toInt();
    double hdAmount =
        (widget.getReportModel.orderTypes?.hd?.totalAmount ?? 0.0).toDouble();
    int hdQty = (widget.getReportModel.orderTypes?.hd?.totalQty ?? 0.0).toInt();
    double swiggyAmount =
        (widget.getReportModel.orderTypes?.swiggy?.totalAmount ?? 0.0)
            .toDouble();
    int swiggyQty =
        (widget.getReportModel.orderTypes?.swiggy?.totalQty ?? 0.0).toInt();
    double totalAmount = (widget.getReportModel.finalAmount ?? 0.0).toDouble();
    int totalQty = (widget.getReportModel.finalQty ?? 0.0).toInt();
    String date = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());

    bool hasData = itemsLine.isNotEmpty ||
        itemsParcel.isNotEmpty ||
        itemsAc.isNotEmpty ||
        itemsHd.isNotEmpty ||
        itemsSwiggy.isNotEmpty;

    return !hasData
        ? Container(
            padding:
                EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.1),
            alignment: Alignment.center,
            child: Text(
              "No Report found",
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
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Center(
                          child: const Text(
                            "Report",
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

                    // Thermal Receipt Widget
                    RepaintBoundary(
                      key: reportKey,
                      child: getReportReceiptWidget(
                          businessName: businessName,
                          tamilTagline: "",
                          address: address,
                          phone: phone,
                          itemsLine: itemsLine,
                          itemsParcel: itemsParcel,
                          itemsAc: itemsAc,
                          itemsHd: itemsHd,
                          itemsSwiggy: itemsSwiggy,
                          reportDate: date,
                          takenBy: userName,
                          tableName: tableName,
                          waiterName: waiterName,
                          lineAmount: lineAmount,
                          lineQty: lineQty,
                          parcelAmount: parcelAmount,
                          parcelQty: parcelQty,
                          acAmount: acAmount,
                          acQty: acQty,
                          hdAmount: hdAmount,
                          hdQty: hdQty,
                          swiggyAmount: swiggyAmount,
                          swiggyQty: swiggyQty,
                          totalQuantity: totalQty,
                          totalAmount: totalAmount,
                          fromDate: fromDate,
                          toDate: toDate,
                          location: location,
                          showItems: widget.showItems),
                    ),

                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            // try {
                            //   await Future.delayed(
                            //       const Duration(milliseconds: 300));
                            //   await WidgetsBinding.instance.endOfFrame;
                            //   Uint8List? imageBytes =
                            //       await captureMonochromeReport(reportKey);
                            //
                            //   if (imageBytes != null) {
                            //     await printerService.init();
                            //     await printerService.printBitmap(imageBytes);
                            //     // await Future.delayed(
                            //     //     const Duration(seconds: 2));
                            //     await printerService.fullCut();
                            //     Navigator.pop(context);
                            //   }
                            // } catch (e) {
                            //   ScaffoldMessenger.of(context).showSnackBar(
                            //     SnackBar(content: Text("Print failed: $e")),
                            //   );
                            // }
                            WidgetsBinding.instance
                                .addPostFrameCallback((_) async {
                              debugPrint("Current Printer Type: ${Constants.currentPrinter}");
                              if (Constants.currentPrinter == PrinterType.tvs) {
                                await _printBillToTvsThermalOnly(context);
                              } else if (Constants.currentPrinter ==
                                  PrinterType.sunmi) {
                                await _printBillToSunmi(context);
                              } else if (Constants.currentPrinter ==
                                  PrinterType.imin) {
                                await _ensureIminServiceReady();
                                await _printReportToIminOnly(context);
                              } else if (Constants.currentPrinter ==
                                  PrinterType.external) {
                                if (storedIpAddress != null &&
                                    storedIpAddress!.isNotEmpty) {
                                  await _printReportToThermalOnly(
                                      context, storedIpAddress!);
                                } else {
                                  await _showPrinterIpDialog(context);
                                }
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
      );

      // user cancelled
      if (cutMode == null) {
        return;
      }*/

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
        reportKey,
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

    debugPrint("_printBillToSunmi pop view report");


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
      Uint8List? imageBytes = await captureMonochromeReceipt(reportKey);

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

  Future<void> _printReportToThermalOnly(
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
              Text("Preparing Report for thermal printer...",
                  style: TextStyle(color: whiteColor)),
            ],
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 300));
      await WidgetsBinding.instance.endOfFrame;

      Uint8List? imageBytes = await captureMonochromeReceipt(reportKey);
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
              content: Text("Report printed to thermal printer!"),
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
        throw Exception("Failed to capture report image");
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Report Print failed: $e"),
          backgroundColor: redColor,
        ),
      );
    }
  }

  Future<void> _ensureIminServiceReady() async {
    try {
      await printerService.init();
    } catch (e) {
      debugPrint("Error reinitializing IMIN service: $e");
    }
  }

  Future<void> _printReportToIminOnly(BuildContext context) async {
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

      Uint8List? imageBytes = await captureMonochromeReceipt(reportKey);

      if (imageBytes != null) {
        // await printerService.init();
        // await printerService.printBitmap(imageBytes);
        // await printerService.fullCut();
        final printer = FlutterTvsPrinter();

        final response = await printer.printReceipt(
          imageBytes,
          cutMode: "FEED",
        );
        print("ressss $response");

        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Report printed successfully to IMIN device!"),
              backgroundColor: greenColor,
            ),
          );
        }
      } else {
        throw Exception("Image capture failed: reportKey returned null");
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("IMIN Print failed: $e"),
            backgroundColor: redColor,
          ),
        );
      }
    }
  }
}
