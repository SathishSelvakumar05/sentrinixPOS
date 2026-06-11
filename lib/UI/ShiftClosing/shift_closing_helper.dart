import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:simple/Reusable/color.dart';

Widget getShiftClosingReceiptWidget({
  required String businessName,
  required String tamilTagline,
  required String address,
  required String city,
  required String state,
  required String pinCode,
  required String phone,
  required String fromDate,
  required String expUPI,
  required String expCard,
  required String expHD,
  required String expCash,
  required String upi,
  required String hd,
  required String card,
  required String totalCash,
  required String cashInHand,
  required String totalSales,
  required String totalExpenses,
  required String nonCashExpense,
  required String cashDifference,
}) {
  return Container(
    width: 384, // Standard thermal printer width
    color: whiteColor, // Ensure white background
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Text(
                  businessName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: blackColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(fontSize: 16, color: blackColor),
                  textAlign: TextAlign.center,
                ),
                Text(
                  "Phone: $phone",
                  style: const TextStyle(fontSize: 16, color: blackColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Separator
          Divider(thickness: 4, color: blackColor),

          // Report Title
          const Center(
            child: Text(
              "SHIFT CLOSING REPORT",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: blackColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Divider(thickness: 4, color: blackColor),
          const SizedBox(height: 8),
          // Report Details
          _buildThermalLabelRow("Date", fromDate),
          const SizedBox(height: 8),

          /* Line */
          Divider(thickness: 4, color: blackColor),
          Row(
            children: const [
              Expanded(
                flex: 2,
                child: Text(
                  "S.No",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  "Payment Type",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  "Expected Amount",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  "Enter Amount",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          Divider(thickness: 4, color: blackColor),
          _buildThermalItemRow(1, "UPI", "₹$expUPI", "₹$upi"),
          _buildThermalItemRow(2, "CARD", "₹$expCard", "₹$card"),
          _buildThermalItemRow(3, "HD", "₹$expHD", "₹$hd"),
          _buildThermalItemRow(4, "CASH", "₹$expCash", "₹$cashInHand"),
          _buildThermalItemRow(
              5, "Expense", "₹$totalExpenses", "₹$totalExpenses"),
          Divider(thickness: 4, color: blackColor),
          // _buildThermalTotalRow(
          //   "CashInHand",
          //   isBold: true,
          //   double.parse(cashInHand),
          // ),
          _buildThermalTotalRow(
            "Total Sales",
            isBold: true,
            double.parse(totalSales),
          ),
          // _buildThermalTotalRow(
          //   "Total Expense",
          //   isBold: true,
          //   double.parse(totalExpenses),
          // ),
          _buildThermalTotalRow(
            "NonCash+Expense",
            isBold: true,
            double.parse(nonCashExpense),
          ),
          Divider(thickness: 4, color: blackColor),
          _buildThermalTotalRow(
            "Expected Cash",
            isBold: true,
            double.parse(totalSales) - double.parse(nonCashExpense),
          ),
          _buildThermalTotalRow(
            "Actual Cash",
            isBold: true,
            double.parse(cashInHand),
          ),
          Divider(thickness: 4, color: blackColor),
          _buildThermalTotalRow(
            "Cash Differences",
            isBold: true,
            double.parse(cashDifference),
          ),
          // _buildThermalTotalRow(
          //   "Total Sales",
          //   totalQuantity.toDouble(),
          //   isBold: true,
          // ),
          // _buildThermalTotalRow(
          //   "Total Quantity",
          //   totalQuantity.toDouble(),
          //   isBold: true,
          // ),
          // _buildThermalTotalRow("Total Amount", totalAmount, isBold: true),
          Divider(thickness: 4, color: blackColor),

          const SizedBox(height: 8),
          const Center(
            child: Text(
              "Thank You!",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: blackColor,
              ),
            ),
          ),
          // const Center(
          //   child: Text(
          //     "Powered By",
          //     style: TextStyle(
          //       fontWeight: FontWeight.bold,
          //       fontSize: 14,
          //       color: blackColor,
          //     ),
          //   ),
          // ),
          // const Center(
          //   child: Text(
          //     "www.sentinixtechsolutions.com",
          //     style: TextStyle(
          //       fontWeight: FontWeight.bold,
          //       fontSize: 14,
          //       color: blackColor,
          //     ),
          //   ),
          // ),
          const SizedBox(height: 40),
          //const SizedBox(height: 80), // Footer padding
        ],
      ),
    ),
  );
}

Widget _buildThermalItemRow(
  int sno,
  String name,
  String expAmount,
  String amount,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 1.0),
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            '$sno',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: blackColor),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            name,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: blackColor),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            expAmount,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: blackColor),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            amount,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: blackColor),
          ),
        ),
      ],
    ),
  );
}

Widget _buildThermalLabelRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: blackColor,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: blackColor,
          ),
        ),
      ],
    ),
  );
}

Widget _buildThermalTotalRow(
  String label,
  double amount, {
  bool isBold = false,
}) {
  final isAmountField = label.toLowerCase().contains("amount");
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 1.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold
                ? 22
                : 20, // Larger for TOTAL, increased base from 12 to 14
            color: blackColor,
          ),
        ),
        Text(
          isAmountField
              ? '₹${amount.toStringAsFixed(2)}'
              : amount.toStringAsFixed(0),
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold
                ? 22
                : 20, // Larger for TOTAL, increased base from 12 to 14
            color: blackColor,
          ),
        ),
      ],
    ),
  );
}

Future<Uint8List?> captureMonochromeShiftReport(GlobalKey key) async {
  try {
    RenderRepaintBoundary boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;

    // Capture the widget as an image
    ui.Image image = await boundary.toImage(pixelRatio: 2.0);
    ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    if (byteData == null) return null;

    Uint8List pixels = byteData.buffer.asUint8List();
    int width = image.width;
    int height = image.height;

    // Convert to monochrome (black and white only)
    List<int> monochromePixels = [];

    for (int i = 0; i < pixels.length; i += 4) {
      int r = pixels[i];
      int g = pixels[i + 1];
      int b = pixels[i + 2];
      int a = pixels[i + 3];

      // Calculate luminance
      double luminance = (0.299 * r + 0.587 * g + 0.114 * b);

      // Convert to black or white based on threshold
      int value = luminance > 128 ? 255 : 0;

      monochromePixels.addAll([value, value, value, a]);
    }

    // Create new image from monochrome pixels
    ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(
        Uint8List.fromList(monochromePixels));

    ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );

    ui.Codec codec = await descriptor.instantiateCodec();
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    ui.Image monochromeImage = frameInfo.image;

    ByteData? finalByteData =
        await monochromeImage.toByteData(format: ui.ImageByteFormat.png);

    return finalByteData?.buffer.asUint8List();
  } catch (e) {
    debugPrint("Error creating monochrome image: $e");
    return null;
  }
}
