import 'package:simple/Bloc/Response/errorResponse.dart';

class GetLocationDetailsModel {
  GetLocationDetailsModel({
    bool? success,
    Data? data,
    ErrorResponse? errorResponse,
  }) {
    _success = success;
    _data = data;
    this.errorResponse = errorResponse;
  }

  GetLocationDetailsModel.fromJson(dynamic json) {
    if (json == null) return;

    if (json is List) {
      if (json.isNotEmpty) {
        _success = true;
        _data = Data.fromJson(json.first);
      }
      return;
    }

    if (json is Map) {
      if (json.containsKey('success')) {
        _success = json['success'];
        final dataJson = json['data'];
        if (dataJson != null) {
          if (dataJson is List) {
            if (dataJson.isNotEmpty) {
              _data = Data.fromJson(dataJson.first);
            }
          } else {
            _data = Data.fromJson(dataJson);
          }
        }
      } else {
        _success = true;
        _data = Data.fromJson(json);
      }
      if (json['errors'] != null && json['errors'] is Map<String, dynamic>) {
        errorResponse = ErrorResponse.fromJson(json['errors']);
      } else {
        errorResponse = null;
      }
    }
  }

  bool? _success;
  Data? _data;
  ErrorResponse? errorResponse;

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

class Data {
  Data({
    this.id,
    this.name,
    this.printOperator,
    this.printTable,
    this.printTypeEnabled,
    this.printWaiter,
    this.posKotPrinterConnectionType,
    this.posKotPrinterIpAddress,
    this.posPrinterName,
  });

  Data.fromJson(dynamic json) {
    if (json == null) return;
    id = json['_id']?.toString();
    name = json['name']?.toString();
    printOperator = _parseBool(json['printOperator']);
    printTable = _parseBool(json['printTable']);
    printTypeEnabled = _parseBool(json['printTypeEnabled']);
    printWaiter = _parseBool(json['printWaiter']);
    posKotPrinterConnectionType = json['pos_kotPrinter_connectionType']?.toString();
    posKotPrinterIpAddress = json['pos_kotPrinter_ipAddress']?.toString();
    posPrinterName = json['pos_printer_name']?.toString();
  }

  bool? _parseBool(dynamic val) {
    if (val == null) return null;
    if (val is bool) return val;
    if (val is String) {
      return val.toLowerCase() == 'true';
    }
    if (val is num) {
      return val == 1;
    }
    return null;
  }

  String? id;
  String? name;
  bool? printOperator;
  bool? printTable;
  bool? printTypeEnabled;
  bool? printWaiter;
  String? posKotPrinterConnectionType;
  String? posKotPrinterIpAddress;
  String? posPrinterName;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['printOperator'] = printOperator;
    map['printTable'] = printTable;
    map['printTypeEnabled'] = printTypeEnabled;
    map['printWaiter'] = printWaiter;
    map['pos_kotPrinter_connectionType'] = posKotPrinterConnectionType;
    map['pos_kotPrinter_ipAddress'] = posKotPrinterIpAddress;
    map['pos_printer_name'] = posPrinterName;
    return map;
  }
}
