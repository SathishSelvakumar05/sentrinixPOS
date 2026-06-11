import 'package:simple/Bloc/Response/errorResponse.dart';

/// success : true
/// data : {"_id":"69281261a895adf8c6ccbbd9","date":"2025-11-27T00:00:00.000Z","CategoryId":{"_id":"692552bf947ed9543e5a3744","name":"vadai"},"name":"keerai","amount":10,"paymentMethod":"cash","locationId":{"_id":"6890d1700eb176a5bfc48b2a","name":"Tenkasi"},"createdBy":{"_id":"692529b1cce96462c4696340","name":"Mathan"},"createdAt":"2025-11-27T08:57:05.557Z","updatedAt":"2025-11-27T11:44:11.446Z","__v":0}

class GetSingleExpenseModel {
  GetSingleExpenseModel({
    bool? success,
    Data? data,
    ErrorResponse? errorResponse,
  }) {
    _success = success;
    _data = data;
  }

  GetSingleExpenseModel.fromJson(dynamic json) {
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
  GetSingleExpenseModel copyWith({
    bool? success,
    Data? data,
  }) =>
      GetSingleExpenseModel(
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

/// _id : "69281261a895adf8c6ccbbd9"
/// date : "2025-11-27T00:00:00.000Z"
/// CategoryId : {"_id":"692552bf947ed9543e5a3744","name":"vadai"}
/// name : "keerai"
/// amount : 10
/// paymentMethod : "cash"
/// locationId : {"_id":"6890d1700eb176a5bfc48b2a","name":"Tenkasi"}
/// createdBy : {"_id":"692529b1cce96462c4696340","name":"Mathan"}
/// createdAt : "2025-11-27T08:57:05.557Z"
/// updatedAt : "2025-11-27T11:44:11.446Z"
/// __v : 0

class Data {
  Data({
    String? id,
    String? date,
    CategoryId? categoryId,
    String? name,
    num? amount,
    String? paymentMethod,
    LocationId? locationId,
    CreatedBy? createdBy,
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
    _categoryId = json['CategoryId'] != null
        ? CategoryId.fromJson(json['CategoryId'])
        : null;
    _name = json['name'];
    _amount = json['amount'];
    _paymentMethod = json['paymentMethod'];
    _locationId = json['locationId'] != null
        ? LocationId.fromJson(json['locationId'])
        : null;
    _createdBy = json['createdBy'] != null
        ? CreatedBy.fromJson(json['createdBy'])
        : null;
    _createdAt = json['createdAt'];
    _updatedAt = json['updatedAt'];
    _v = json['__v'];
  }
  String? _id;
  String? _date;
  CategoryId? _categoryId;
  String? _name;
  num? _amount;
  String? _paymentMethod;
  LocationId? _locationId;
  CreatedBy? _createdBy;
  String? _createdAt;
  String? _updatedAt;
  num? _v;
  Data copyWith({
    String? id,
    String? date,
    CategoryId? categoryId,
    String? name,
    num? amount,
    String? paymentMethod,
    LocationId? locationId,
    CreatedBy? createdBy,
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
  CategoryId? get categoryId => _categoryId;
  String? get name => _name;
  num? get amount => _amount;
  String? get paymentMethod => _paymentMethod;
  LocationId? get locationId => _locationId;
  CreatedBy? get createdBy => _createdBy;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;
  num? get v => _v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = _id;
    map['date'] = _date;
    if (_categoryId != null) {
      map['CategoryId'] = _categoryId?.toJson();
    }
    map['name'] = _name;
    map['amount'] = _amount;
    map['paymentMethod'] = _paymentMethod;
    if (_locationId != null) {
      map['locationId'] = _locationId?.toJson();
    }
    if (_createdBy != null) {
      map['createdBy'] = _createdBy?.toJson();
    }
    map['createdAt'] = _createdAt;
    map['updatedAt'] = _updatedAt;
    map['__v'] = _v;
    return map;
  }
}

/// _id : "692529b1cce96462c4696340"
/// name : "Mathan"

class CreatedBy {
  CreatedBy({
    String? id,
    String? name,
  }) {
    _id = id;
    _name = name;
  }

  CreatedBy.fromJson(dynamic json) {
    _id = json['_id'];
    _name = json['name'];
  }
  String? _id;
  String? _name;
  CreatedBy copyWith({
    String? id,
    String? name,
  }) =>
      CreatedBy(
        id: id ?? _id,
        name: name ?? _name,
      );
  String? get id => _id;
  String? get name => _name;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = _id;
    map['name'] = _name;
    return map;
  }
}

/// _id : "6890d1700eb176a5bfc48b2a"
/// name : "Tenkasi"

class LocationId {
  LocationId({
    String? id,
    String? name,
  }) {
    _id = id;
    _name = name;
  }

  LocationId.fromJson(dynamic json) {
    _id = json['_id'];
    _name = json['name'];
  }
  String? _id;
  String? _name;
  LocationId copyWith({
    String? id,
    String? name,
  }) =>
      LocationId(
        id: id ?? _id,
        name: name ?? _name,
      );
  String? get id => _id;
  String? get name => _name;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = _id;
    map['name'] = _name;
    return map;
  }
}

/// _id : "692552bf947ed9543e5a3744"
/// name : "vadai"

class CategoryId {
  CategoryId({
    String? id,
    String? name,
  }) {
    _id = id;
    _name = name;
  }

  CategoryId.fromJson(dynamic json) {
    _id = json['_id'];
    _name = json['name'];
  }
  String? _id;
  String? _name;
  CategoryId copyWith({
    String? id,
    String? name,
  }) =>
      CategoryId(
        id: id ?? _id,
        name: name ?? _name,
      );
  String? get id => _id;
  String? get name => _name;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = _id;
    map['name'] = _name;
    return map;
  }
}
