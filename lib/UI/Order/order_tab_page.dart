import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple/Alertbox/snackBarAlert.dart';
import 'package:simple/Bloc/Order/order_list_bloc.dart';
import 'package:simple/ModelClass/Order/get_order_list_today_model.dart';
import 'package:simple/ModelClass/Table/Get_table_model.dart';
import 'package:simple/ModelClass/User/getUserModel.dart';
import 'package:simple/ModelClass/Waiter/getWaiterModel.dart';
import 'package:simple/ModelClass/Company/getCompanyModel.dart';
import 'package:simple/ModelClass/Location/get_location_details_model.dart';
import 'package:simple/Reusable/color.dart';
import 'package:simple/Reusable/text_styles.dart';
import 'package:simple/UI/Authentication/login_screen.dart';
import 'package:simple/UI/Order/order_list.dart';
import 'package:simple/injector/injector.dart';

class OrdersTabbedScreen extends StatelessWidget {
  final VoidCallback? onRefresh;
  final GlobalKey<OrderViewViewState>? orderAllKey;
  final GlobalKey<OrderTabViewViewState>? orderResetKey;
  const OrdersTabbedScreen({
    super.key,
    this.onRefresh,
    this.orderAllKey,
    this.orderResetKey,
  });

  @override
  Widget build(BuildContext context) {
    // Move BlocProvider to the top level to share state across all tabs
    return BlocProvider(
      create: (_) => OrderTodayBloc(),
      child: OrderTabViewView(
        key: orderResetKey,
        onRefresh: onRefresh,
        orderAllKey: orderAllKey,
      ),
    );
  }
}

class OrderTabViewView extends StatefulWidget {
  final VoidCallback? onRefresh;
  final GlobalKey<OrderViewViewState>? orderAllKey;
  const OrderTabViewView({super.key, this.onRefresh, this.orderAllKey});

  @override
  OrderTabViewViewState createState() => OrderTabViewViewState();
}

class OrderTabViewViewState extends State<OrderTabViewView>
    with SingleTickerProviderStateMixin {
  bool hasRefreshedOrder = false;
  late TabController _tabController;
  GetTableModel getTableModel = GetTableModel();
  GetWaiterModel getWaiterModel = GetWaiterModel();
  GetUserModel getUserModel = GetUserModel();
  GetOrderListTodayModel getOrderListTodayModel = GetOrderListTodayModel();
  GetCompanyModel getCompanyModelData = GetCompanyModel();
  GetLocationDetailsModel getLocationModel = GetLocationDetailsModel();
  dynamic selectedValue;
  dynamic selectedValueWaiter;
  dynamic selectedValueUser;
  dynamic tableId;
  dynamic waiterId;
  dynamic userId;
  dynamic operatorId;
  bool tableLoad = false;
  bool isLoadingOrders = false;
  final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String? fromDate;

  bool isPriceTypeAvailable(String priceName) {
    if (getCompanyModelData.success != true ||
        getCompanyModelData.data == null ||
        getCompanyModelData.data!.priceId == null) {
      return priceName == "basePrice" || priceName == "parcelPrice";
    }
    return getCompanyModelData.data!.priceId!.any((p) => p.name == priceName);
  }

  List<Map<String, String>> _getAvailableTabs() {
    List<Map<String, String>> tabs = [
      {'text': 'All', 'type': 'All'},
      {'text': 'Line', 'type': 'Line'},
    ];
    if (isPriceTypeAvailable("parcelPrice")) {
      tabs.add({'text': 'Parcel', 'type': 'Parcel'});
    }
    if (isPriceTypeAvailable("acPrice")) {
      tabs.add({'text': 'AC', 'type': 'AC'});
    }
    if (isPriceTypeAvailable("hdPrice")) {
      tabs.add({'text': 'HD', 'type': 'HD'});
    }
    if (isPriceTypeAvailable("swiggyPrice")) {
      tabs.add({'text': 'SWIGGY', 'type': 'SWIGGY'});
    }
    return tabs;
  }

  final List<GlobalKey<OrderViewViewState>> _tabKeys = List.generate(
    10, // Increased to cover all potential tabs
    (index) => GlobalKey<OrderViewViewState>(),
  );

  Future<void> getOperatorId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      operatorId = prefs.getString("userId");
    });
    debugPrint("operatorId: $operatorId");
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _getAvailableTabs().length, vsync: this);
    _loadInitialData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tabController.index == 0 && widget.orderAllKey != null) {
        setState(() {
          selectedValue = null;
          selectedValueWaiter = null;
          selectedValueUser = null;
          tableId = null;
          waiterId = null;
          userId = null;
          hasRefreshedOrder = false;
          isLoadingOrders = true;
        });
        widget.orderAllKey?.currentState?.refreshOrders();
        setState(() {});
      }
    });
  }

  void resetSelections() {
    setState(() {
      selectedValue = null;
      selectedValueWaiter = null;
      selectedValueUser = null;
      tableId = null;
      waiterId = null;
      userId = null;
      hasRefreshedOrder = false;
      isLoadingOrders = true;
    });
    context.read<OrderTodayBloc>().add(FetchLocationDetails());
    context.read<OrderTodayBloc>().add(TableDine());
    context.read<OrderTodayBloc>().add(WaiterDine());
    context.read<OrderTodayBloc>().add(UserDetails());
    context.read<OrderTodayBloc>().add(
          OrderTodayList(todayDate, todayDate, "", "", ""),
        );
  }

  void _loadInitialData() {
    getOperatorId();
    context.read<OrderTodayBloc>().add(FetchCompanyCurrent());
    context.read<OrderTodayBloc>().add(FetchLocationDetails());
    _refreshData();
    fromDate = todayDate;
    _refreshAllTabs();
  }

  void _refreshAllTabs() {
    debugPrint("isLoadingOrders1 : $isLoadingOrders");
    // if (isLoadingOrders) return;
    debugPrint("isLoadingOrders2 : $isLoadingOrders");
    setState(() {
      isLoadingOrders = true;
    });
    debugPrint("refreshTab");
    context.read<OrderTodayBloc>().add(
          OrderTodayList(
            todayDate,
            todayDate,
            tableId ?? "",
            waiterId ?? "",
            userId ?? "",
          ),
        );
  }

  void _refreshData() {
    setState(() {
      selectedValue = null;
      selectedValueWaiter = null;
      selectedValueUser = null;
      tableId = null;
      waiterId = null;
      userId = null;
      hasRefreshedOrder = false;
      isLoadingOrders = true; // Set loading state
    });
    _tabController.animateTo(0);
    context.read<OrderTodayBloc>().add(FetchLocationDetails()); // Always re-fetch so location flags stay current
    context.read<OrderTodayBloc>().add(TableDine());
    context.read<OrderTodayBloc>().add(WaiterDine());
    context.read<OrderTodayBloc>().add(UserDetails());
    context.read<OrderTodayBloc>().add(
          OrderTodayList(
            todayDate,
            todayDate,
            tableId ?? "",
            waiterId ?? "",
            userId ?? "",
          ),
        );
  }

  void _onFilterChanged() {
    _refreshAllTabs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget mainContainer() {
      int tabCount = _getAvailableTabs().length;
      return Column(
        key: ValueKey("order_tabs_$tabCount"),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's Orders",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: appPrimaryColor,
                    ),
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
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  if (getLocationModel.data?.printTable == true)
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedValue,
                        decoration: InputDecoration(
                          labelText: 'Select Table',
                          labelStyle: MyTextStyle.f12(blackColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        items: getTableModel.data?.map((table) {
                          return DropdownMenuItem<String>(
                            value: table.id.toString(),
                            child: Text(table.name ?? 'Unknown',
                                style: MyTextStyle.f12(blackColor)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedValue = newValue;
                              tableId = newValue;
                              isLoadingOrders = true;
                            });
                            _onFilterChanged();
                          }
                        },
                      ),
                    ),
                  if (getLocationModel.data?.printTable == true && getLocationModel.data?.printWaiter == true)
                    const SizedBox(width: 12),
                  if (getLocationModel.data?.printWaiter == true)
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedValueWaiter,
                        decoration: InputDecoration(
                          labelText: 'Select Waiter',
                          labelStyle: MyTextStyle.f12(blackColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        items: getWaiterModel.data?.map((waiter) {
                          return DropdownMenuItem<String>(
                            value: waiter.id.toString(),
                            child: Text(waiter.name ?? 'Unknown',
                                style: MyTextStyle.f12(blackColor)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedValueWaiter = newValue;
                              waiterId = newValue;
                              isLoadingOrders = true;
                            });
                            _onFilterChanged();
                          }
                        },
                      ),
                    ),
                  if ((getLocationModel.data?.printTable == true || getLocationModel.data?.printWaiter == true) && getLocationModel.data?.printOperator == true)
                    const SizedBox(width: 12),
                  if (getLocationModel.data?.printOperator == true)
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedValueUser,
                        decoration: InputDecoration(
                          labelText: 'Select Operator',
                          labelStyle: MyTextStyle.f12(blackColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        items: getUserModel.data?.map((user) {
                          return DropdownMenuItem<String>(
                            value: user.id.toString(),
                            child: Text(user.name ?? 'Unknown',
                                style: MyTextStyle.f12(blackColor)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedValueUser = newValue;
                              userId = newValue;
                              isLoadingOrders = true;
                            });
                            debugPrint("operatorSelectr:$userId");
                            _onFilterChanged();
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: appPrimaryColor,
              unselectedLabelColor: greyColor,
              indicatorColor: appPrimaryColor,
              isScrollable: true,
              tabs: _getAvailableTabs().map((tab) => Tab(text: tab['text'])).toList(),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _getAvailableTabs().asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, String> tab = entry.value;
                  return OrderViewView(
                    key: (tab['type'] == 'All' && widget.orderAllKey != null)
                        ? widget.orderAllKey
                        : _tabKeys[index],
                    type: tab['type']!,
                    selectedTableName: tableId,
                    selectedWaiterName: waiterId,
                    selectOperator: userId,
                    operatorShared: operatorId,
                    sharedOrderData: getOrderListTodayModel,
                    isLoading: isLoadingOrders,
                  );
                }).toList(),
              ),
            ),
          ],
        );
    }

    return BlocListener<OrderTodayBloc, dynamic>(
      listener: (context, current) {
        debugPrint("OrderTabViewView BlocListener: state = ${current.runtimeType}");
        if (current is GetOrderListTodayModel) {
          debugPrint("OrderTabViewView: GetOrderListTodayModel received, resetting loader");
          setState(() {
            isLoadingOrders = false;
            tableLoad = false;
          });
        } else if (current is GetCompanyModel) {
          int oldLength = _tabController.length;
          getCompanyModelData = current;
          int newLength = _getAvailableTabs().length;
          if (oldLength != newLength) {
            _tabController.dispose();
            _tabController = TabController(length: newLength, vsync: this);
          }
          setState(() {});
        } else if (current is GetTableModel || current is GetWaiterModel || current is GetUserModel || current is GetLocationDetailsModel) {
          if (current is GetLocationDetailsModel) {
            getLocationModel = current;
          }
          setState(() {
            tableLoad = false;
          });
        } else if (current is Exception || current is String) {
          debugPrint("OrderTabViewView: Error received, resetting loader");
          setState(() {
            isLoadingOrders = false;
            tableLoad = false;
          });
        }
      },
      child: BlocBuilder<OrderTodayBloc, dynamic>(
        buildWhen: ((previous, current) {
          debugPrint("OrderTabViewView BlocBuilder buildWhen: previous=${previous.runtimeType}, current=${current.runtimeType}");
          if (current is GetOrderListTodayModel) {
            getOrderListTodayModel = current;
            if (getOrderListTodayModel.errorResponse?.isUnauthorized == true) {
              _handle401Error();
            }
            return true;
          }
          if (current is GetTableModel) {
            getTableModel = current;
            if (getTableModel.errorResponse?.isUnauthorized == true) {
              _handle401Error();
            }
            if (getTableModel.success != true) {
              showToast("No Tables found", context, color: false);
            }
            return true;
          }
          if (current is GetWaiterModel) {
            getWaiterModel = current;
            if (getWaiterModel.errorResponse?.isUnauthorized == true) {
              _handle401Error();
            }
            if (getWaiterModel.success != true) {
              showToast("No Waiter found", context, color: false);
            }
            return true;
          }
          if (current is GetUserModel) {
            getUserModel = current;
            if (getUserModel.errorResponse?.isUnauthorized == true) {
              _handle401Error();
            }
            if (getUserModel.success != true) {
              showToast("No Operator found", context, color: false);
            }
            return true;
          }
          if (current is GetLocationDetailsModel) {
            getLocationModel = current;
            if (getLocationModel.errorResponse?.isUnauthorized == true) {
              _handle401Error();
            }
            return true;
          }
          return false;
        }),
        builder: (context, state) {
          return mainContainer();
        },
      ),
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
