import 'package:simple/Bloc/Response/errorResponse.dart';

class GetCompanyModel {
  bool? success;
  Data? data;
  ErrorResponse? errorResponse;

  GetCompanyModel({this.success, this.data, this.errorResponse});

  GetCompanyModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
    if (json['errors'] != null && json['errors'] is Map<String, dynamic>) {
      errorResponse = ErrorResponse.fromJson(json['errors']);
    } else {
      errorResponse = null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    if (errorResponse != null) {
      data['errors'] = errorResponse!.toJson();
    }
    return data;
  }
}

class Data {
  String? id;
  String? name;
  List<PriceId>? priceId;
  Businesstype? businesstype;
  String? defaultPaymentMethod;
  List<FeatureId>? featureId;

  Data({this.id, this.name, this.priceId, this.businesstype, this.defaultPaymentMethod, this.featureId});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    name = json['name'];
    if (json['priceId'] != null) {
      priceId = <PriceId>[];
      json['priceId'].forEach((v) {
        priceId!.add(PriceId.fromJson(v));
      });
    }
    businesstype = json['businesstype'] != null
        ? Businesstype.fromJson(json['businesstype'])
        : null;
    defaultPaymentMethod = json['default_payment_method'];
    if (json['featureId'] != null) {
      featureId = <FeatureId>[];
      json['featureId'].forEach((v) {
        featureId!.add(FeatureId.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = id;
    data['name'] = name;
    if (priceId != null) {
      data['priceId'] = priceId!.map((v) => v.toJson()).toList();
    }
    if (businesstype != null) {
      data['businesstype'] = businesstype!.toJson();
    }
    data['default_payment_method'] = defaultPaymentMethod;
    if (featureId != null) {
      data['featureId'] = featureId!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class FeatureId {
  String? id;
  String? name;
  String? description;

  FeatureId({this.id, this.name, this.description});

  FeatureId.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    name = json['name'];
    description = json['description'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = id;
    data['name'] = name;
    data['description'] = description;
    return data;
  }
}

class Businesstype {
  String? id;
  String? name;
  String? description;

  Businesstype({this.id, this.name, this.description});

  Businesstype.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    name = json['name'];
    description = json['description'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = id;
    data['name'] = name;
    data['description'] = description;
    return data;
  }
}

class PriceId {
  String? id;
  String? name;

  PriceId({this.id, this.name});

  PriceId.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = id;
    data['name'] = name;
    return data;
  }
}
