import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:simple/ModelClass/Order/Post_generate_order_model.dart';
import 'package:simple/ModelClass/RazorPayOrderResponseModel.dart';
import 'package:simple/data/repositories/category/category_repository.dart';
import 'package:simple/injector/injector.dart';
import 'package:simple/Reusable/color.dart';
import 'package:simple/utilies/exceptions/app_exception.dart';

class RazorPaymentPage extends StatefulWidget {
  final RazorPayOrderResponseModel razorPayOrderResponseModel;
  final String payloadJson;
  const RazorPaymentPage({Key? key, required this.razorPayOrderResponseModel, required this.payloadJson}) : super(key: key);

  @override
  State<RazorPaymentPage> createState() => _RazorPaymentPageState();
}

class _RazorPaymentPageState extends State<RazorPaymentPage> {
  late Razorpay _razorpay;
  String _statusText = 'Initializing checkout...';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _openCheckout();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handleSuccess(PaymentSuccessResponse response) async {
    log("razorPay sign: ${response.signature}");
    log("razorPay success: ${response.data}");

    if (!mounted) return;
    setState(() {
      _statusText = 'Verifying payment, please wait...';
    });

    try {
      final Map<String, dynamic> orderData = jsonDecode(widget.payloadJson);
      
      if (orderData['payments'] is List) {
        final List paymentsList = orderData['payments'];
        for (var payment in paymentsList) {
          if (payment is Map && payment['method'] == 'ONLINE') {
            payment['razorpayOrderId'] = widget.razorPayOrderResponseModel.razorpayOrderId;
            payment['razorpayPaymentId'] = response.paymentId;
          }
        }
      }

      final verificationPayload = {
        "razorpay_order_id": widget.razorPayOrderResponseModel.razorpayOrderId,
        "razorpay_payment_id": response.paymentId,
        "razorpay_signature": response.signature,
        "orderData": orderData,
      };

      final PostGenerateOrderModel verifyResponse = 
          await injector<CategoryRepository>().verifyRazorPayPayment(verificationPayload);

      if (mounted) {
        Navigator.pop(context, verifyResponse);
      }
    } catch (e) {
      log("Verify payment error: $e");
      String errorMsg = "Verification failed";
      if (e is AppException) {
        errorMsg = e.message ?? e.errorCode ?? errorMsg;
      } else {
        errorMsg = e.toString();
      }
      if (mounted) {
        Navigator.pop(context, errorMsg);
      }
    }
  }

  void _handleError(PaymentFailureResponse response) {
    log("razorPay error: ${response.message}");
    if (mounted) {
      Navigator.pop(context, "Payment failed");
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    log("razorPay wallet: ${response.walletName}");
    if (mounted) {
      Navigator.pop(context, "External wallet selected: ${response.walletName}");
    }
  }

  void _openCheckout() {
    var options = {
      "order_id": widget.razorPayOrderResponseModel.razorpayOrderId,
      'key': widget.razorPayOrderResponseModel.keyId,
      'amount': widget.razorPayOrderResponseModel.amount,
      'name': 'RazorPay',
      'description': 'Online Payment',
      'send_sms_hash': true,
      'method': {
        'card': true,
        'upi': true,
        'netbanking': false,
        'wallet': false,
        'emi': false,
      }
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      log("Error opening RazorPay checkout: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, "Payment failed");
      },
      child: Scaffold(
        backgroundColor: appPrimaryColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: whiteColor),
              const SizedBox(height: 16),
              Text(
                _statusText,
                style: const TextStyle(color: whiteColor, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
