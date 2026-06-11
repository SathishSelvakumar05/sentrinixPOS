import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple/Alertbox/snackBarAlert.dart';
import 'package:simple/Bloc/Report/report_bloc.dart';
import 'package:simple/ModelClass/Report/Get_report_with_ordertype_model.dart' as report;
import 'package:simple/ModelClass/Table/Get_table_model.dart' as table_model;
import 'package:simple/ModelClass/User/getUserModel.dart' as user_model;
import 'package:simple/ModelClass/Waiter/getWaiterModel.dart' as waiter_model;
import 'package:simple/Reusable/color.dart';
import 'package:simple/ModelClass/Company/getCompanyModel.dart';
import 'package:simple/ModelClass/Location/get_location_details_model.dart';
import 'package:simple/Reusable/space.dart';
import 'package:simple/Reusable/text_styles.dart';
import 'package:simple/UI/Authentication/login_screen.dart';
import 'package:simple/UI/Report/pop_view_report.dart';

class ReportView extends StatelessWidget {
  final GlobalKey<ReportViewViewState>? reportKey;
  bool? hasRefreshedReport;
  ReportView({
    super.key,
    this.reportKey,
    this.hasRefreshedReport,
  });

  @override
  Widget build(BuildContext context) {
    return ReportViewView(
        key: reportKey,
        reportKey: reportKey,
        hasRefreshedReport: hasRefreshedReport);
  }
}

class ReportViewView extends StatefulWidget {
  final GlobalKey<ReportViewViewState>? reportKey;
  bool? hasRefreshedReport;
  ReportViewView({
    super.key,
    this.reportKey,
    this.hasRefreshedReport,
  });

  @override
  ReportViewViewState createState() => ReportViewViewState();
}

class ReportViewViewState extends State<ReportViewView> {
  report.GetReportModel getReportModel = report.GetReportModel();
  table_model.GetTableModel getTableModel = table_model.GetTableModel();
  waiter_model.GetWaiterModel getWaiterModel = waiter_model.GetWaiterModel();
  user_model.GetUserModel getUserModel = user_model.GetUserModel();
  GetCompanyModel getCompanyModelData = GetCompanyModel();
  GetLocationDetailsModel getLocationModel = GetLocationDetailsModel();
  dynamic selectedValue;
  dynamic selectedValueWaiter;
  dynamic selectedValueUser;
  dynamic tableId;
  dynamic waiterId;
  dynamic userId;
  bool tableLoad = false;
  String? errorMessage;
  bool reportLoad = false;
  final String todayDisplayDate =
      DateFormat('dd/MM/yyyy').format(DateTime.now()); // UI
  final String todayApiDate =
      DateFormat('yyyy-MM-dd').format(DateTime.now()); // API
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  bool includeProduct = true;
  DateTime? fromDate;
  DateTime? toDate;
  DateTime? _fromDate;
  DateTime? _toDate;
  final DateTime now = DateTime.now();

  List<report.Data> getAllItems(dynamic orderType) {
    List<report.Data> allItems = [];
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

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isFromDate ? (_fromDate ?? now) : (_toDate ?? (_fromDate ?? now)),
      firstDate: isFromDate ? DateTime(2000) : (_fromDate ?? DateTime(2000)),
      lastDate: isFromDate ? (_toDate ?? now) : now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: appPrimaryColor,
              onPrimary: whiteColor,
              onSurface: blackColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: appPrimaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted) return;
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          fromDateController.text = DateFormat('dd/MM/yyyy').format(_fromDate!);
          if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
            _toDate = null;
            toDateController.clear();
          }
        } else {
          _toDate = picked;
          toDateController.text = DateFormat('dd/MM/yyyy').format(_toDate!);
        }
        if (_fromDate != null && _toDate != null) {
          String formattedFromDate =
              DateFormat('yyyy-MM-dd').format(_fromDate!);
          String formattedToDate = DateFormat('yyyy-MM-dd').format(_toDate!);

          context.read<ReportTodayBloc>().add(
                ReportTodayList(formattedFromDate, formattedToDate,
                    tableId ?? "", waiterId ?? "", userId ?? ""),
              );
        } else if (_fromDate != null && _toDate == null) {
          String formattedFromDate =
              DateFormat('yyyy-MM-dd').format(_fromDate!);
          String formattedToDate = DateFormat('yyyy-MM-dd').format(now);

          context.read<ReportTodayBloc>().add(
                ReportTodayList(formattedFromDate, formattedToDate,
                    tableId ?? "", waiterId ?? "", userId ?? ""),
              );
        }
      });
    }
  }

  void refreshReport() {
    if (!mounted || !context.mounted) return;
    context.read<ReportTodayBloc>().add(
          ReportTodayList(todayApiDate, todayApiDate, tableId ?? "",
              waiterId ?? "", userId ?? ""),
        );
    context.read<ReportTodayBloc>().add(TableDine());
    context.read<ReportTodayBloc>().add(WaiterDine());
    context.read<ReportTodayBloc>().add(UserDetails());
    context.read<ReportTodayBloc>().add(FetchCompanyCurrent());
    context.read<ReportTodayBloc>().add(FetchLocationDetails());
    setState(() {
      reportLoad = true;
    });
  }

  @override
  void initState() {
    super.initState();
    context.read<ReportTodayBloc>().add(TableDine());
    context.read<ReportTodayBloc>().add(WaiterDine());
    context.read<ReportTodayBloc>().add(UserDetails());
    context.read<ReportTodayBloc>().add(FetchCompanyCurrent());
    context.read<ReportTodayBloc>().add(FetchLocationDetails());
    if (widget.hasRefreshedReport == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          reportLoad = true;
          fromDateController.text = todayDisplayDate;
          toDateController.text = todayDisplayDate;
        });
        widget.reportKey?.currentState?.refreshReport();
      });
    } else {
      setState(() {
        reportLoad = true;
        fromDateController.text = todayDisplayDate;
        toDateController.text = todayDisplayDate;
      });
      context.read<ReportTodayBloc>().add(
            ReportTodayList(todayApiDate, todayApiDate, tableId ?? "",
                waiterId ?? "", userId ?? ""),
          );
    }
  }

  void _refreshData() {
    setState(() {
      selectedValue = null;
      selectedValueWaiter = null;
      selectedValueUser = null;
      tableId = null;
      waiterId = null;
      userId = null;
    });
    context.read<ReportTodayBloc>().add(
          ReportTodayList(todayApiDate, todayApiDate, tableId ?? "",
              waiterId ?? "", userId ?? ""),
        );
    context.read<ReportTodayBloc>().add(TableDine());
    context.read<ReportTodayBloc>().add(WaiterDine());
    context.read<ReportTodayBloc>().add(UserDetails());
    context.read<ReportTodayBloc>().add(FetchCompanyCurrent());
    context.read<ReportTodayBloc>().add(FetchLocationDetails());
    widget.reportKey?.currentState?.refreshReport();
  }

  @override
  void dispose() {
    super.dispose();
    fromDateController.clear;
    toDateController.clear;
  }

  @override
  Widget build(BuildContext context) {
    Widget mainContainer() {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Report",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => ThermalReportReceiptDialog(
                                getReportModel,
                                showItems: includeProduct,
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.print,
                            color: appPrimaryColor,
                            size: 28,
                          ),
                          tooltip: 'Print Report',
                        ),
                        IconButton(
                          onPressed: () {
                            _refreshData();
                          },
                          icon: const Icon(
                            Icons.refresh,
                            color: appPrimaryColor,
                            size: 28,
                          ),
                          tooltip: 'Refresh Orders',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              verticalSpace(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        textSelectionTheme: const TextSelectionThemeData(
                          selectionColor: Colors.transparent,
                          selectionHandleColor: Colors.transparent,
                        ),
                      ),
                      child: TextField(
                        controller: fromDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'From Date',
                          labelStyle: TextStyle(color: greyColor),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: appPrimaryColor, width: 2),
                          ),
                          suffixIcon: fromDateController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      fromDateController.clear();
                                      _fromDate = null;
                                      if (fromDateController.text.isEmpty &&
                                          toDateController.text.isEmpty) {
                                        context.read<ReportTodayBloc>().add(
                                              ReportTodayList(
                                                  todayApiDate,
                                                  todayApiDate,
                                                  tableId ?? "",
                                                  waiterId ?? "",
                                                  userId ?? ""),
                                            );
                                      }
                                    });
                                  },
                                )
                              : null,
                        ),
                        onTap: () => _selectDate(context, true),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Flexible(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        textSelectionTheme: const TextSelectionThemeData(
                          selectionColor: Colors.transparent,
                          selectionHandleColor: Colors.transparent,
                        ),
                      ),
                      child: TextField(
                        controller: toDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'To Date',
                          labelStyle: TextStyle(color: greyColor),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: appPrimaryColor, width: 2),
                          ),
                          suffixIcon: toDateController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      toDateController.clear();
                                      _toDate = null;
                                      if (fromDateController.text.isEmpty &&
                                          toDateController.text.isEmpty) {
                                        context.read<ReportTodayBloc>().add(
                                              ReportTodayList(
                                                  todayApiDate,
                                                  todayApiDate,
                                                  tableId ?? "",
                                                  waiterId ?? "",
                                                  userId ?? ""),
                                            );
                                      }
                                    });
                                  },
                                )
                              : null,
                        ),
                        onTap: () => _selectDate(context, false),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              if (getLocationModel.data != null)
                Row(
                  children: [
                    if (getLocationModel.data?.printTable == true)
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: (getTableModel.data?.any(
                                      (item) => item.name == selectedValue) ??
                                  false)
                              ? selectedValue
                              : null,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: appPrimaryColor,
                          ),
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: appPrimaryColor,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          items: getTableModel.data?.map((item) {
                            return DropdownMenuItem<String>(
                              value: item.name,
                              child: Text(
                                "Table ${item.name}",
                                style: MyTextStyle.f14(
                                  blackColor,
                                  weight: FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedValue = newValue;
                                final selectedItem = getTableModel.data
                                    ?.firstWhere((item) => item.name == newValue);
                                tableId = selectedItem?.id.toString();
                                context.read<ReportTodayBloc>().add(
                                      ReportTodayList(
                                          todayApiDate,
                                          todayApiDate,
                                          tableId ?? "",
                                          waiterId ?? "",
                                          userId ?? ""),
                                    );
                              });
                            }
                          },
                          hint: Text(
                            '-- Select Table --',
                            style: MyTextStyle.f14(
                              blackColor,
                              weight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    if (getLocationModel.data?.printTable == true && getLocationModel.data?.printWaiter == true)
                      const SizedBox(width: 12),
                    if (getLocationModel.data?.printWaiter == true)
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: (getWaiterModel.data?.any((item) =>
                                      item.name == selectedValueWaiter) ??
                                  false)
                              ? selectedValueWaiter
                              : null,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: appPrimaryColor,
                          ),
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: appPrimaryColor,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          items: getWaiterModel.data?.map((item) {
                            return DropdownMenuItem<String>(
                              value: item.name,
                              child: Text(
                                "${item.name}",
                                style: MyTextStyle.f14(
                                  blackColor,
                                  weight: FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedValueWaiter = newValue;
                                final selectedItem = getWaiterModel.data
                                    ?.firstWhere((item) => item.name == newValue);
                                waiterId = selectedItem?.id.toString();
                                context.read<ReportTodayBloc>().add(
                                      ReportTodayList(
                                          todayApiDate,
                                          todayApiDate,
                                          tableId ?? "",
                                          waiterId ?? "",
                                          userId ?? ""),
                                    );
                              });
                            }
                          },
                          hint: Text(
                            '-- Select Waiter --',
                            style: MyTextStyle.f14(
                              blackColor,
                              weight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    if ((getLocationModel.data?.printTable == true || getLocationModel.data?.printWaiter == true) && getLocationModel.data?.printOperator == true)
                      const SizedBox(width: 12),
                    if (getLocationModel.data?.printOperator == true)
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: (getUserModel.data?.any((item) =>
                                      item.name == selectedValueUser) ??
                                  false)
                              ? selectedValueUser
                              : null,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: appPrimaryColor,
                          ),
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: appPrimaryColor,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          items: getUserModel.data?.map((item) {
                            return DropdownMenuItem<String>(
                              value: item.name,
                              child: Text(
                                "${item.name}",
                                style: MyTextStyle.f14(
                                  blackColor,
                                  weight: FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedValueUser = newValue;
                                final selectedItem = getUserModel.data
                                    ?.firstWhere((item) => item.name == newValue);
                                userId = selectedItem?.id.toString();
                              });
                              debugPrint("operatorSelectr:$userId");
                              debugPrint("operatorSelectr:$selectedValueUser");
                              context.read<ReportTodayBloc>().add(
                                    ReportTodayList(
                                        todayApiDate,
                                        todayApiDate,
                                        tableId ?? "",
                                        waiterId ?? "",
                                        userId ?? ""),
                                  );
                            }
                          },
                          hint: Text(
                            '-- Select Operator --',
                            style: MyTextStyle.f14(
                              blackColor,
                              weight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              SizedBox(height: 24),
              Row(
                children: [
                  Checkbox(
                    value: includeProduct,
                    activeColor: appPrimaryColor,
                    onChanged: (value) {
                      setState(() {
                        includeProduct = value ?? true;
                      });
                    },
                  ),
                  const Text("Include product"),
                ],
              ),
              SizedBox(height: 24),
              reportLoad
                  ? Container(
                      padding: EdgeInsets.only(
                          top: MediaQuery.of(context).size.height * 0.1),
                      alignment: Alignment.center,
                      child: const SpinKitChasingDots(
                          color: appPrimaryColor, size: 30))
                  : getReportModel.orderTypes == null
                      ? Container(
                          padding: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height * 0.3),
                          alignment: Alignment.center,
                          child: Text(
                            "No Report found !!!",
                            style: MyTextStyle.f16(
                              greyColor,
                              weight: FontWeight.w500,
                            ),
                          ))
                      : Column(
                          children: [
                            if (includeProduct) ...[
                              if (getAllItems(getReportModel.orderTypes?.line).isNotEmpty) ...[
                                Text(
                                  "LINE",
                                  style: MyTextStyle.f16(
                                    blackColor,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Table(
                                  border: TableBorder.all(),
                                  columnWidths: const {
                                    0: FixedColumnWidth(50),
                                    1: FlexColumnWidth(),
                                    2: FixedColumnWidth(75),
                                    3: FixedColumnWidth(100),
                                  },
                                  children: [
                                    const TableRow(
                                      decoration:
                                          BoxDecoration(color: appPrimaryColor),
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text("S.No",
                                              style: TextStyle(
                                                  color: whiteColor,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text("Product Name",
                                              style: TextStyle(
                                                  color: whiteColor,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Center(
                                            child: Text("Quantity",
                                                style: TextStyle(
                                                    color: whiteColor,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Center(
                                            child: Text("Amount",
                                                style: TextStyle(
                                                    color: whiteColor,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    ...List.generate(
                                        getAllItems(getReportModel.orderTypes!.line).length, (index) {
                                      final item = getAllItems(getReportModel.orderTypes!.line)[index];
                                      return TableRow(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Center(
                                                child: Text("${index + 1}")),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Text(item.productName ?? ""),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Center(
                                                child: Text(
                                                    "${item.totalQty ?? ""}")),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Center(
                                                child: Text(item.totalAmount
                                                        ?.toStringAsFixed(2) ??
                                                    "")),
                                          ),
                                        ],
                                      );
                                    }),
                                    TableRow(
                                      decoration: const BoxDecoration(
                                          color: whiteColor),
                                      children: [
                                        const SizedBox(), // empty under S.No
                                        const Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text("Line Total",
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Center(
                                            child: Text(
                                              "${getReportModel.orderTypes!.line!.totalQty}",
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Center(
                                            child: Text(
                                              "₹ ${getReportModel.orderTypes!.line!.totalAmount?.toStringAsFixed(2) ?? '0.00'}",
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (getAllItems(getReportModel.orderTypes?.parcel).isNotEmpty) ...[
                                Text(
                                  "PARCEL",
                                  style: MyTextStyle.f16(
                                    blackColor,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Table(
                                  border: TableBorder.all(),
                                  columnWidths: const {
                                    0: FixedColumnWidth(50),
                                    1: FlexColumnWidth(),
                                    2: FixedColumnWidth(75),
                                    3: FixedColumnWidth(100),
                                  },
                                  children: [
                                    const TableRow(
                                      decoration:
                                          BoxDecoration(color: appPrimaryColor),
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text("S.No",
                                              style: TextStyle(
                                                  color: whiteColor,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text("Product Name",
                                              style: TextStyle(
                                                  color: whiteColor,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Center(
                                            child: Text("Quantity",
                                                style: TextStyle(
                                                    color: whiteColor,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Center(
                                            child: Text("Amount",
                                                style: TextStyle(
                                                    color: whiteColor,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    ...List.generate(
                                        getAllItems(getReportModel.orderTypes!.parcel).length, (index) {
                                      final item = getAllItems(getReportModel.orderTypes!.parcel)[index];
                                      return TableRow(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Center(
                                                child: Text("${index + 1}")),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Text(item.productName ?? ""),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Center(
                                                child: Text(
                                                    "${item.totalQty ?? ""}")),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Center(
                                                child: Text(item.totalAmount
                                                        ?.toStringAsFixed(2) ??
                                                    "")),
                                          ),
                                        ],
                                      );
                                    }),
                                    TableRow(
                                      decoration: const BoxDecoration(
                                          color: whiteColor),
                                      children: [
                                        const SizedBox(), // empty under S.No
                                        const Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text("Parcel Total",
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Center(
                                            child: Text(
                                              "${getReportModel.orderTypes!.parcel!.totalQty}",
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Center(
                                            child: Text(
                                              "₹ ${getReportModel.orderTypes!.parcel!.totalAmount?.toStringAsFixed(2) ?? '0.00'}",
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (getAllItems(getReportModel.orderTypes?.ac).isNotEmpty) ...[
                                Text(
                                  "AC",
                                  style: MyTextStyle.f16(
                                    blackColor,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Table(
                                  border: TableBorder.all(),
                                  columnWidths: const {
                                    0: FixedColumnWidth(50),
                                    1: FlexColumnWidth(),
                                    2: FixedColumnWidth(75),
                                    3: FixedColumnWidth(100),
                                  },
                                  children: [
                                    const TableRow(
                                      decoration:
                                          BoxDecoration(color: appPrimaryColor),
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text("S.No",
                                              style: TextStyle(
                                                  color: whiteColor,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text("Product Name",
                                              style: TextStyle(
                                                  color: whiteColor,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Center(
                                            child: Text("Quantity",
                                                style: TextStyle(
                                                    color: whiteColor,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Center(
                                            child: Text("Amount",
                                                style: TextStyle(
                                                    color: whiteColor,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    ...List.generate(
                                        getAllItems(getReportModel.orderTypes!.ac).length, (index) {
                                      final item = getAllItems(getReportModel.orderTypes!.ac)[index];
                                      return TableRow(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Center(
                                                child: Text("${index + 1}")),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Text(item.productName ?? ""),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Center(
                                                child: Text(
                                                    "${item.totalQty ?? ""}")),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Center(
                                                child: Text(item.totalAmount
                                                        ?.toStringAsFixed(2) ??
                                                    "")),
                                          ),
                                        ],
                                      );
                                    }),
                                    TableRow(
                                      decoration: const BoxDecoration(
                                          color: whiteColor),
                                      children: [
                                        const SizedBox(), // empty under S.No
                                        const Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text("AC Total",
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Center(
                                            child: Text(
                                              "${getReportModel.orderTypes!.ac!.totalQty}",
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Center(
                                            child: Text(
                                              "₹ ${getReportModel.orderTypes!.ac!.totalAmount?.toStringAsFixed(2) ?? '0.00'}",
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (getAllItems(getReportModel.orderTypes?.hd).isNotEmpty) ...[
                                Text(
                                  "HD",
                                  style: MyTextStyle.f16(
                                    blackColor,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Table(
                                  border: TableBorder.all(),
                                  columnWidths: const {
                                    0: FixedColumnWidth(50),
                                    1: FlexColumnWidth(),
                                    2: FixedColumnWidth(75),
                                    3: FixedColumnWidth(100),
                                  },
                                  children: [
                                    const TableRow(
                                      decoration:
                                          BoxDecoration(color: appPrimaryColor),
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text("S.No",
                                              style: TextStyle(
                                                  color: whiteColor,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text("Product Name",
                                              style: TextStyle(
                                                  color: whiteColor,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Center(
                                            child: Text("Quantity",
                                                style: TextStyle(
                                                    color: whiteColor,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Center(
                                            child: Text("Amount",
                                                style: TextStyle(
                                                    color: whiteColor,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    ...List.generate(
                                        getAllItems(getReportModel.orderTypes!.hd).length, (index) {
                                      final item = getAllItems(getReportModel.orderTypes!.hd)[index];
                                      return TableRow(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Center(
                                                child: Text("${index + 1}")),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Text(item.productName ?? ""),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Center(
                                                child: Text(
                                                    "${item.totalQty ?? ""}")),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Center(
                                                child: Text(item.totalAmount
                                                        ?.toStringAsFixed(2) ??
                                                    "")),
                                          ),
                                        ],
                                      );
                                    }),
                                    TableRow(
                                      decoration: const BoxDecoration(
                                          color: whiteColor),
                                      children: [
                                        const SizedBox(), // empty under S.No
                                        const Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text("HD Total",
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Center(
                                            child: Text(
                                              "${getReportModel.orderTypes!.hd!.totalQty}",
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Center(
                                            child: Text(
                                              "₹ ${getReportModel.orderTypes!.hd!.totalAmount?.toStringAsFixed(2) ?? '0.00'}",
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (getAllItems(getReportModel.orderTypes?.swiggy).isNotEmpty) ...[
                                Text(
                                  "SWIGGY",
                                  style: MyTextStyle.f16(
                                    blackColor,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Table(
                                  border: TableBorder.all(),
                                  columnWidths: const {
                                    0: FixedColumnWidth(50),
                                    1: FlexColumnWidth(),
                                    2: FixedColumnWidth(75),
                                    3: FixedColumnWidth(100),
                                  },
                                  children: [
                                    const TableRow(
                                      decoration:
                                          BoxDecoration(color: appPrimaryColor),
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text("S.No",
                                              style: TextStyle(
                                                  color: whiteColor,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text("Product Name",
                                              style: TextStyle(
                                                  color: whiteColor,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Center(
                                            child: Text("Quantity",
                                                style: TextStyle(
                                                    color: whiteColor,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Center(
                                            child: Text("Amount",
                                                style: TextStyle(
                                                    color: whiteColor,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    ...List.generate(
                                        getAllItems(getReportModel.orderTypes!.swiggy).length, (index) {
                                      final item = getAllItems(getReportModel.orderTypes!.swiggy)[index];
                                      return TableRow(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Center(
                                                child: Text("${index + 1}")),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Text(item.productName ?? ""),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Center(
                                                child: Text(
                                                    "${item.totalQty ?? ""}")),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Center(
                                                child: Text(item.totalAmount
                                                        ?.toStringAsFixed(2) ??
                                                    "")),
                                          ),
                                        ],
                                      );
                                    }),
                                    TableRow(
                                      decoration: const BoxDecoration(
                                          color: whiteColor),
                                      children: [
                                        const SizedBox(), // empty under S.No
                                        const Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text("Swiggy Total",
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Center(
                                            child: Text(
                                              "${getReportModel.orderTypes!.swiggy!.totalQty}",
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Center(
                                            child: Text(
                                              "₹ ${getReportModel.orderTypes!.swiggy!.totalAmount?.toStringAsFixed(2) ?? '0.00'}",
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                            ],

                            // ✅ Always show totals
                            Align(
                              alignment: Alignment.centerRight,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "Total Quantity: ${getReportModel.finalQty}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  Text(
                                    "Total Amount: ₹${getReportModel.finalAmount?.toStringAsFixed(2) ?? '0.00'}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        ThermalReportReceiptDialog(
                                            getReportModel,
                                            showItems: includeProduct),
                                  );
                                },
                                icon: const Icon(Icons.print),
                                label: const Text("Print"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: greenColor,
                                  foregroundColor: whiteColor,
                                ),
                              ),
                            ),
                          ],
                        ),
            ],
          ),
        ),
      );
    }

    return BlocConsumer<ReportTodayBloc, dynamic>(
      // listener fires BEFORE builder — model assignments here are available in builder
      listener: (context, current) {
        try {
          if (current is report.GetReportModel) {
            getReportModel = current;
            if (getReportModel.errorResponse?.isUnauthorized == true) {
              _handle401Error();
              return;
            }
            setState(() {
              reportLoad = false;
            });
          } else if (current is table_model.GetTableModel) {
            getTableModel = current;
            if (getTableModel.errorResponse?.isUnauthorized == true) {
              _handle401Error();
              return;
            }
            setState(() {
              tableLoad = false;
            });
            if (getTableModel.success != true) {
              showToast("No Tables found", context, color: false);
            }
          } else if (current is waiter_model.GetWaiterModel) {
            getWaiterModel = current;
            if (getWaiterModel.errorResponse?.isUnauthorized == true) {
              _handle401Error();
              return;
            }
            setState(() {
              tableLoad = false;
            });
            if (getWaiterModel.success != true) {
              showToast("No Waiter found", context, color: false);
            }
          } else if (current is user_model.GetUserModel) {
            getUserModel = current;
            if (getUserModel.errorResponse?.isUnauthorized == true) {
              _handle401Error();
              return;
            }
            setState(() {
              tableLoad = false;
            });
            if (getUserModel.success != true) {
              showToast("No Operator found", context, color: false);
            }
          } else if (current is GetCompanyModel) {
            getCompanyModelData = current;
            if (getCompanyModelData.errorResponse?.isUnauthorized == true) {
              _handle401Error();
              return;
            }
            setState(() {
              tableLoad = false;
            });
          } else if (current is GetLocationDetailsModel) {
            getLocationModel = current;
            debugPrint("[Report] LocationModel loaded: printOperator=${getLocationModel.data?.printOperator}, printTable=${getLocationModel.data?.printTable}, printWaiter=${getLocationModel.data?.printWaiter}");
            if (getLocationModel.errorResponse?.isUnauthorized == true) {
              _handle401Error();
              return;
            }
            setState(() {
              tableLoad = false;
            });
          } else if (current != null) {
            // Unknown/error state
            debugPrint("[Report] Bloc emitted an error state: ${current.runtimeType}: $current");
            setState(() {
              reportLoad = false;
            });
            if (current is DioException) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error: ${current.message}")),
              );
            }
          }
        } catch (e, stackTrace) {
          debugPrint("[Report] Error processing state: $e\n$stackTrace");
          setState(() {
            reportLoad = false;
          });
        }
      },
      builder: (context, state) {
        return mainContainer();
      },
    );
  }

  void _handle401Error() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.remove("token");
    await sharedPreferences.clear();
    if (!mounted) return;
    showToast("Session expired. Please login again.", context, color: false);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }
}
