import 'package:simple/Bloc/Response/errorResponse.dart';

/// success : true
/// data : {"_id":"69284800a895adf8c6ccc48b","date":"2025-11-27T00:00:00.000Z","CategoryId":"692552bf947ed9543e5a3744","name":"egg vadai","amount":25,"paymentMethod":"upi","locationId":"6890d1700eb176a5bfc48b2a","createdBy":"692529b1cce96462c4696340","createdAt":"2025-11-27T12:45:52.517Z","updatedAt":"2025-11-27T13:50:39.149Z","__v":0}

class PutExpenseModel {
  PutExpenseModel({
    bool? success,
    Data? data,
    ErrorResponse? errorResponse,
  }) {
    _success = success;
    _data = data;
  }

  PutExpenseModel.fromJson(dynamic json) {
    _success = json['success'];
    _data = json['data'] != null ? Data.fromJson(json['data']) : null;
    if (json['errors'] != null && json['errors'] is Map<String, dynamic>) {
      errorResponse = ErrorResponse.fromJson(json['errors']);
    } else {
      errorResponse = null;
    }
  }
  bool? _success;
  Data? _data;
  ErrorResponse? errorResponse;
  PutExpenseModel copyWith({
    bool? success,
    Data? data,
  }) =>
      PutExpenseModel(
        success: success ?? _success,
        data: data ?? _data,
      );
  bool? get success => _success;
  Data? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = _success;
    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    if (errorResponse != null) {
      map['errors'] = errorResponse!.toJson();
    }
    return map;
  }
}

/// _id : "69284800a895adf8c6ccc48b"
/// date : "2025-11-27T00:00:00.000Z"
/// CategoryId : "692552bf947ed9543e5a3744"
/// name : "egg vadai"
/// amount : 25
/// paymentMethod : "upi"
/// locationId : "6890d1700eb176a5bfc48b2a"
/// createdBy : "692529b1cce96462c4696340"
/// createdAt : "2025-11-27T12:45:52.517Z"
/// updatedAt : "2025-11-27T13:50:39.149Z"
/// __v : 0

class Data {
  Data({
    String? id,
    String? date,
    String? categoryId,
    String? name,
    num? amount,
    String? paymentMethod,
    String? locationId,
    String? createdBy,
    String? createdAt,
    String? updatedAt,
    num? v,
  }) {
    _id = id;
    _date = date;
    _categoryId = categoryId;
    _name = name;
    _amount = amount;
    _paymentMethod = paymentMethod;
    _locationId = locationId;
    _createdBy = createdBy;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _v = v;
  }

  Data.fromJson(dynamic json) {
    _id = json['_id'];
    _date = json['date'];
    _categoryId = json['CategoryId'];
    _name = json['name'];
    _amount = json['amount'];
    _paymentMethod = json['paymentMethod'];
    _locationId = json['locationId'];
    _createdBy = json['createdBy'];
    _createdAt = json['createdAt'];
    _updatedAt = json['updatedAt'];
    _v = json['__v'];
  }
  String? _id;
  String? _date;
  String? _categoryId;
  String? _name;
  num? _amount;
  String? _paymentMethod;
  String? _locationId;
  String? _createdBy;
  String? _createdAt;
  String? _updatedAt;
  num? _v;
  Data copyWith({
    String? id,
    String? date,
    String? categoryId,
    String? name,
    num? amount,
    String? paymentMethod,
    String? locationId,
    String? createdBy,
    String? createdAt,
    String? updatedAt,
    num? v,
  }) =>
      Data(
        id: id ?? _id,
        date: date ?? _date,
        categoryId: categoryId ?? _categoryId,
        name: name ?? _name,
        amount: amount ?? _amount,
        paymentMethod: paymentMethod ?? _paymentMethod,
        locationId: locationId ?? _locationId,
        createdBy: createdBy ?? _createdBy,
        createdAt: createdAt ?? _createdAt,
        updatedAt: updatedAt ?? _updatedAt,
        v: v ?? _v,
      );
  String? get id => _id;
  String? get date => _date;
  String? get categoryId => _categoryId;
  String? get name => _name;
  num? get amount => _amount;
  String? get paymentMethod => _paymentMethod;
  String? get locationId => _locationId;
  String? get createdBy => _createdBy;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;
  num? get v => _v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = _id;
    map['date'] = _date;
    map['CategoryId'] = _categoryId;
    map['name'] = _name;
    map['amount'] = _amount;
    map['paymentMethod'] = _paymentMethod;
    map['locationId'] = _locationId;
    map['createdBy'] = _createdBy;
    map['createdAt'] = _createdAt;
    map['updatedAt'] = _updatedAt;
    map['__v'] = _v;
    return map;
  }
}
