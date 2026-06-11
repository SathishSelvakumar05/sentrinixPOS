import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple/Alertbox/snackBarAlert.dart';
import 'package:simple/Bloc/Expense/expense_bloc.dart';
import 'package:simple/ModelClass/Expense/getCategoryByLocationModel.dart';
import 'package:simple/ModelClass/Expense/getDailyExpenseModel.dart';
import 'package:simple/ModelClass/Expense/getSingleExpenseModel.dart';
import 'package:simple/ModelClass/Expense/postExpenseModel.dart';
import 'package:simple/ModelClass/Expense/putExpenseModel.dart';
import 'package:simple/ModelClass/StockIn/getLocationModel.dart';
import 'package:simple/Reusable/color.dart';
import 'package:simple/Reusable/text_styles.dart';
import 'package:simple/UI/Authentication/login_screen.dart';
import 'package:simple/UI/Order/Helper/time_formatter.dart';

class ExpenseView extends StatelessWidget {
  final GlobalKey<ExpenseViewViewState>? expenseKey;
  bool? hasRefreshedExpense;
  ExpenseView({
    super.key,
    this.expenseKey,
    this.hasRefreshedExpense,
  });

  @override
  Widget build(BuildContext context) {
    return ExpenseViewView(
        expenseKey: expenseKey, hasRefreshedExpense: hasRefreshedExpense);
  }
}

class ExpenseViewView extends StatefulWidget {
  final GlobalKey<ExpenseViewViewState>? expenseKey;
  bool? hasRefreshedExpense;
  ExpenseViewView({
    super.key,
    this.expenseKey,
    this.hasRefreshedExpense,
  });

  @override
  ExpenseViewViewState createState() => ExpenseViewViewState();
}

class ExpenseViewViewState extends State<ExpenseViewView> {
  GetLocationModel getLocationModel = GetLocationModel();
  GetCategoryByLocationModel getCategoryByLocationModel =
      GetCategoryByLocationModel();
  PostExpenseModel postExpenseModel = PostExpenseModel();
  GetDailyExpenseModel getDailyExpenseModel = GetDailyExpenseModel();
  GetSingleExpenseModel getSingleExpenseModel = GetSingleExpenseModel();
  PutExpenseModel putExpenseModel = PutExpenseModel();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  String? selectedCategory;
  String? selectedCategoryFilter;
  String? categoryId;
  String? categoryIdFilter;
  String? selectedPayment;
  String? selectedPaymentFilter;
  String? locationId;
  List<String> categories = ["Pongal", "Festival", "Food", "Travel"];
  String mapPaymentForApi(String? payment) {
    switch (payment) {
      case "Cash":
        return "cash";
      case "Card":
        return "card";
      case "UPI":
        return "upi";
      case "Bank Transfer":
        return "bank_transfer";
      case "Other":
        return "other";
      default:
        return "";
    }
  }

  List<String> paymentMethods = [
    "Card",
    "Cash",
    "Bank Transfer",
    "UPI",
    "Other"
  ];
  bool categoryLoad = false;
  bool saveLoad = false;
  bool editLoad = false;
  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
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
                foregroundColor:
                    appPrimaryColor, // OK & Cancel button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  bool stockLoad = false;
  bool expenseLoad = false;
  bool expenseShowLoad = false;
  bool isEdit = false;
  String? errorMessage;
  String? expenseId;

  void refreshExpense() {
    if (!mounted || !context.mounted) return;
    final apiPayment = mapPaymentForApi(selectedPaymentFilter ?? "");
    context.read<ExpenseBloc>().add(StockInLocation());
    context.read<ExpenseBloc>().add(DailyExpense(searchController.text,
        locationId ?? "", categoryIdFilter ?? "", apiPayment));
    setState(() {
      stockLoad = true;
      expenseLoad = true;
    });
  }

  void clearExpensesForm() {
    setState(() {
      selectedPayment = null;
      selectedCategory = null;
      categoryId = null;
      amountController.clear();
      nameController.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    dateController.text =
        "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";
    if (widget.hasRefreshedExpense == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          stockLoad = true;
          expenseLoad = true;
        });
        widget.expenseKey?.currentState?.refreshExpense();
      });
    } else {
      final apiPayment = mapPaymentForApi(selectedPaymentFilter ?? "");
      context.read<ExpenseBloc>().add(StockInLocation());
      context.read<ExpenseBloc>().add(DailyExpense(searchController.text,
          locationId ?? "", categoryIdFilter ?? "", apiPayment));
      setState(() {
        expenseLoad = true;
      });
    }
  }

  void _refreshData() {
    setState(() {
      selectedCategoryFilter = null;
      selectedPaymentFilter = null;
      categoryIdFilter = null;
      stockLoad = true;
    });
    final apiPayment = mapPaymentForApi(selectedPaymentFilter ?? "");
    context.read<ExpenseBloc>().add(StockInLocation());
    context.read<ExpenseBloc>().add(DailyExpense(searchController.text,
        locationId ?? "", categoryIdFilter ?? "", apiPayment));
    widget.expenseKey?.currentState?.refreshExpense();
  }

  void _refreshEditData() {
    setState(() {
      isEdit = false;
      selectedCategory = null;
      selectedPayment = null;
      amountController.clear();
      nameController.clear();
    });
    context.read<ExpenseBloc>().add(StockInLocation());
    widget.expenseKey?.currentState?.refreshExpense();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget mainContainer() {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    isEdit ? "Edit Expense" : "Add Expense",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  if (isEdit)
                    IconButton(
                      onPressed: () {
                        _refreshEditData();
                      },
                      icon: const Icon(
                        Icons.refresh,
                        color: appPrimaryColor,
                        size: 28,
                      ),
                      tooltip: 'Refresh Products',
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // ---------------- Row 1 ----------------

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Date",
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_month),
                          onPressed: pickDate,
                        ),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  getLocationModel.data?.locationName != null
                      ? Expanded(
                          child: TextFormField(
                            enabled: false,
                            initialValue: getLocationModel.data!.locationName!,
                            decoration: InputDecoration(
                              labelText: 'Location',
                              labelStyle: TextStyle(color: appPrimaryColor),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: greyColor),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: greyColor),
                              ),
                            ),
                          ),
                        )
                      : SizedBox.shrink()
                ],
              ),

              const SizedBox(height: 15),

              // ---------------- Row 2 ----------------
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: (getCategoryByLocationModel.data?.any(
                                  (item) => item.name == selectedCategory) ??
                              false)
                          ? selectedCategory
                          : null,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: appPrimaryColor,
                      ),
                      isExpanded: false,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: appPrimaryColor,
                          ),
                        ),
                      ),
                      items: getCategoryByLocationModel.data?.map((item) {
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
                            selectedCategory = newValue;
                            final selectedItem = getCategoryByLocationModel.data
                                ?.firstWhere((item) => item.name == newValue);
                            categoryId = selectedItem?.id.toString();
                          });
                        }
                      },
                      hint: Text(
                        'Category *',
                        style: MyTextStyle.f14(
                          blackColor,
                          weight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedPayment,
                      items: paymentMethods
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => selectedPayment = v),
                      decoration: const InputDecoration(
                        labelText: "Payment Method *",
                        labelStyle: TextStyle(color: appPrimaryColor),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // ---------------- Row 3 ----------------
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Amount *",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              isEdit == true
                  ? Center(
                      child: editLoad
                          ? SpinKitCircle(color: appPrimaryColor, size: 30)
                          : ElevatedButton(
                              onPressed: () {
                                final parsed = DateFormat("dd/MM/yyyy")
                                    .parse(dateController.text);
                                final backendDate =
                                    DateFormat("yyyy-MM-dd").format(parsed);
                                debugPrint("date:$backendDate");
                                if (getLocationModel.data!.locationName ==
                                    null) {
                                  showToast("Location not found", context,
                                      color: false);
                                } else if (selectedCategory == null) {
                                  showToast("Select Category", context,
                                      color: false);
                                } else if (selectedPayment == null) {
                                  showToast("Select payment method", context,
                                      color: false);
                                } else if (nameController.text.isEmpty) {
                                  showToast("Enter category name", context,
                                      color: false);
                                } else if (amountController.text.isEmpty) {
                                  showToast("Enter amount", context,
                                      color: false);
                                } else {
                                  setState(() {
                                    editLoad = true;
                                    context.read<ExpenseBloc>().add(
                                        UpdateExpense(
                                            expenseId.toString(),
                                            backendDate,
                                            categoryId.toString(),
                                            nameController.text,
                                            selectedPayment == "Cash"
                                                ? "cash"
                                                : selectedPayment == "Card"
                                                    ? "card"
                                                    : selectedPayment == "UPI"
                                                        ? "upi"
                                                        : selectedPayment ==
                                                                "Bank Transfer"
                                                            ? "bank_transfer"
                                                            : "other",
                                            amountController.text,
                                            locationId.toString()));
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appPrimaryColor,
                                minimumSize: const Size(0, 50), // Height only
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                "Update Expense",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                    )
                  : Center(
                      child: saveLoad
                          ? SpinKitCircle(color: appPrimaryColor, size: 30)
                          : ElevatedButton(
                              onPressed: () {
                                final parsed = DateFormat("dd/MM/yyyy")
                                    .parse(dateController.text);
                                final backendDate =
                                    DateFormat("yyyy-MM-dd").format(parsed);
                                debugPrint("date:$backendDate");
                                if (getLocationModel.data!.locationName ==
                                    null) {
                                  showToast("Location not found", context,
                                      color: false);
                                } else if (selectedCategory == null) {
                                  showToast("Select Category", context,
                                      color: false);
                                } else if (selectedPayment == null) {
                                  showToast("Select payment method", context,
                                      color: false);
                                } else if (nameController.text.isEmpty) {
                                  showToast("Enter category name", context,
                                      color: false);
                                } else if (amountController.text.isEmpty) {
                                  showToast("Enter amount", context,
                                      color: false);
                                } else {
                                  setState(() {
                                    saveLoad = true;
                                    context.read<ExpenseBloc>().add(SaveExpense(
                                        backendDate,
                                        categoryId.toString(),
                                        nameController.text,
                                        selectedPayment == "Cash"
                                            ? "cash"
                                            : selectedPayment == "Card"
                                                ? "card"
                                                : selectedPayment == "UPI"
                                                    ? "upi"
                                                    : selectedPayment ==
                                                            "Bank Transfer"
                                                        ? "bank_transfer"
                                                        : "other",
                                        amountController.text,
                                        locationId.toString()));
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appPrimaryColor,
                                minimumSize: const Size(0, 50), // Height only
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                "SAVE",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                    ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Expenses List",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 10),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Filters",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name...',
                        prefixIcon: Icon(Icons.search),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        searchController
                          ..text = (value)
                          ..selection = TextSelection.collapsed(
                              offset: searchController.text.length);
                        setState(() {
                          final apiPayment =
                              mapPaymentForApi(selectedPaymentFilter ?? "");
                          context.read<ExpenseBloc>().add(DailyExpense(
                              searchController.text,
                              locationId ?? "",
                              categoryIdFilter ?? "",
                              apiPayment));
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: (getCategoryByLocationModel.data?.any((item) =>
                                  item.name == selectedCategoryFilter) ??
                              false)
                          ? selectedCategoryFilter
                          : null,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: appPrimaryColor,
                      ),
                      isExpanded: false,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: appPrimaryColor,
                          ),
                        ),
                      ),
                      items: getCategoryByLocationModel.data?.map((item) {
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
                            selectedCategoryFilter = newValue;
                            final selectedItem = getCategoryByLocationModel.data
                                ?.firstWhere((item) => item.name == newValue);
                            categoryIdFilter = selectedItem?.id.toString();
                            final apiPayment =
                                mapPaymentForApi(selectedPaymentFilter ?? "");
                            context.read<ExpenseBloc>().add(DailyExpense(
                                searchController.text,
                                locationId ?? "",
                                categoryIdFilter ?? "",
                                apiPayment));
                          });
                        }
                      },
                      hint: Text(
                        'All Categories',
                        style: MyTextStyle.f14(
                          blackColor,
                          weight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedPaymentFilter,
                      items: paymentMethods
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          selectedPaymentFilter = v;
                          final apiPayment =
                              mapPaymentForApi(selectedPaymentFilter ?? "");

                          context.read<ExpenseBloc>().add(DailyExpense(
                              searchController.text,
                              locationId ?? "",
                              categoryIdFilter ?? "",
                              apiPayment));
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: "Payment Method *",
                        labelStyle: TextStyle(color: appPrimaryColor),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  ElevatedButton(
                    onPressed: () {
                      _refreshData();
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: appPrimaryColor,
                        minimumSize: const Size(0, 50), // Height only
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        )),
                    child: const Text(
                      "CLEAR FILTERS",
                      style: TextStyle(color: whiteColor),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Replace your DataTable widget with this responsive version

              expenseLoad
                  ? Container(
                      padding: EdgeInsets.only(
                          top: MediaQuery.of(context).size.height * 0.1),
                      alignment: Alignment.center,
                      child: const SpinKitChasingDots(
                          color: appPrimaryColor, size: 30))
                  : getDailyExpenseModel.data == null ||
                          getDailyExpenseModel.data == [] ||
                          getDailyExpenseModel.data!.isEmpty
                      ? Container(
                          padding: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height * 0.1),
                          alignment: Alignment.center,
                          child: Text(
                            "No Expenses Today !!!",
                            style: MyTextStyle.f16(
                              greyColor,
                              weight: FontWeight.w500,
                            ),
                          ))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            // Calculate column widths based on available screen width
                            final availableWidth = constraints.maxWidth;

                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth:
                                      availableWidth, // Ensures table takes full width
                                ),
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    dataTableTheme: const DataTableThemeData(
                                      dataRowMinHeight: 40,
                                      dataRowMaxHeight: 40,
                                    ),
                                  ),
                                  child: DataTable(
                                    headingRowColor: MaterialStateProperty.all(
                                        Colors.grey.shade200),
                                    dataRowHeight: 55,
                                    headingTextStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      fontSize: 14,
                                    ),
                                    columnSpacing: availableWidth *
                                        0.02, // 2% of screen width
                                    columns: [
                                      DataColumn(
                                        label: SizedBox(
                                          width: availableWidth * 0.12,
                                          child: const Text("Date"),
                                        ),
                                      ),
                                      DataColumn(
                                        label: SizedBox(
                                          width: availableWidth * 0.15,
                                          child: const Text("Location"),
                                        ),
                                      ),
                                      DataColumn(
                                        label: SizedBox(
                                          width: availableWidth * 0.15,
                                          child: const Text("Category"),
                                        ),
                                      ),
                                      DataColumn(
                                        label: SizedBox(
                                          width: availableWidth * 0.15,
                                          child: const Text("Name"),
                                        ),
                                      ),
                                      DataColumn(
                                        label: SizedBox(
                                          width: availableWidth * 0.12,
                                          child: const Text("Amount"),
                                        ),
                                      ),
                                      DataColumn(
                                        label: SizedBox(
                                          width: availableWidth * 0.16,
                                          child: const Text("Payment Method"),
                                        ),
                                      ),
                                      DataColumn(
                                        label: SizedBox(
                                          width: availableWidth * 0.13,
                                          child: const Text("Actions"),
                                        ),
                                      ),
                                    ],
                                    rows:
                                        getDailyExpenseModel.data!.map((item) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            SizedBox(
                                              width: availableWidth * 0.12,
                                              child: Text(
                                                "",
                                                // formatDate(
                                                //     item.date.toString()),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: availableWidth * 0.15,
                                              child: Text(
                                                item.locationId?.name ?? "",
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: availableWidth * 0.15,
                                              child: Text(
                                                item.categoryId?.name ?? "",
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: availableWidth * 0.15,
                                              child: Text(
                                                item.name ?? "",
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: availableWidth * 0.12,
                                              child: Text(
                                                item.amount.toString(),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: availableWidth * 0.16,
                                              child: Text(
                                                item.paymentMethod ?? "",
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: availableWidth * 0.13,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      color: appPrimaryColor,
                                                      size: 18,
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        isEdit = true;
                                                        expenseId =
                                                            item.id.toString();
                                                        debugPrint(
                                                            "isEdit_$isEdit");
                                                      });
                                                      context
                                                          .read<ExpenseBloc>()
                                                          .add(ExpenseById(item
                                                              .id
                                                              .toString()));
                                                    },
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(),
                                                  ),
                                                  // const SizedBox(width: 8),
                                                  // IconButton(
                                                  //   icon: const Icon(
                                                  //     Icons.delete,
                                                  //     color: Colors.red,
                                                  //     size: 18,
                                                  //   ),
                                                  //   onPressed: () {},
                                                  //   padding: EdgeInsets.zero,
                                                  //   constraints:
                                                  //       const BoxConstraints(),
                                                  // ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            );
                          },
                        )
            ],
          ),
        ),
      );
    }

    return BlocBuilder<ExpenseBloc, dynamic>(
      buildWhen: ((previous, current) {
        if (current is GetLocationModel) {
          getLocationModel = current;
          if (getLocationModel.errorResponse?.isUnauthorized == true) {
            _handle401Error();
            return true;
          }
          if (getLocationModel.success == true) {
            locationId = getLocationModel.data?.locationId;
            debugPrint("locationId:$locationId");
            debugPrint("locationId:$locationId");
            context
                .read<ExpenseBloc>()
                .add(CategoryByLocation(locationId.toString()));
            setState(() {
              stockLoad = false;
            });
          } else {
            debugPrint("${getLocationModel.data?.locationName}");
            setState(() {
              stockLoad = false;
            });
            showToast("No Location found", context, color: false);
          }
          return true;
        }
        if (current is GetCategoryByLocationModel) {
          getCategoryByLocationModel = current;
          if (getCategoryByLocationModel.success == true) {
            setState(() {
              categoryLoad = false;
            });
          }
          if (getCategoryByLocationModel.errorResponse?.isUnauthorized ==
              true) {
            _handle401Error();
            return true;
          }
          return true;
        }
        if (current is PostExpenseModel) {
          postExpenseModel = current;
          if (postExpenseModel.errorResponse?.isUnauthorized == true) {
            _handle401Error();
            return true;
          }
          if (postExpenseModel.success == true) {
            showToast("Expense Added Successfully", context, color: true);
            final apiPayment = mapPaymentForApi(selectedPaymentFilter ?? "");
            context.read<ExpenseBloc>().add(DailyExpense(searchController.text,
                locationId ?? "", categoryIdFilter ?? "", apiPayment));
            Future.delayed(Duration(milliseconds: 100), () {
              clearExpensesForm();
            });
            setState(() {
              saveLoad = false;
            });
          } else {
            setState(() {
              saveLoad = false;
            });
          }
          return true;
        }
        if (current is GetDailyExpenseModel) {
          getDailyExpenseModel = current;
          if (getDailyExpenseModel.errorResponse?.isUnauthorized == true) {
            _handle401Error();
            return true;
          }
          if (getDailyExpenseModel.success == true) {
            setState(() {
              expenseLoad = false;
            });
          } else {
            setState(() {
              expenseLoad = false;
            });
            showToast("No Expenses found", context, color: false);
          }
          return true;
        }
        if (current is GetSingleExpenseModel) {
          getSingleExpenseModel = current;
          if (getSingleExpenseModel.errorResponse?.isUnauthorized == true) {
            _handle401Error();
            return true;
          }
          if (getSingleExpenseModel.success == true) {
            setState(() {
              if (getSingleExpenseModel.data != null) {
                dateController.text = "";
                   // formatDate(getSingleExpenseModel.data!.date.toString());
                selectedCategory =
                    getSingleExpenseModel.data!.categoryId!.name ?? "";
                categoryId = getSingleExpenseModel.data!.categoryId!.id ?? "";
                nameController.text = getSingleExpenseModel.data!.name ?? "";
                amountController.text =
                    int.parse(getSingleExpenseModel.data!.amount.toString())
                        .toString();
                selectedPayment =
                    getSingleExpenseModel.data!.paymentMethod == "cash"
                        ? "Cash"
                        : getSingleExpenseModel.data!.paymentMethod == "card"
                            ? "Card"
                            : getSingleExpenseModel.data!.paymentMethod == "upi"
                                ? "UPI"
                                : getSingleExpenseModel.data!.paymentMethod ==
                                        "bank_transfer"
                                    ? "Bank Transfer"
                                    : "Other";
              }
              expenseShowLoad = false;
            });
          } else {
            setState(() {
              expenseShowLoad = false;
            });
            // showToast("No Expenses found", context, color: false);
          }
          return true;
        }
        if (current is PutExpenseModel) {
          putExpenseModel = current;
          if (putExpenseModel.errorResponse?.isUnauthorized == true) {
            _handle401Error();
            return true;
          }
          if (putExpenseModel.success == true) {
            showToast("Expense Updated Successfully", context, color: true);
            _refreshEditData();
            final apiPayment = mapPaymentForApi(selectedPaymentFilter ?? "");
            context.read<ExpenseBloc>().add(DailyExpense(searchController.text,
                locationId ?? "", categoryIdFilter ?? "", apiPayment));
            Future.delayed(Duration(milliseconds: 100), () {
              clearExpensesForm();
            });
            setState(() {
              editLoad = false;
            });
          } else {
            setState(() {
              editLoad = false;
            });
          }
          return true;
        }
        return false;
      }),
      builder: (context, dynamic) {
        return mainContainer();
      },
    );
  }

  void _handle401Error() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.remove("token");
    await sharedPreferences.clear();
    showToast("Session expired. Please login again.", context, color: false);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }
}
