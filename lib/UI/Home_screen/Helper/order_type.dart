enum OrderType { line, parcel, ac, hd, swiggy, test }

extension OrderTypeX on OrderType {
  String get apiValue {
    switch (this) {
      case OrderType.line:
        return "LINE";
      case OrderType.parcel:
        return "PARCEL";
      case OrderType.ac:
        return "AC";
      case OrderType.hd:
        return "HD";
      case OrderType.swiggy:
        return "SWIGGY";
      case OrderType.test:
        return "TEST";
    }
  }

  static OrderType fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'LINE':
        return OrderType.line;
      case 'PARCEL':
        return OrderType.parcel;
      case 'AC':
        return OrderType.ac;
      case 'HD':
        return OrderType.hd;
      case 'SWIGGY':
        return OrderType.swiggy;
      default:
        return OrderType.line;
    }
  }
}
