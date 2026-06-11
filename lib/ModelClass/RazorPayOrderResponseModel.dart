import 'package:simple/Bloc/Response/errorResponse.dart';

class RazorPayOrderResponseModel {
  bool? success;
  String? message;
  String? razorpayOrderId;
  String? keyId;
  int? amount;
  ErrorResponse? errorResponse;

  RazorPayOrderResponseModel({
    this.success,
    this.message,
    this.razorpayOrderId,
    this.keyId,
    this.amount,
    this.errorResponse,
  });

  RazorPayOrderResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    razorpayOrderId = json['razorpayOrderId'];
    keyId = json['keyId'];
    amount = json['amount'];
    if (json['errors'] != null && json['errors'] is Map<String, dynamic>) {
      errorResponse = ErrorResponse.fromJson(json['errors']);
    } else {
      errorResponse = null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    data['razorpayOrderId'] = razorpayOrderId;
    data['keyId'] = keyId;
    data['amount'] = amount;
    if (errorResponse != null) {
      data['errors'] = errorResponse!.toJson();
    }
    return data;
  }
}
