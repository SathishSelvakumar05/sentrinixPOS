import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simple/ModelClass/ShiftClosing/getShiftClosingModel.dart';
import 'package:simple/ModelClass/ShopDetails/getStockMaintanencesModel.dart';
import 'package:simple/Reusable/color.dart';
import 'package:simple/Reusable/space.dart';
import 'package:simple/Reusable/text_styles.dart';
import 'package:simple/UI/Home_screen/Widget/another_imin_printer/imin_abstract.dart';
import 'package:simple/UI/Home_screen/Widget/another_imin_printer/real_device_printer.dart';
import 'package:simple/UI/ShiftClosing/shift_closing_helper.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';

import '../Home_screen/Widget/another_imin_printer/mock_imin_printer_chrome.dart';

class ThermalShiftClosingDialog extends StatefulWidget {
  final GetShiftClosingModel getShiftClosingModel;
  final GetStockMaintanencesModel getStockMaintanencesModel;
  final String upi;
  final String card;
  final String hd;
  final String cash;
  final String cashDifference;
  const ThermalShiftClosingDialog(
    this.getShiftClosingModel,
    this.getStockMaintanencesModel, {
    super.key,
    required this.upi,
    required this.card,
    required this.hd,
    required this.cash,
    required this.cashDifference,
  });

  @override
  State<ThermalShiftClosingDialog> createState() =>
      _ThermalShiftClosingDialogState();
}

class _ThermalShiftClosingDialogState extends State<ThermalShiftClosingDialog> {
  late IPrinterService printerService;
  final GlobalKey shiftKey = GlobalKey();
  final TextEditingController ipLanController = TextEditingController();
  @override
  void initState() {
    // ipLanController.text = "192.168.1.123";
    super.initState();
    if (kIsWeb) {
      printerService = MockPrinterService();
    } else if (Platform.isAndroid) {
      printerService = RealPrinterService();
    } else {
      printerService = MockPrinterService();
    }
  }

  Future<void> _ensureIminServiceReady() async {
    try {
      await printerService.init();
    } catch (e) {
      debugPrint("Error reinitializing IMIN service: $e");
    }
  }

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

      Uint8List? imageBytes = await captureMonochromeShiftReport(shiftKey);

      if (imageBytes != null) {
        await printerService.init();
        await printerService.printBitmap(imageBytes);
        await printerService.fullCut();

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
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    String businessName = widget.getStockMaintanencesModel.data?.name ?? '';
    String address =
        widget.getStockMaintanencesModel.data?.location?.address ?? '';
    String city = widget.getStockMaintanencesModel.data?.location?.city ?? '';
    String state = widget.getStockMaintanencesModel.data?.location?.state ?? '';
    String pinCode =
        widget.getStockMaintanencesModel.data?.location?.zipCode ?? '';
    final rawDate = widget.getShiftClosingModel.data?.filtersUsed?.date ?? "";
    final parsedDate = DateTime.tryParse(rawDate);

    String fromDate =
        parsedDate != null ? DateFormat('dd/MM/yyyy').format(parsedDate) : "";
    String phone = widget.getStockMaintanencesModel.data?.contactNumber ?? '';
    ipLanController.text =
        widget.getShiftClosingModel.data?.summary?.ipAddress.toString() ?? "";
    debugPrint("ipLan:${ipLanController.text}");
    String expUPI = widget.getShiftClosingModel.data!.summary!.paymentMethods!
            .expectedUpiAmount
            ?.toString() ??
        '';
    String expCard = widget.getShiftClosingModel.data!.summary!.paymentMethods!
            .expectedCardAmount
            ?.toString() ??
        '';
    String expHD = widget.getShiftClosingModel.data!.summary!.expectedHdAmount
            ?.toString() ??
        '';
    String expCash = widget.getShiftClosingModel.data!.summary!.paymentMethods!
            .expectedCashAmount
            ?.toString() ??
        '';
    String upi = widget.upi;
    String card = widget.card ?? '';
    String hd = widget.hd ?? '';
    String totalCash = widget
            .getShiftClosingModel.data!.summary!.paymentMethods!.totalcashAmount
            .toString() ??
        '';
    String cashInHand = widget.cash ?? '';
    String totalSales = widget
            .getShiftClosingModel.data!.summary!.totalSalesAmount
            .toString() ??
        '';
    String totalExpense = widget
            .getShiftClosingModel.data!.summary!.totalExpensesAmount
            .toString() ??
        '';
    String nonCashExpense = widget
            .getShiftClosingModel.data!.summary!.overallexpensesamt
            .toString() ??
        '';
    String cashDifference = widget.cashDifference ?? '';

    return widget.getShiftClosingModel.data == null ||
            widget.getStockMaintanencesModel.data == null
        ? Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * 0.1,
            ),
            alignment: Alignment.center,
            child: Text(
              "No Shift Closing found",
              style: MyTextStyle.f16(greyColor, weight: FontWeight.w500),
            ),
          )
        : Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 40,
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 80),
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
                                  "Shift Closing",
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
                            key: shiftKey,
                            child: Center(
                              child: getShiftClosingReceiptWidget(
                                businessName: businessName,
                                tamilTagline: "",
                                address: address,
                                city: city,
                                state: state,
                                pinCode: pinCode,
                                phone: phone,
                                fromDate: fromDate,
                                expUPI: expUPI,
                                expCard: expCard,
                                expHD: expHD,
                                expCash: expCash,
                                card: card,
                                cashDifference: cashDifference,
                                upi: upi,
                                hd: hd,
                                totalCash: totalCash,
                                cashInHand: cashInHand,
                                totalSales: totalSales,
                                totalExpenses: totalExpense,
                                nonCashExpense: nonCashExpense,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Close Button
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          WidgetsBinding.instance
                              .addPostFrameCallback((_) async {
                            await _ensureIminServiceReady();
                            await _printBillToIminOnly(context);
                          });
                        },
                        icon: const Icon(Icons.print),
                        label: const Text("Print(Imin)"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: greenColor,
                          foregroundColor: whiteColor,
                        ),
                      ),
                      horizontalSpace(width: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        label: const Text("CLOSE"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appPrimaryColor,
                          foregroundColor: whiteColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }
}
