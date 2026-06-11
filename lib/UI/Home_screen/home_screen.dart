import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple/Alertbox/snackBarAlert.dart';
import 'package:simple/Bloc/Category/category_bloc.dart';
import 'package:simple/ModelClass/Cart/Post_Add_to_billing_model.dart';
import 'package:simple/ModelClass/HomeScreen/Category&Product/Get_category_model.dart';
import 'package:simple/ModelClass/HomeScreen/Category&Product/Get_product_by_catId_model.dart';
import 'package:simple/ModelClass/Order/Get_view_order_model.dart';
import 'package:simple/ModelClass/Order/Post_generate_order_model.dart';
import 'package:simple/ModelClass/Order/Update_generate_order_model.dart';
import 'package:simple/ModelClass/Location/get_location_details_model.dart';
import 'package:simple/data/repositories/order/order_repository.dart';
import 'package:simple/injector/injector.dart';
import 'package:simple/ModelClass/ShopDetails/getStockMaintanencesModel.dart';
import 'package:simple/ModelClass/Table/Get_table_model.dart';
import 'package:simple/ModelClass/Waiter/getWaiterModel.dart';
import 'package:simple/ModelClass/Company/getCompanyModel.dart';
import 'package:simple/Reusable/color.dart';
import 'package:simple/Reusable/constant.dart';
import 'package:simple/Reusable/payment_option_config.dart';
import 'package:simple/Reusable/image.dart';
import 'package:simple/Reusable/space.dart';
import 'package:simple/Reusable/text_styles.dart';
import 'package:simple/UI/Authentication/login_screen.dart';
import 'package:simple/UI/Cart/Widget/payment_option.dart';
import 'package:simple/UI/Home_screen/Helper/order_helper.dart';
import 'package:simple/UI/Home_screen/Widget/another_imin_printer/imin_abstract.dart';
import 'package:simple/UI/Home_screen/Widget/another_imin_printer/mock_imin_printer_chrome.dart';
import 'package:simple/UI/Home_screen/Widget/another_imin_printer/real_device_printer.dart';
import 'package:simple/UI/Home_screen/Widget/category_card.dart';
import 'package:simple/UI/IminHelper/printer_helper.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:image/image.dart' as img;
import 'package:simple/UI/KOT_printer_helper/printer_kot_helper.dart';
import 'package:simple/services/tvse_printer_service.dart';
import 'package:simple/UI/Home_screen/Helper/order_type.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

import '../../mobile_code/bluetooth_service.dart';

class FoodOrderingScreen extends StatelessWidget {
  final GlobalKey<FoodOrderingScreenViewState>? foodKey;
  final GetViewOrderModel? existingOrder;
  bool? isEditingOrder;
  bool? hasRefreshedOrder;
  FoodOrderingScreen({
    super.key,
    this.foodKey,
    this.existingOrder,
    this.isEditingOrder,
    this.hasRefreshedOrder,
  });

  @override
  Widget build(BuildContext context) {
    return FoodOrderingScreenView(
        foodKey: foodKey,
        existingOrder: existingOrder,
        isEditingOrder: isEditingOrder,
        hasRefreshedOrder: hasRefreshedOrder);
  }
}



class FoodOrderingScreenView extends StatefulWidget {
  final GlobalKey<FoodOrderingScreenViewState>? foodKey;
  final GetViewOrderModel? existingOrder;
  bool? hasRefreshedOrder;
  bool? isEditingOrder;
  FoodOrderingScreenView(
      {super.key,
        this.foodKey,
        this.existingOrder,
        this.hasRefreshedOrder,
        this.isEditingOrder});

  @override
  FoodOrderingScreenViewState createState() => FoodOrderingScreenViewState();
}


class FoodOrderingScreenViewState extends State<FoodOrderingScreenView> {
  GetCompanyModel getCompanyModelData = GetCompanyModel();
  String? _shopLogo;

  bool isPriceTypeAvailable(String priceName) {
    if (getCompanyModelData.success != true || getCompanyModelData.data == null || getCompanyModelData.data!.priceId == null) {
      // While loading or if config missing, show Dine-in (basePrice) and Parcel (parcelPrice) by default
      return priceName == "basePrice" || priceName == "parcelPrice";
    }
    return getCompanyModelData.data!.priceId!.any((p) => p.name == priceName);
  }

  void _resetToDefaultOrderType() {
    if (isPriceTypeAvailable("basePrice")) {
      selectedOrderType = OrderType.line;
    } else if (isPriceTypeAvailable("parcelPrice")) {
      selectedOrderType = OrderType.parcel;
    } else if (isPriceTypeAvailable("acPrice")) {
      selectedOrderType = OrderType.ac;
    } else if (isPriceTypeAvailable("hdPrice")) {
      selectedOrderType = OrderType.hd;
    } else if (isPriceTypeAvailable("swiggyPrice")) {
      selectedOrderType = OrderType.swiggy;
    } else {
      selectedOrderType = OrderType.line; // Fallback
    }
  }

  String getCartItemKey(String productId, String? variantId) {
    if (variantId != null && variantId.isNotEmpty) {
      return "${productId}_$variantId";
    }
    return productId;
  }

  TextEditingController getOrCreateController(String key, num initialQty) {
    if (!quantityControllers.containsKey(key)) {
      final textValue = (initialQty % 1 == 0) ? initialQty.toInt().toString() : initialQty.toString();
      quantityControllers[key] =
          TextEditingController(text: textValue);
    }
    return quantityControllers[key]!;
  }

  void updateControllerText(String key, num qty) {
    final controller = quantityControllers[key];
    final textValue = (qty % 1 == 0) ? qty.toInt().toString() : qty.toString();
    if (controller != null) {
      controller.text = textValue;
    } else {
      quantityControllers[key] = TextEditingController(text: textValue);
    }
  }

  num getCurrentQuantity(String productId, {String? variantId}) {
    final matchKey = getCartItemKey(productId, variantId);
    final cartItem = billingItems.firstWhereOrNull((item) {
      final itemKey = getCartItemKey(item['_id']?.toString() ?? '', item['variantId']?.toString());
      return itemKey == matchKey;
    });
    if (cartItem != null) {
      return cartItem['qty'] ?? 0;
    }
    return 0;
  }

  void _showVariantSelectionDialog(Rows p) {
    num getVariantPrice(GeneratedVariants variant) {
      switch (selectedOrderType) {
        case OrderType.line:
          return variant.basePrice ?? 0;
        case OrderType.parcel:
          return variant.parcelPrice ?? variant.basePrice ?? 0;
        case OrderType.ac:
          return variant.acPrice ?? variant.basePrice ?? 0;
        case OrderType.hd:
          return variant.hdPrice ?? variant.basePrice ?? 0;
        case OrderType.swiggy:
          return variant.swiggyPrice ?? variant.basePrice ?? 0;
        default:
          return variant.basePrice ?? 0;
      }
    }

    final variants = p.generatedVariants ?? [];
    Map<String, int> selectedVariants = {};
    
    // Initialize from existing cart items if present
    final existingCartItems = billingItems.where((item) => item['_id'] == p.id).toList();
    if (existingCartItems.isNotEmpty) {
      for (var item in existingCartItems) {
        final vId = item['variantId']?.toString();
        if (vId != null && vId.isNotEmpty) {
          selectedVariants[vId] = (item['qty'] as num?)?.toInt() ?? 1;
        }
      }
    }
    
    // If no variants of this product are in the cart yet, fall back to checking the first one
    if (selectedVariants.isEmpty && variants.isNotEmpty) {
      final initialVariant = variants.firstWhereOrNull(
        (v) => p.isStock != true || (v.availableQuantity ?? 0) > 0
      ) ?? variants.first;
      if (initialVariant.id != null) {
        selectedVariants[initialVariant.id!] = 1;
      }
    }

    showDialog(
      context: context,
      builder: (context2) {
        return BlocProvider(
          create: (context) => FoodCategoryBloc(),
          child: BlocProvider.value(
            value: BlocProvider.of<FoodCategoryBloc>(context, listen: false),
            child: StatefulBuilder(
              builder: (context, setStateDialog) {
                final size = MediaQuery.of(context).size;

                return Dialog(
                  insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: size.width * 0.45,
                      maxHeight: size.height * 0.8,
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: "Choose Variants for ",
                            style: MyTextStyle.f18(blackColor, weight: FontWeight.bold),
                            children: [
                              TextSpan(
                                text: p.name ?? '',
                                style: MyTextStyle.f18(appPrimaryColor, weight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...variants.map((v) {
                                  final isSelected = selectedVariants.containsKey(v.id);
                                  final qty = selectedVariants[v.id] ?? 1;
                                  final isOutOfStock = p.isStock == true && (v.availableQuantity ?? 0) <= 0;
                                  final price = getVariantPrice(v);

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10.0),
                                    child: InkWell(
                                      onTap: isOutOfStock
                                          ? null
                                          : () {
                                              setStateDialog(() {
                                                if (isSelected) {
                                                  selectedVariants.remove(v.id);
                                                } else {
                                                  selectedVariants[v.id!] = 1;
                                                }
                                              });
                                            },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFFF2F8FF)
                                              : (isOutOfStock ? Colors.grey.shade100 : Colors.white),
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFF3B82F6)
                                                : Colors.black,
                                            width: isSelected ? 1.5 : 1.0,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Theme(
                                              data: ThemeData(
                                                checkboxTheme: CheckboxThemeData(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                ),
                                              ),
                                              child: Checkbox(
                                                value: isSelected,
                                                activeColor: const Color(0xFF3B82F6),
                                                checkColor: Colors.white,
                                                side: const BorderSide(color: Colors.black54, width: 1.5),
                                                onChanged: isOutOfStock
                                                    ? null
                                                    : (val) {
                                                        setStateDialog(() {
                                                          if (val == true) {
                                                            selectedVariants[v.id!] = 1;
                                                          } else {
                                                            selectedVariants.remove(v.id);
                                                          }
                                                        });
                                                      },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    v.label ?? '',
                                                    style: MyTextStyle.f16(
                                                      isOutOfStock ? greyColor : blackColor,
                                                      weight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "\u20B9 ${price.toStringAsFixed(2)}",
                                                    style: MyTextStyle.f12(greyColor),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isSelected) ...[
                                              Row(
                                                children: [
                                                  GestureDetector(
                                                    onTap: qty > 1
                                                        ? () {
                                                            setStateDialog(() {
                                                              selectedVariants[v.id!] = qty - 1;
                                                            });
                                                          }
                                                        : null,
                                                    child: Container(
                                                      width: 28,
                                                      height: 28,
                                                      decoration: const BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Color(0xFFECECEC),
                                                      ),
                                                      child: const Icon(Icons.remove, size: 16, color: blackColor),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    width: 45,
                                                    height: 32,
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF1F5F9),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: Colors.grey.shade300),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        "$qty",
                                                        style: const TextStyle(fontWeight: FontWeight.bold, color: blackColor),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  GestureDetector(
                                                    onTap: () {
                                                      if (p.isStock == true) {
                                                        final paidQty = widget.existingOrder?.data?.items
                                                                ?.firstWhereOrNull((item) => item.product?.id == p.id && item.variant == v.id)
                                                                ?.quantity ??
                                                            0;
                                                        final currentQtyInCart = billingItems
                                                            .where((item) => item['_id'] == p.id && item['variantId'] == v.id)
                                                            .fold<int>(0, (sum, item) => sum + (item['qty'] as int? ?? 0));

                                                        int maxAvailable = (v.availableQuantity ?? 0).toInt();
                                                        if ((widget.isEditingOrder == true && widget.existingOrder?.data?.orderStatus == "COMPLETED") ||
                                                            (widget.isEditingOrder == true && widget.existingOrder?.data?.orderStatus == "WAITLIST")) {
                                                          maxAvailable += paidQty.toInt();
                                                        }

                                                        if (currentQtyInCart + qty >= maxAvailable) {
                                                          showToast("Cannot increase quantity. Stock limit reached.", context, color: false);
                                                          return;
                                                        }
                                                      }
                                                      setStateDialog(() {
                                                        selectedVariants[v.id!] = qty + 1;
                                                      });
                                                    },
                                                    child: Container(
                                                      width: 28,
                                                      height: 28,
                                                      decoration: const BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: appPrimaryColor,
                                                      ),
                                                      child: const Icon(Icons.add, size: 16, color: Colors.white),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            ]
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                if (p.addons != null && p.addons!.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  Text(
                                    "Add-Ons (Optional)",
                                    style: MyTextStyle.f14(greyColor, weight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 12),
                                  ...p.addons!.map((addon) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: greyColor.shade300),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    addon.name ?? '',
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    addon.isFree == true
                                                        ? "Free (Max: ${addon.maxQuantity})"
                                                        : "\u20B9 ${addon.price?.toStringAsFixed(2) ?? '0.00'} (Max: ${addon.maxQuantity})",
                                                    style: TextStyle(color: Colors.grey.shade600),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.remove),
                                                  onPressed: (addon.quantity) > 0
                                                      ? () {
                                                          setStateDialog(() {
                                                            addon.quantity = (addon.quantity) - 1;
                                                          });
                                                        }
                                                      : null,
                                                ),
                                                Text('${addon.quantity}'),
                                                IconButton(
                                                  icon: const Icon(Icons.add, color: appPrimaryColor),
                                                  onPressed: (addon.quantity) < (addon.maxQuantity ?? 1)
                                                      ? () {
                                                          setStateDialog(() {
                                                            addon.quantity = (addon.quantity) + 1;
                                                          });
                                                        }
                                                      : null,
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE2E8F0),
                                foregroundColor: blackColor,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                "Cancel",
                                style: MyTextStyle.f14(blackColor, weight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appPrimaryColor,
                                foregroundColor: whiteColor,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: selectedVariants.isEmpty
                                  ? null
                                  : () {
                                      setState(() {
                                        isSplitPayment = false;
                                        if (widget.isEditingOrder != true) {
                                          if (billingItems.isEmpty) _resetToDefaultOrderType();
                                        }

                                        // 1. Remove any variants of product p that are NOT in selectedVariants, and remove their controllers
                                        billingItems.removeWhere((item) {
                                          if (item['_id'] == p.id && !selectedVariants.containsKey(item['variantId']?.toString())) {
                                            quantityControllers.remove(getCartItemKey(p.id.toString(), item['variantId']?.toString()));
                                            return true;
                                          }
                                          return false;
                                        });

                                        // 2. Add or update selected variants
                                        selectedVariants.forEach((variantId, qty) {
                                          final v = variants.firstWhere((varItem) => varItem.id == variantId);
                                          final index = billingItems.indexWhere(
                                            (item) => item['_id'] == p.id && item['variantId'] == v.id
                                          );

                                          if (index != -1) {
                                            billingItems[index]['qty'] = qty; // Overwrite
                                            updateControllerText(
                                              getCartItemKey(p.id.toString(), v.id),
                                              qty
                                            );
                                          } else {
                                            billingItems.add({
                                              "_id": p.id,
                                              "basePrice": v.basePrice,
                                              "image": p.image,
                                              "qty": qty,
                                              "name": "${p.name} (${v.label})",
                                              "variantId": v.id,
                                              "variantLabel": v.label,
                                              "availableQuantity": v.availableQuantity,
                                              "unitmasterid": p.unitmasterid,
                                              "selectedAddons": p.addons!
                                                  .where((addon) => addon.quantity > 0)
                                                  .map((addon) => {
                                                        "_id": addon.id,
                                                        "price": addon.price,
                                                        "quantity": addon.quantity,
                                                        "name": addon.name,
                                                        "isAvailable": addon.isAvailable,
                                                        "maxQuantity": addon.maxQuantity,
                                                        "isFree": addon.isFree,
                                                      })
                                                  .toList()
                                            });
                                            updateControllerText(
                                              getCartItemKey(p.id.toString(), v.id),
                                              qty
                                            );
                                          }
                                        });

                                        context.read<FoodCategoryBloc>().add(
                                          AddToBilling(List.from(billingItems), isDiscountApplied, selectedOrderType)
                                        );

                                        for (var addon in p.addons!) {
                                          addon.isSelected = false;
                                          addon.quantity = 0;
                                        }
                                      });

                                      Navigator.of(context).pop();
                                    },
                              child: Text(
                                "Add ${selectedVariants.length} ${selectedVariants.length > 1 ? 'Variants' : 'Variant'} to Bill",
                                style: MyTextStyle.f14(whiteColor, weight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  bool isPaymentMethodAllowed(String methodName) {
    String? defaultPayment = getCompanyModelData.data?.defaultPaymentMethod;
    debugPrint("payment method:${defaultPayment}");
    if ((defaultPayment?.isEmpty??true) || defaultPayment?.toLowerCase() == "all") {
      return true;
    }
    return defaultPayment?.toLowerCase() == methodName.toLowerCase();
  }

  GetCategoryModel getCategoryModel = GetCategoryModel();
  GetProductByCatIdModel getProductByCatIdModel = GetProductByCatIdModel();
  PostAddToBillingModel postAddToBillingModel = PostAddToBillingModel();
  PostGenerateOrderModel postGenerateOrderModel = PostGenerateOrderModel();
  GetTableModel getTableModel = GetTableModel();
  GetWaiterModel getWaiterModel = GetWaiterModel();
  UpdateGenerateOrderModel updateGenerateOrderModel =
  UpdateGenerateOrderModel();
  GetStockMaintanencesModel getStockMaintanencesModel =
  GetStockMaintanencesModel();
  final TextEditingController ipController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String? storedIpAddress;
  TextEditingController searchController = TextEditingController();
  TextEditingController searchProdIdController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  Map<String, TextEditingController> quantityControllers = {};

  List<TextEditingController> splitAmountControllers = [];
  List<String?> selectedPaymentMethods = [];
  double totalSplit = 0.0;

  String selectedCategory = "All";
  String? selectedCatId = "";

  OrderType? selectedOrderType = OrderType.line;
  bool _isSplitPaymentVal = false;
  bool get isSplitPayment {
    if (activePaymentOption == PaymentOptionType.splitOnly) return true;
    if (activePaymentOption == PaymentOptionType.fullOnly) return false;
    return _isSplitPaymentVal;
  }
  set isSplitPayment(bool val) {
    _isSplitPaymentVal = val;
  }
  bool splitChange = false;
  bool isCompleteOrder = false;
  int _paymentFieldCount = 1;
  double balance = 0;
  bool allSplitAmountsFilled() {
    return splitAmountControllers
        .every((controller) => controller.text.trim().isNotEmpty);
  }

  bool allPaymentMethodsSelected() {
    return selectedPaymentMethods
        .every((method) => method != null && method.isNotEmpty);
  }

  void addPaymentField() {
    if (_paymentFieldCount < 3) {
      setState(() {
        _paymentFieldCount++;
        double currentTotal = 0.0;
        for (var controller in splitAmountControllers) {
          currentTotal += double.tryParse(controller.text) ?? 0.0;
        }
        double remaining = (postAddToBillingModel.total ?? 0).toDouble() - currentTotal;
        if (remaining < 0) remaining = 0;
        
        TextEditingController newController = TextEditingController(
          text: remaining > 0 ? remaining.toStringAsFixed(0) : ""
        );
        splitAmountControllers.add(newController);
        selectedPaymentMethods.add(null);
        
        // Update totalSplit
        totalSplit = currentTotal + remaining;
      });
    }
  }

  void removePaymentField(int index) {
    if (_paymentFieldCount > 1) {
      setState(() {
        _paymentFieldCount--;
        splitAmountControllers[index].dispose();
        splitAmountControllers.removeAt(index);
        selectedPaymentMethods.removeAt(index);
        
        double total = 0.0;
        for (var controller in splitAmountControllers) {
          total += double.tryParse(controller.text) ?? 0.0;
        }
        totalSplit = total;
      });
    }
  }

  dynamic selectedValue;
  dynamic selectedValueWaiter;
  dynamic tableId;
  dynamic waiterId;

  bool showTipField = false;
  final TextEditingController tipController = TextEditingController();
  double tipAmount = 0.0;
  void toggleTipField() {
    setState(() {
      showTipField = !showTipField;
      if (!showTipField) {
        tipAmount = 0.0;
        tipController.clear();
      }
    });
  }

  void updateTip(String value) {
    setState(() {
      tipAmount = double.tryParse(value) ?? 0.0;
    });
  }

  String? errorMessage;
  bool categoryLoad = false;
  bool orderLoad = false;
  bool completeLoad = false;
  bool cartLoad = false;
  bool isToppingSelected = false;
  GlobalKey normalReceiptKey = GlobalKey();
  GlobalKey kotReceiptKey = GlobalKey();
  List<BluetoothInfo> _devices = [];
  bool _isScanning = false;

  int counter = 0;
  String selectedFullPaymentMethod = "";
  double totalAmount = 0.0;
  double paidAmount = 0.0;
  double balanceAmount = 0.0;
  bool isCartLoaded = false;
  bool isDiscountApplied = false;
  List<Map<String, dynamic>> billingItems = [];
  late IPrinterService printerService;
  late IPrinterService printerServiceThermal;
  String serialNumber = '';
  GetLocationDetailsModel? _locationDetails;
  bool _isLoadingLocation = true;
  String formatInvoiceDate(String? dateStr) {
    DateTime dateTime;

    if (dateStr == null) {
      return DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());
    }

    try {
      dateTime = DateFormat('M/d/yyyy, h:mm:ss a').parse(dateStr);
    } catch (_) {
      try {
        dateTime = DateTime.parse(dateStr);
      } catch (_) {
        dateTime = DateTime.now();
      }
    }
    return DateFormat('dd/MM/yyyy hh:mm a').format(dateTime);
  }

  Future<void> _ensureIminServiceReady() async {
    try {
      // Try to reinitialize the service to ensure it's pointing to IMIN
      await printerService.init();
    } catch (e) {
      debugPrint("Error reinitializing IMIN service: $e");
    }
  }

  Future<void> _showPrinterIpDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("Thermal Printer Setup"),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: "Thermal Printer IP Address",
                hintText: "e.g. 192.168.1.96",
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter printer IP";
                }
                final regex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
                if (!regex.hasMatch(value.trim())) {
                  return "Enter valid IP (e.g. 192.168.1.96)";
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel",
                  style: TextStyle(color: appPrimaryColor)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final ip = ipController.text.trim();
                  debugPrint("User entered IP: $ip");
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('thermal_printer_ip', ip);
                  setState(() {
                    storedIpAddress = ip;
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text("SUBMIT",
                  style: TextStyle(color: appPrimaryColor)),
            ),
          ],
        );
      },
    );
  }

  // Future<void> _scanBluetoothDevices() async {
  //   if (_isScanning) return;
  //
  //   setState(() {
  //     _isScanning = true;
  //     _devices.clear();
  //   });
  //
  //   try {
  //     // Check if Bluetooth is enabled
  //     final bool result = await PrintBluetoothThermal.bluetoothEnabled;
  //     if (!result) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text("Bluetooth is not enabled"),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //       setState(() => _isScanning = false);
  //       return;
  //     }
  //
  //     // Get paired Bluetooth devices
  //     final List<BluetoothInfo> bluetooths =
  //     await PrintBluetoothThermal.pairedBluetooths;
  //     setState(() {
  //       _devices = bluetooths;
  //       _isScanning = false;
  //     });
  //   } catch (e) {
  //     debugPrint("Error scanning Bluetooth devices: $e");
  //     setState(() => _isScanning = false);
  //   }
  // }

  final BluetoothPrintService _printService = BluetoothPrintService();

  static const String _bigLimit = '1000';

  Future<void> _scanBluetoothDevices() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _devices.clear();
    });

    try {
      // Request permissions
      await _printService.requestBluetoothPermissions();

      final bool result = await PrintBluetoothThermal.bluetoothEnabled;

      if (!result) {
        setState(() => _isScanning = false);
        return;
      }

      final List<BluetoothInfo> bluetooths =
      await PrintBluetoothThermal.pairedBluetooths;

      print("Found devices: ${bluetooths.length}");
      print(bluetooths);

      setState(() {
        _devices = bluetooths;
        _isScanning = false;
      });
    } catch (e) {
      print("Bluetooth Scan Error: $e");
      setState(() => _isScanning = false);
    }
  }
  Future<void> _selectBluetoothPrinter(BuildContext context) async {
    await _scanBluetoothDevices();

    if (_devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "No paired Bluetooth printers found. Please pair your printer first."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Select Bluetooth Printer",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _devices.length,
                itemBuilder: (_, index) {
                  final printer = _devices[index];
                  return ListTile(
                    leading: const Icon(Icons.print),
                    title: Text(
                        printer.name), // Changed from printer.name ?? "Unknown"
                    subtitle: Text(printer
                        .macAdress), // Changed from printer.address ?? ""
                    onTap: () {
                      Navigator.pop(context);
                      _startKOTPrintingBluetoothOnly(context, printer);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// BT KOT Print
  Future<void> _startKOTPrintingBluetoothOnly(
      BuildContext context, BluetoothInfo printer) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: appPrimaryColor),
              SizedBox(height: 16),
              Text("Preparing KOT for Bluetooth printer...",
                  style: TextStyle(color: whiteColor)),
            ],
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 300));
      await WidgetsBinding.instance.endOfFrame;

      Uint8List? imageBytes = await captureMonochromeKOTReceipt(kotReceiptKey);

      print("Image bytes null? ${imageBytes == null}");
      print("Key currentContext: ${kotReceiptKey.currentContext}");

      if (imageBytes != null) {
        final bool connectionResult = await PrintBluetoothThermal.connect(
            macPrinterAddress: printer.macAdress);

        if (!connectionResult) {
          throw Exception("Failed to connect to printer");
        }

        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm58, profile);

        final decodedImage = img.decodeImage(imageBytes);
        if (decodedImage != null) {
          // Updated API for image package v4.x
          final resizedImage = img.copyResize(
            decodedImage,
            width: 384,
            maintainAspect: true,
          );

          List<int> bytes = [];
          bytes += generator.reset();

          // For image v4.x, the imageRaster method signature may be different
          // Check the documentation, but this should work:
          bytes += generator.imageRaster(resizedImage);

          bytes += generator.feed(2);
          bytes += generator.cut();

          final bool printResult =
          await PrintBluetoothThermal.writeBytes(bytes);
          await PrintBluetoothThermal.disconnect;

          Navigator.of(context).pop();

          if (printResult) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("KOT printed to Bluetooth printer!"),
                backgroundColor: greenColor,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Failed to send data to printer"),
                backgroundColor: redColor,
              ),
            );
          }
        }
      } else {
        Navigator.of(context).pop();
        throw Exception("Failed to capture KOT receipt image");
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("KOT Print failed: $e"),
          backgroundColor: redColor,
        ),
      );
    }
  }

  /// LAN KOT Print
  Future<void> _startKOTPrintingThermalOnly(
      BuildContext context, String printerIp) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: appPrimaryColor),
              SizedBox(height: 16),
              Text("Preparing KOT for thermal printer...",
                  style: TextStyle(color: whiteColor)),
            ],
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 300));
      await WidgetsBinding.instance.endOfFrame;

      Uint8List? imageBytes = await captureMonochromeKOTReceipt(kotReceiptKey);
      if (imageBytes != null) {
        final printer = PrinterNetworkManager(printerIp);
        final result = await printer.connect();

        if (result == PosPrintResult.success) {
          final profile = await CapabilityProfile.load();
          final generator = Generator(PaperSize.mm58, profile);

          final decodedImage = img.decodeImage(imageBytes);
          if (decodedImage != null) {
            final resizedImage = img.copyResize(
              decodedImage,
              width: 384, // 58mm = ~384 dots at 203 DPI
              maintainAspect: true,
            );
            List<int> bytes = [];
            bytes += generator.reset();
            bytes += generator.imageRaster(
              resizedImage,
              align: PosAlign.center,
              highDensityHorizontal: true, // Better quality
              highDensityVertical: true,
            );
            bytes += generator.feed(2);
            bytes += generator.cut();
            await printer.printTicket(bytes);
          }

          await printer.disconnect();

          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("KOT printed to thermal printer only!"),
              backgroundColor: greenColor,
            ),
          );
        } else {
          // ❌ Failed to connect
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to connect to printer ($result)"),
              backgroundColor: redColor,
            ),
          );
        }
      } else {
        Navigator.of(context).pop();
        throw Exception("Failed to capture KOT receipt image");
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("KOT Print failed: $e"),
          backgroundColor: redColor,
        ),
      );
    }
  }

  /* Future<void> _printBillToTvsThermalOnly(
      BuildContext context,
      ) async {

    try {

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      Uint8List? imageBytes =
      await captureMonochromeReceipt(
        normalReceiptKey,
      );

      Navigator.pop(context);

      if (imageBytes == null) {
        throw Exception("Receipt image capture failed");
      }

      final printer = FlutterTvsPrinter();

      final response =
      await printer.printReceipt(imageBytes);

      String message = "";

      switch (response) {

        case "PRINT_SUCCESS_WITH_FULL_CUT":
          message =
          "Receipt printed with full cut";
          break;

        case "PRINT_SUCCESS_WITH_PARTIAL_CUT":
          message =
          "Receipt printed with partial cut";
          break;

        case "PRINT_SUCCESS_MANUAL_TEAR":
          message =
          "Receipt printed. Please tear manually.";
          break;

        case "PAPER_OUT":
          message = "Printer paper out";
          break;

        case "PRINTER_BUSY":
          message = "Printer busy";
          break;

        case "PRINTER_FAULT":
          message = "Printer fault";
          break;

        case "PRINTER_OVERHEAT":
          message = "Printer overheated";
          break;

        case "PRINTER_NOT_AVAILABLE":
          message = "Printer not available";
          break;

        default:
          message = "Printing failed";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

    } catch (e) {

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Print failed: $e"),
        ),
      );
    }
  }
*/

  Future<void> _printBillToTvsThermalOnly(
      BuildContext context,
      ) async {

    try {

      // 🔥 SELECT CUT MODE
      final cutMode = "FEED";
      /* await showModalBottomSheet<String>(
        context: context,
        builder: (context) {

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const SizedBox(height: 16),

                const Text(
                  "Select Printer Cut Mode",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                ListTile(
                  title: const Text("Normal Cut"),
                  onTap: () {
                    Navigator.pop(context, "NORMAL");
                  },
                ),

                ListTile(
                  title: const Text("Delay Cut"),
                  onTap: () {
                    Navigator.pop(context, "DELAY");
                  },
                ),

                ListTile(
                  title: const Text("Feed + Cut"),
                  onTap: () {
                    Navigator.pop(context, "FEED");
                  },
                ),

                ListTile(
                  title: const Text("Partial Cut"),
                  onTap: () {
                    Navigator.pop(context, "PARTIAL");
                  },
                ),

                ListTile(
                  title: const Text("ESC/POS Raw Cut"),
                  onTap: () {
                    Navigator.pop(context, "RAW");
                  },
                ),

                ListTile(
                  title: const Text("Large Feed Cut"),
                  onTap: () {
                    Navigator.pop(context, "LARGE_FEED");
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );

      // user cancelled
      if (cutMode == null) {
        return;
      }*/

      // 🔥 LOADING
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      Uint8List? imageBytes =
      await captureMonochromeReceipt(
        normalReceiptKey,
      );

      Navigator.pop(context);

      if (imageBytes == null) {
        throw Exception("Receipt image capture failed");
      }

      final printer = FlutterTvsPrinter();

      // 🔥 SEND CUT MODE
      final response =
      await printer.printReceipt(
        imageBytes,
        cutMode: cutMode,
      );

      String message = "";

      switch (response) {

        case "NORMAL_CUT_DONE":
          message =
          "Receipt printed using NORMAL CUT";
          break;

        case "DELAY_CUT_DONE":
          message =
          "Receipt printed using DELAY CUT";
          break;

        case "FEED_CUT_DONE":
          message =
          "Receipt printed using FEED + CUT";
          break;

        case "PARTIAL_CUT_DONE":
          message =
          "Receipt printed using PARTIAL CUT";
          break;

        case "RAW_CUT_DONE":
          message =
          "Receipt printed using ESC/POS RAW CUT";
          break;

        case "LARGE_FEED_CUT_DONE":
          message =
          "Receipt printed using LARGE FEED CUT";
          break;

        case "PAPER_OUT":
          message = "Printer paper out";
          break;

        case "PRINTER_BUSY":
          message = "Printer busy";
          break;

        case "PRINTER_FAULT":
          message = "Printer fault";
          break;

        case "PRINTER_OVERHEAT":
          message = "Printer overheated";
          break;

        case "PRINTER_NOT_AVAILABLE":
          message = "Printer not available";
          break;

        default:
          message = "Printing failed : $response";
      }

      /* ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );*/

    } catch (e) {

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Print failed: $e"),
        ),
      );
    }
  }

  Future<void> _printBillToSunmi(BuildContext context) async {

    debugPrint("_printBillToSunmi home screen");

    try {
      if (!context.mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: appPrimaryColor),
              SizedBox(height: 16),
              Text(
                "Printing to Sunmi device...",
                style: TextStyle(color: whiteColor),
              ),
            ],
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      await WidgetsBinding.instance.endOfFrame;

      // Capture the receipt with proper sizing for 58mm printer
      Uint8List? imageBytes = await captureMonochromeReceipt(normalReceiptKey);

      if (imageBytes == null) {
        Navigator.of(context).pop();
        throw Exception("Image capture failed: normalReceiptKey returned null");
      }

      // Initialize printer and print
      await SunmiPrinter.bindingPrinter();
      await SunmiPrinter.initPrinter();
      await SunmiPrinter.printImage(imageBytes);
      await SunmiPrinter.lineWrap(2);
      await SunmiPrinter.cutPaper();

      Navigator.of(context).pop();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bill printed successfully on Sunmi device!"),
            backgroundColor: greenColor,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Sunmi print failed: $e"),
            backgroundColor: redColor,
          ),
        );
      }
    }
  }


  Future<void> _printBillToIminOnly(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: appPrimaryColor,
              ),
              SizedBox(height: 16),
              Text("Printing to IMIN device...",
                  style: TextStyle(color: whiteColor)),
            ],
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      await WidgetsBinding.instance.endOfFrame;

      Uint8List? imageBytes = await captureMonochromeReceipt(normalReceiptKey);

      if (imageBytes != null) {
        await printerService.init();
        await printerService.printBitmap(imageBytes);
        await printerService.fullCut();

        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bill printed successfully to IMIN device!"),
            backgroundColor: greenColor,
          ),
        );
      } else {
        throw Exception("Image capture failed: normalReceiptKey returned null");
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("IMIN Print failed: $e"),
          backgroundColor: redColor,
        ),
      );
    }
  }

  Future<void> printGenerateOrderReceipt() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final details = await injector<OrderRepository>().getLocationDetails();
        setState(() {
          _locationDetails = details;
          _isLoadingLocation = false;
          if (_locationDetails?.data?.posKotPrinterIpAddress != null &&
              _locationDetails!.data!.posKotPrinterIpAddress!.isNotEmpty) {
            ipController.text = _locationDetails!.data!.posKotPrinterIpAddress!;
          }
        });
      } catch (e) {
        debugPrint("Error fetching location details in printGenerateOrderReceipt: $e");
        setState(() {
          _isLoadingLocation = false;
        });
      }

      List<Map<String, dynamic>> items = postGenerateOrderModel.order!.items!
          .map((e) => {
        'name': e.name,
        'qty': e.quantity,
        'price': (e.unitPrice ?? 0).toDouble(),
        'total': ((e.quantity ?? 0) * (e.unitPrice ?? 0)).toDouble(),
      })
          .toList();
      List<Map<String, dynamic>> kotItems = postGenerateOrderModel.invoice!.kot!
          .map((e) => {
        'name': e.name,
        'qty': e.quantity,
      })
          .toList();
      List<Map<String, dynamic>> finalTax =
      postGenerateOrderModel.order!.finalTaxes!
          .map((e) => {
        'name': e.name,
        'amt': e.amount,
      })
          .toList();

      String businessName = postGenerateOrderModel.invoice!.businessName ?? '';
      String address = postGenerateOrderModel.invoice!.address ?? '';
      String gst = postGenerateOrderModel.invoice!.gstNumber ?? '';
      String description = postGenerateOrderModel.invoice!.description ?? '';
      double taxPercent = (postGenerateOrderModel.order!.tax ?? 0.0).toDouble();
      String orderNumber = postGenerateOrderModel.order!.orderNumber ?? 'N/A';
      String paymentMethod = postGenerateOrderModel.invoice!.paidBy ?? '';
      String phone = postGenerateOrderModel.invoice!.phone ?? '';
      double subTotal =
      (postGenerateOrderModel.invoice!.subtotal ?? 0.0).toDouble();
      double total = (postGenerateOrderModel.invoice!.total ?? 0.0).toDouble();
      String orderType = postGenerateOrderModel.order!.orderType ?? '';
      String orderStatus = postGenerateOrderModel.invoice!.orderStatus ?? '';
      String tableName =
          postGenerateOrderModel.invoice?.tableName?.toString() ?? 'N/A';
      String waiterName =
          postGenerateOrderModel.invoice?.waiterName?.toString() ?? 'N/A';
      String date = formatInvoiceDate(postGenerateOrderModel.invoice?.date);
      String thermalIp = postGenerateOrderModel.invoice?.thermalIp?.toString() ?? "";
      if (storedIpAddress != null && storedIpAddress!.isNotEmpty) {
        ipController.text = storedIpAddress!;
      } else if (thermalIp != "null" && thermalIp.isNotEmpty) {
        ipController.text = thermalIp;
      } else {
        ipController.text = "";
      }
      debugPrint("ip:${ipController.text}");
      Navigator.of(context).pop();

      await showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.4,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  if (_shopLogo != null && _shopLogo!.isNotEmpty) ...[
                    Center(
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.center,
                          heightFactor: 0.65,
                          child: Image.network(
                            _shopLogo!,
                            height: 80,
                            width: 80,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  // Normal Bill Receipt
                  RepaintBoundary(
                    key: normalReceiptKey,
                    child: getThermalReceiptWidget(
                      businessName: businessName,
                      address: address,
                      gst: gst,
                      items: items,
                      finalTax: finalTax,
                      tax: taxPercent,
                      paidBy: paymentMethod,
                      tamilTagline: '',
                      phone: phone,
                      subtotal: subTotal,
                      total: total,
                      orderNumber: orderNumber,
                      tableName: tableName,
                      waiterName: waiterName,
                      orderType: orderType,
                      date: date,
                      status: orderStatus,
                      description: description,
                    ),
                  ),

                  // KOT Receipt (hidden - kept for print capture only)
                  if (postGenerateOrderModel.invoice!.kot!.isNotEmpty)
                    Opacity(
                      opacity: 0,
                      child: SizedBox(
                        height: 0,
                        child: RepaintBoundary(
                          key: kotReceiptKey,
                          child: getThermalReceiptKOTWidget(isKot: true,
                            businessName: businessName,
                            address: address,
                            gst: gst,
                            items: kotItems,
                            paidBy: paymentMethod,
                            tamilTagline: '',
                            phone: phone,
                            subtotal: subTotal,
                            tax: taxPercent,
                            total: total,
                            orderNumber: orderNumber,
                            tableName: tableName,
                            waiterName: waiterName,
                            orderType: orderType,
                            date: date,
                            status: orderStatus,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Single KOT Print button - internally routes to WiFi or Bluetooth
                      // if (postGenerateOrderModel.invoice!.kot!.isNotEmpty &&
                      //     _locationDetails?.data?.posKotPrinterConnectionType != null &&
                      //     _locationDetails!.data!.posKotPrinterConnectionType!.isNotEmpty) ...[
                        ElevatedButton.icon(
                          onPressed: () {
                            final connType = _locationDetails!.data!.posKotPrinterConnectionType!.toUpperCase();
                            if (connType == "WIFI") {
                              final String ip = (_locationDetails?.data?.posKotPrinterIpAddress != null &&
                                                  _locationDetails!.data!.posKotPrinterIpAddress!.isNotEmpty)
                                  ? _locationDetails!.data!.posKotPrinterIpAddress!
                                  : (storedIpAddress ?? (thermalIp.isNotEmpty ? thermalIp : ipController.text.trim()));
                              _startKOTPrintingThermalOnly(context, ip);
                            } else if (connType == "BLUETOOTH") {
                              _selectBluetoothPrinter(context);
                            }
                          },
                          icon: const Icon(Icons.print),
                          label: const Text("KOT Print"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: greenColor,
                            foregroundColor: whiteColor,
                          ),
                        ),
                        horizontalSpace(width: 10),
                      // ],
                      // Normal Print button
                      if (_isLoadingLocation)
                        const CircularProgressIndicator(color: appPrimaryColor)
                      else ...[
                        if (_locationDetails?.data?.posPrinterName != null &&
                            _locationDetails!.data!.posPrinterName!.isNotEmpty) ...[
                          // TVS Print button - show when pos_printer_name is not empty
                          ElevatedButton.icon(
                            onPressed: () async {
                              WidgetsBinding.instance.addPostFrameCallback((_) async {
                                await _printBillToTvsThermalOnly(context);
                              });
                            },
                            icon: const Icon(Icons.print),
                            label: const Text("Print"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: greenColor,
                              foregroundColor: whiteColor,
                            ),
                          ),
                          horizontalSpace(width: 10),
                        ] else ...[
                          if (Constants.currentPrinter != PrinterType.external) ...[
                            ElevatedButton.icon(
                              onPressed: () async {
                                WidgetsBinding.instance.addPostFrameCallback((_) async {
                                  if (Constants.currentPrinter == PrinterType.tvs) {
                                    await _printBillToTvsThermalOnly(context);
                                  } else if (Constants.currentPrinter == PrinterType.sunmi) {
                                    await _printBillToSunmi(context);
                                  } else if (Constants.currentPrinter == PrinterType.imin) {
                                    await _ensureIminServiceReady();
                                    await _printBillToIminOnly(context);
                                  }
                                });
                              },
                              icon: const Icon(Icons.print),
                              label: const Text("Print"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: greenColor,
                                foregroundColor: whiteColor,
                              ),
                            ),
                            horizontalSpace(width: 10),
                          ],
                          if (Constants.currentPrinter == PrinterType.external) ...[
                            ElevatedButton.icon(
                              onPressed: () async {
                                WidgetsBinding.instance.addPostFrameCallback((_) async {
                                  if (ipController.text.isNotEmpty) {
                                    await _printBillToThermalOnly(context, ipController.text.trim());
                                  } else {
                                    _showPrinterIpDialog(context);
                                  }
                                });
                              },
                              icon: const Icon(Icons.print),
                              label: const Text("Print"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: greenColor,
                                foregroundColor: whiteColor,
                              ),
                            ),
                            horizontalSpace(width: 10),
                          ],
                        ],
                      ],





                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.09,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "CLOSE",
                            style: TextStyle(color: appPrimaryColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  Future<void> printUpdateOrderReceipt() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        final details = await injector<OrderRepository>().getLocationDetails();
        setState(() {
          _locationDetails = details;
          _isLoadingLocation = false;
          if (_locationDetails?.data?.posKotPrinterIpAddress != null &&
              _locationDetails!.data!.posKotPrinterIpAddress!.isNotEmpty) {
            ipController.text = _locationDetails!.data!.posKotPrinterIpAddress!;
          }
        });
      } catch (e) {
        debugPrint("Error fetching location details in printUpdateOrderReceipt: $e");
        setState(() {
          _isLoadingLocation = false;
        });
      }
      List<Map<String, dynamic>> items = updateGenerateOrderModel.order!.items!
          .map((e) => {
        'name': e.name,
        'qty': e.quantity,
        'price': (e.unitPrice ?? 0).toDouble(),
        'total': ((e.quantity ?? 0) * (e.unitPrice ?? 0)).toDouble(),
      })
          .toList();
      List<Map<String, dynamic>> kotItems =
      updateGenerateOrderModel.invoice!.kot!
          .map((e) => {
        'name': e.name,
        'qty': e.quantity,
      })
          .toList();
      List<Map<String, dynamic>> finalTax =
      updateGenerateOrderModel.invoice!.finalTaxes!
          .map((e) => {
        'name': e.name,
        'amt': double.parse(e.amount.toString()),
      })
          .toList();
      String businessName =
          updateGenerateOrderModel.invoice!.businessName ?? '';
      String address = updateGenerateOrderModel.invoice!.address ?? '';
      String gst = updateGenerateOrderModel.invoice!.gstNumber ?? '';
      String description = updateGenerateOrderModel.invoice!.description ?? '';
      double taxPercent =
      (updateGenerateOrderModel.order!.tax ?? 0.0).toDouble();
      String orderNumber = updateGenerateOrderModel.order!.orderNumber ?? 'N/A';
      String paymentMethod = updateGenerateOrderModel.invoice!.paidBy ?? '';
      String phone = updateGenerateOrderModel.invoice!.phone ?? '';
      double subTotal =
      (updateGenerateOrderModel.invoice!.subtotal ?? 0.0).toDouble();
      double total =
      (updateGenerateOrderModel.invoice!.total ?? 0.0).toDouble();
      String orderType = updateGenerateOrderModel.order!.orderType ?? '';
      String orderStatus = updateGenerateOrderModel.invoice!.orderStatus ?? '';
      String tableName =
          updateGenerateOrderModel.invoice?.tableName?.toString() ?? 'N/A';
      String waiterName =
          updateGenerateOrderModel.invoice?.waiterName?.toString() ?? 'N/A';
      String date = formatInvoiceDate(updateGenerateOrderModel.invoice?.date);
      String thermalIp = updateGenerateOrderModel.invoice?.thermalIp?.toString() ?? "";
      if (storedIpAddress != null && storedIpAddress!.isNotEmpty) {
        ipController.text = storedIpAddress!;
      } else if (thermalIp != "null" && thermalIp.isNotEmpty) {
        ipController.text = thermalIp;
      } else {
        ipController.text = "";
      }
      debugPrint("ip:${ipController.text}");
      Navigator.of(context).pop();
      await showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.4,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  if (_shopLogo != null && _shopLogo!.isNotEmpty) ...[
                    Center(
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.center,
                          heightFactor: 0.65,
                          child: Image.network(
                            _shopLogo!,
                            height: 80,
                            width: 80,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  RepaintBoundary(
                    key: normalReceiptKey,
                    child: getThermalReceiptWidget(
                      businessName: businessName,
                      address: address,
                      gst: gst,
                      items: items,
                      finalTax: finalTax,
                      tax: taxPercent,
                      paidBy: paymentMethod,
                      tamilTagline: '',
                      phone: phone,
                      subtotal: subTotal,
                      total: total,
                      orderNumber: orderNumber,
                      tableName: tableName,
                      waiterName: waiterName,
                      orderType: orderType,
                      date: date,
                      status: orderStatus,
                      description: description,
                    ),
                  ),
                  // KOT Receipt (hidden - kept for print capture only)
                  if (updateGenerateOrderModel.invoice!.kot!.isNotEmpty)
                    Opacity(
                      opacity: 0,
                      child: SizedBox(
                        height: 0,
                        child: RepaintBoundary(
                          key: kotReceiptKey,
                          child: getThermalReceiptKOTWidget(
                            businessName: businessName,
                            address: address,
                            gst: gst,
                            items: kotItems,
                            paidBy: paymentMethod,
                            tamilTagline: '',
                            phone: phone,
                            subtotal: subTotal,
                            tax: taxPercent,
                            total: total,
                            orderNumber: orderNumber,
                            tableName: tableName,
                            waiterName: waiterName,
                            orderType: orderType,
                            date: date,
                            status: orderStatus,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Single KOT Print button - internally routes to WiFi or Bluetooth
                      if (updateGenerateOrderModel.invoice!.kot!.isNotEmpty &&
                          _locationDetails?.data?.posKotPrinterConnectionType != null &&
                          _locationDetails!.data!.posKotPrinterConnectionType!.isNotEmpty) ...[
                        ElevatedButton.icon(
                          onPressed: () {
                            final connType = _locationDetails!.data!.posKotPrinterConnectionType!.toUpperCase();
                            if (connType == "WIFI") {
                              final String ip = (_locationDetails?.data?.posKotPrinterIpAddress != null &&
                                                  _locationDetails!.data!.posKotPrinterIpAddress!.isNotEmpty)
                                  ? _locationDetails!.data!.posKotPrinterIpAddress!
                                  : (storedIpAddress ?? (thermalIp.isNotEmpty ? thermalIp : ipController.text.trim()));
                              _startKOTPrintingThermalOnly(context, ip);
                            } else if (connType == "BLUETOOTH") {
                              _selectBluetoothPrinter(context);
                            }
                          },
                          icon: const Icon(Icons.print),
                          label: const Text("KOT Print"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: greenColor,
                            foregroundColor: whiteColor,
                          ),
                        ),
                        horizontalSpace(width: 10),
                      ],
                      // Normal Print button
                      if (_isLoadingLocation)
                        const CircularProgressIndicator(color: appPrimaryColor)
                      else ...[
                        if (_locationDetails?.data?.posPrinterName != null &&
                            _locationDetails!.data!.posPrinterName!.isNotEmpty) ...[
                          // TVS Print button - show when pos_printer_name is not empty
                          ElevatedButton.icon(
                            onPressed: () async {
                              WidgetsBinding.instance.addPostFrameCallback((_) async {
                                await _printBillToTvsThermalOnly(context);
                              });
                            },
                            icon: const Icon(Icons.print),
                            label: const Text("Print"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: greenColor,
                              foregroundColor: whiteColor,
                            ),
                          ),
                          horizontalSpace(width: 10),
                        ] else ...[
                          if (Constants.currentPrinter != PrinterType.external) ...[
                            ElevatedButton.icon(
                              onPressed: () async {
                                WidgetsBinding.instance.addPostFrameCallback((_) async {
                                  if (Constants.currentPrinter == PrinterType.tvs) {
                                    await _printBillToTvsThermalOnly(context);
                                  } else if (Constants.currentPrinter == PrinterType.sunmi) {
                                    await _printBillToSunmi(context);
                                  } else if (Constants.currentPrinter == PrinterType.imin) {
                                    await _ensureIminServiceReady();
                                    await _printBillToIminOnly(context);
                                  }
                                });
                              },
                              icon: const Icon(Icons.print),
                              label: const Text("Print"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: greenColor,
                                foregroundColor: whiteColor,
                              ),
                            ),
                            horizontalSpace(width: 10),
                          ],
                          if (Constants.currentPrinter == PrinterType.external) ...[
                            ElevatedButton.icon(
                              onPressed: () async {
                                WidgetsBinding.instance.addPostFrameCallback((_) async {
                                  if (ipController.text.isNotEmpty) {
                                    await _printBillToThermalOnly(context, ipController.text.trim());
                                  } else {
                                    _showPrinterIpDialog(context);
                                  }
                                });
                              },
                              icon: const Icon(Icons.print),
                              label: const Text("Print"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: greenColor,
                                foregroundColor: whiteColor,
                              ),
                            ),
                            horizontalSpace(width: 10),
                          ],
                        ],
                      ],
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.09,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "CLOSE",
                            style: TextStyle(color: appPrimaryColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      if (e is DioException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.message}"),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Something went wrong: ${e.toString()}"),
          ),
        );
      }
    }
  }

  void refreshHome() {
    if (!mounted || !context.mounted) return;
    context.read<FoodCategoryBloc>().add(FoodCategory());
    context.read<FoodCategoryBloc>().add(FoodProductItem(
        selectedCatId.toString(),
        searchController.text,
        searchProdIdController.text));
    setState(() {
      categoryLoad = true;
      resetCartState();
    });
  }

  Future<void> getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
        setState(() {
          serialNumber = androidInfo.id;
          debugPrint("Device ID: $serialNumber");
        });
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
        setState(() {
          serialNumber =
              iosInfo.identifierForVendor ?? 'Unknown iOS Identifier';
          debugPrint("Device ID: $serialNumber");
        });
      }
    } catch (e) {
      setState(() {
        serialNumber = 'Error getting device info';
        debugPrint("Device ID: $serialNumber");
      });
    }
  }

  void loadExistingOrder(GetViewOrderModel? order) {
    if (order == null || order.data == null) return;
    debugPrint("existOrderId:${widget.existingOrder?.data?.id}");
    final data = order.data!;

    setState(() {
      switch (data.orderType) {
        case 'LINE':
          selectedOrderType = OrderType.line;
          break;
        case 'PARCEL':
          selectedOrderType = OrderType.parcel;
          break;
        case 'AC':
          selectedOrderType = OrderType.ac;
          break;
        case 'HD':
          selectedOrderType = OrderType.hd;
          break;
        case 'SWIGGY':
          selectedOrderType = OrderType.swiggy;
          break;
        default:
          selectedOrderType = OrderType.line;
      }
      tableId = data.tableNo;
      waiterId = data.waiter;
      selectedValue = data.tableName;
      selectedValueWaiter = data.waiterName;
      isCartLoaded = true;
      isDiscountApplied =
          widget.existingOrder?.data!.isDiscountApplied ?? false;
      billingItems = data.items?.map((e) {
        final product = e.product;
        return {
          "_id": product?.id,
          "name": e.name,
          "basePrice": (product?.basePrice ?? 0),
          "qty": e.quantity,
          "image": product?.image,
          "unitmasterid": product?.unitmasterid,
          "selectedAddons": e.addons?.map((addonItem) {
            final addon = addonItem.addon;
            return {
              "_id": addon?.id,
              "name": addon?.name,
              "price": addon?.price,
              "isFree": addon?.isFree,
              "quantity": addonItem.quantity ?? 1,
              "isAvailable": addon?.isAvailable,
              "maxQuantity": addon?.maxQuantity,
            };
          }).toList() ??
              [],
        };
      }).toList() ??
          [];
      context.read<FoodCategoryBloc>().add(AddToBilling(
          List.from(billingItems),
          widget.existingOrder?.data!.isDiscountApplied ?? false,
          OrderTypeX.fromApi(widget.existingOrder?.data!.orderType ?? "LINE")));
    });
  }

  void resetCartState() {
    setState(() {
      billingItems.clear();
      tableId = null;
      waiterId = null;
      selectedValue = null;
      selectedValueWaiter = null;
      _resetToDefaultOrderType();
      isSplitPayment = false;
      amountController.clear();
      selectedFullPaymentMethod = "";
      widget.isEditingOrder = false;
      balance = 0;
      if (billingItems.isEmpty || billingItems == []) {
        isDiscountApplied = false;
      }
      context
          .read<FoodCategoryBloc>()
          .add(AddToBilling([], isDiscountApplied, selectedOrderType));
    });
  }

  Future<void> _loadStoredIp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      storedIpAddress = prefs.getString('thermal_printer_ip');
      if (storedIpAddress != null && storedIpAddress!.isNotEmpty) {
        ipController.text = storedIpAddress!;
      }
    });

    if (Constants.currentPrinter == PrinterType.external &&
        (storedIpAddress == null || storedIpAddress!.isEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPrinterIpDialog(context);
      });
    }
  }

  Future<void> _loadShopLogo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _shopLogo = prefs.getString('shop_logo');
    });
  }

  Future<void> _printBillToBluetoothOnly(
      BuildContext context, BluetoothInfo printer) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: appPrimaryColor),
              SizedBox(height: 16),
              Text("Preparing Bill for Bluetooth printer...",
                  style: TextStyle(color: whiteColor)),
            ],
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 300));
      await WidgetsBinding.instance.endOfFrame;

      Uint8List? imageBytes = await captureMonochromeReceipt(normalReceiptKey);

      if (imageBytes != null) {
        final bool connectionResult = await PrintBluetoothThermal.connect(
            macPrinterAddress: printer.macAdress);

        if (!connectionResult) {
          throw Exception("Failed to connect to printer");
        }

        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm58, profile);

        final img.Image? decodedImage = img.decodeImage(imageBytes);
        if (decodedImage != null) {
          final img.Image resizedImage = img.copyResize(decodedImage, width: 360);

          List<int> resetBytes = generator.reset();
          await PrintBluetoothThermal.writeBytes(resetBytes);
          await Future.delayed(const Duration(milliseconds: 100));

          const int chunkHeight = 128;
          final int totalHeight = resizedImage.height;
          bool printResult = true;

          for (int y = 0; y < totalHeight; y += chunkHeight) {
            final int h = (y + chunkHeight > totalHeight) ? totalHeight - y : chunkHeight;
            final img.Image chunk = img.copyCrop(resizedImage, x: 0, y: y, width: resizedImage.width, height: h);

            List<int> chunkBytes = generator.imageRaster(chunk, align: PosAlign.center);
            printResult = await PrintBluetoothThermal.writeBytes(chunkBytes);
            if (!printResult) break;

            await Future.delayed(const Duration(milliseconds: 200));
          }

          if (printResult) {
            List<int> endBytes = [];
            endBytes += generator.cut();
            await PrintBluetoothThermal.writeBytes(endBytes);
          }

          await PrintBluetoothThermal.disconnect;

          Navigator.of(context).pop();

          if (printResult) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Bill printed to Bluetooth printer!"),
                backgroundColor: greenColor,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Failed to send data to printer"),
                backgroundColor: redColor,
              ),
            );
          }
        }
      } else {
        Navigator.of(context).pop();
        throw Exception("Failed to capture receipt image");
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Bluetooth Print failed: $e"),
          backgroundColor: redColor,
        ),
      );
    }
  }

  Future<void> _selectBluetoothBillPrinter(BuildContext context) async {
    await _scanBluetoothDevices();

    if (_devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "No paired Bluetooth printers found. Please pair your printer first."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Select Bluetooth Printer for Bill",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _devices.length,
                itemBuilder: (_, index) {
                  final printer = _devices[index];
                  return ListTile(
                    leading: const Icon(Icons.print),
                    title: Text(printer.name),
                    subtitle: Text(printer.macAdress),
                    onTap: () {
                      Navigator.pop(context);
                      _printBillToBluetoothOnly(context, printer);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _printBillToThermalOnly(
      BuildContext context, String printerIp) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: appPrimaryColor),
              SizedBox(height: 16),
              Text("Preparing Bill for thermal printer...",
                  style: TextStyle(color: whiteColor)),
            ],
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 300));
      await WidgetsBinding.instance.endOfFrame;

      Uint8List? imageBytes = await captureMonochromeReceipt(normalReceiptKey);
      if (imageBytes != null) {
        final printer = PrinterNetworkManager(printerIp);
        final result = await printer.connect();

        if (result == PosPrintResult.success) {
          final profile = await CapabilityProfile.load();
          final generator = Generator(PaperSize.mm58, profile);

          final decodedImage = img.decodeImage(imageBytes);
          if (decodedImage != null) {
            final resizedImage = img.copyResize(
              decodedImage,
              width: 384,
              maintainAspect: true,
            );
            List<int> bytes = [];
            bytes += generator.reset();
            bytes += generator.imageRaster(
              resizedImage,
              align: PosAlign.center,
              highDensityHorizontal: true,
              highDensityVertical: true,
            );
            bytes += generator.feed(2);
            bytes += generator.cut();
            await printer.printTicket(bytes);
          }

          await printer.disconnect();

          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Bill printed to thermal printer only!"),
              backgroundColor: greenColor,
            ),
          );
        } else {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to connect to printer (${result.msg})"),
              backgroundColor: redColor,
            ),
          );
          _showPrinterIpDialog(context);
        }
      } else {
        Navigator.of(context).pop();
        throw Exception("Failed to capture Bill receipt image");
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Bill Print failed: $e"),
          backgroundColor: redColor,
        ),
      );
      _showPrinterIpDialog(context);
    }
  }

  Future<void> _fetchLocationDetails() async {
    try {
      final details = await injector<OrderRepository>().getLocationDetails();
      setState(() {
        _locationDetails = details;
        _isLoadingLocation = false;
        if (_locationDetails?.data?.posKotPrinterIpAddress != null &&
            _locationDetails!.data!.posKotPrinterIpAddress!.isNotEmpty) {
          ipController.text = _locationDetails!.data!.posKotPrinterIpAddress!;
        }
      });
    } catch (e) {
      debugPrint("Error fetching location details in home screen: $e");
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStoredIp();
    _loadShopLogo();
    _fetchLocationDetails();
    context.read<FoodCategoryBloc>().add(FetchCompanyCurrent());
    // ipController.text = "192.168.1.123";
    if (kIsWeb) {
      printerService = MockPrinterService();
      printerServiceThermal = MockPrinterService();
    } else if (Platform.isAndroid) {
      printerService = RealPrinterService();
      printerServiceThermal = RealPrinterService();
    } else {
      printerService = MockPrinterService();
      printerServiceThermal = MockPrinterService();
    }
    if (widget.hasRefreshedOrder == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.foodKey?.currentState?.refreshHome();
        setState(() {
          categoryLoad = true;
          getDeviceInfo();
        });
      });
    } else {
      context.read<FoodCategoryBloc>().add(FoodCategory());
      context.read<FoodCategoryBloc>().add(FoodProductItem(
          selectedCatId.toString(),
          searchController.text,
          searchProdIdController.text));
      getDeviceInfo();
    }
    context.read<FoodCategoryBloc>().add(TableDine());
    context.read<FoodCategoryBloc>().add(WaiterDine());
    context.read<FoodCategoryBloc>().add(StockDetails());
    context.read<FoodCategoryBloc>().add(FetchCompanyCurrent());
    setState(() {
      categoryLoad = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isEditingOrder == true && widget.existingOrder != null) {
        loadExistingOrder(widget.existingOrder!);
      } else {
        resetCartState();
      }
    });
  }

  @override
  void dispose() {
    for (var controller in quantityControllers.values) {
      controller.dispose();
    }
    quantityControllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    Widget mainContainer() {
      final sortedCategories = (getCategoryModel.data ?? [])
          .map((data) => Category(
        id: data.id,
        name: data.name,
        image: data.image,
      ))
          .toList();

      final List<Category> displayedCategories = [
        Category(name: 'All', image: Images.all, id: ""),
        ...sortedCategories,
      ];

      double total = (postAddToBillingModel.total ?? 0).toDouble();
      double paidAmount = (widget.existingOrder?.data?.total ?? 0).toDouble();
      balance = total - paidAmount;

      @override
      Widget price(String label, String value, {bool isBold = false}) {
        return SizedBox(
          height: 20,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: isBold
                      ? MyTextStyle.f12(blackColor, weight: FontWeight.bold)
                      : MyTextStyle.f12(greyColor),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  value,
                  style: isBold
                      ? MyTextStyle.f12(blackColor, weight: FontWeight.bold)
                      : MyTextStyle.f12(blackColor),
                ),
              ),
            ],
          ),
        );
      }

      return categoryLoad
          ? Container(
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * 0.2),
          alignment: Alignment.center,
          child: const SpinKitChasingDots(color: appPrimaryColor, size: 30))
          : SafeArea(
        child: Container(
            margin:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: whiteColor,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: blackColor.withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: 2,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.start,
                                  children: [
                                    Text("Choose Category",
                                        style: MyTextStyle.f18(blackColor,
                                            weight: FontWeight.bold)),
                                    SizedBox(width: size.width * 0.05),
                                    Expanded(
                                      child: SizedBox(
                                        width: size.width * 0.25,
                                        child: TextField(
                                          controller: searchController,
                                          decoration: InputDecoration(
                                            hintText: 'Search product',
                                            prefixIcon:
                                            Icon(Icons.search),
                                            contentPadding:
                                            EdgeInsets.symmetric(
                                                horizontal: 16),
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                BorderRadius.circular(
                                                    30)),
                                          ),
                                          onChanged: (value) {
                                            searchController
                                              ..text = (value)
                                              ..selection =
                                              TextSelection.collapsed(
                                                  offset:
                                                  searchController
                                                      .text
                                                      .length);
                                            setState(() {
                                              context
                                                  .read<
                                                  FoodCategoryBloc>()
                                                  .add(
                                                FoodProductItem(
                                                    selectedCatId
                                                        .toString(),
                                                    searchController
                                                        .text,
                                                    searchProdIdController
                                                        .text),
                                              );
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    horizontalSpace(width: 10),
                                    Expanded(
                                      child: SizedBox(
                                        width: size.width * 0.25,
                                        child: TextField(
                                          controller:
                                          searchProdIdController,
                                          decoration: InputDecoration(
                                            hintText:
                                            'Search product code',
                                            prefixIcon:
                                            Icon(Icons.search),
                                            contentPadding:
                                            EdgeInsets.symmetric(
                                                horizontal: 16),
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                BorderRadius.circular(
                                                    30)),
                                          ),
                                          onChanged: (value) {
                                            searchProdIdController
                                              ..text = (value)
                                              ..selection =
                                              TextSelection.collapsed(
                                                  offset:
                                                  searchProdIdController
                                                      .text
                                                      .length);
                                            setState(() {
                                              context
                                                  .read<
                                                  FoodCategoryBloc>()
                                                  .add(
                                                FoodProductItem(
                                                    selectedCatId
                                                        .toString(),
                                                    searchController
                                                        .text,
                                                    searchProdIdController
                                                        .text),
                                              );
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          searchController.clear();
                                          searchProdIdController.clear();
                                        });
                                        context
                                            .read<FoodCategoryBloc>()
                                            .add(FoodCategory());
                                        context
                                            .read<FoodCategoryBloc>()
                                            .add(FoodProductItem(
                                            selectedCatId.toString(),
                                            searchController.text,
                                            searchProdIdController
                                                .text));
                                      },
                                      icon: const Icon(Icons.refresh),
                                    ),
                                  ],
                                ),
                              ),
                              displayedCategories.isEmpty
                                  ? Container()
                                  : SizedBox(
                                height: size.height * 0.13,
                                width: size.width * 0.6,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount:
                                  displayedCategories.length,
                                  separatorBuilder: (_, __) =>
                                      SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    final category =
                                    displayedCategories[index];
                                    final isSelected =
                                        category.name ==
                                            selectedCategory;
                                    return CategoryCard(
                                      label: category.name!,
                                      imagePath:
                                      category.image ?? "",
                                      isSelected: isSelected,
                                      onTap: () {
                                        setState(() {
                                          selectedCategory =
                                          category.name!;
                                          selectedCatId =
                                              category.id;
                                          if (selectedCategory ==
                                              'All') {
                                            context
                                                .read<
                                                FoodCategoryBloc>()
                                                .add(FoodProductItem(
                                                selectedCatId
                                                    .toString(),
                                                searchController
                                                    .text,
                                                searchProdIdController
                                                    .text));
                                          } else {
                                            context
                                                .read<
                                                FoodCategoryBloc>()
                                                .add(
                                              FoodProductItem(
                                                  selectedCatId
                                                      .toString(),
                                                  searchController
                                                      .text,
                                                  searchProdIdController
                                                      .text),
                                            );
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                              SizedBox(
                                height: size.height * 0.6,
                                width: size.width * 0.6,
                                child:
                                getProductByCatIdModel.rows == null ||
                                    getProductByCatIdModel.rows ==
                                        [] ||
                                    getProductByCatIdModel
                                        .rows!.isEmpty
                                    ? Container()
                                    : GridView.builder(
                                  padding: EdgeInsets.all(12),
                                  gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                    MediaQuery.of(context)
                                        .size
                                        .width >
                                        600
                                        ? 3
                                        : 2,
                                    mainAxisExtent: counter == 0
                                        ? size.height * 0.38
                                        : size.height * 0.35,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                                  itemCount:
                                  getProductByCatIdModel
                                      .rows!.length,
                                  itemBuilder: (_, index) {
                                    num getCurrentQuantity(
                                        String productId) {
                                      return billingItems
                                          .firstWhere(
                                            (item) =>
                                        item['_id'] ==
                                            productId,
                                        orElse: () => {},
                                      )['qty'] ??
                                          0;
                                    }

                                    TextEditingController
                                    getQuantityController(
                                        String productId) {
                                      if (!quantityControllers
                                          .containsKey(
                                          productId)) {
                                        final currentQty =
                                        getCurrentQuantity(
                                            productId);
                                        quantityControllers[
                                        productId] =
                                            TextEditingController(
                                                text: currentQty
                                                    .toString());
                                      }
                                      return quantityControllers[
                                      productId]!;
                                    }

                                    void updateControllerText(
                                        String productId,
                                        num quantity) {
                                      if (quantityControllers
                                          .containsKey(
                                          productId)) {
                                        quantityControllers[
                                        productId]!
                                            .text =
                                            ((quantity % 1 == 0) ? quantity.toInt().toString() : quantity.toString());
                                      }
                                    }

                                    final p =
                                    getProductByCatIdModel
                                        .rows![index];
                                    num currentQuantity =
                                    getCurrentQuantity(
                                        p.id.toString());
                                    TextEditingController
                                    currentController =
                                    getQuantityController(
                                        p.id.toString());
                                    return InkWell(
                                      onTap: () {
                                         if (p.isVariant == true) {
                                           _showVariantSelectionDialog(p);
                                           return;
                                         }
                                        setState(() {
                                          currentQuantity = 1;
                                          if (p.addons!
                                              .isNotEmpty) {
                                            showDialog(
                                              context: context,
                                              builder:
                                                  (context2) {
                                                return BlocProvider(
                                                  create: (context) =>
                                                      FoodCategoryBloc(),
                                                  child:
                                                  BlocProvider
                                                      .value(
                                                    value: BlocProvider.of<
                                                        FoodCategoryBloc>(
                                                        context,
                                                        listen:
                                                        false),
                                                    child: StatefulBuilder(builder:
                                                        (context,
                                                        setState) {
                                                      return Dialog(
                                                        insetPadding: EdgeInsets.symmetric(
                                                            horizontal:
                                                            40,
                                                            vertical:
                                                            24),
                                                        shape:
                                                        RoundedRectangleBorder(
                                                          borderRadius:
                                                          BorderRadius.circular(8),
                                                        ),
                                                        child:
                                                        Container(
                                                          constraints:
                                                          BoxConstraints(
                                                            maxWidth:
                                                            size.width * 0.4,
                                                            maxHeight:
                                                            size.height * 0.6,
                                                          ),
                                                          padding:
                                                          EdgeInsets.all(16),
                                                          child:
                                                          SingleChildScrollView(
                                                            child:
                                                            Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                ClipRRect(
                                                                    borderRadius: BorderRadius.circular(15.0),
                                                                    child: CachedNetworkImage(
                                                                      imageUrl: p.image!,
                                                                      width: size.width * 0.5,
                                                                      height: size.height * 0.2,
                                                                      fit: BoxFit.cover,
                                                                      errorWidget: (context, url, error) {
                                                                        return const Icon(
                                                                          Icons.error,
                                                                          size: 30,
                                                                          color: appHomeTextColor,
                                                                        );
                                                                      },
                                                                      progressIndicatorBuilder: (context, url, downloadProgress) => const SpinKitCircle(color: appPrimaryColor, size: 30),
                                                                    )),
                                                                SizedBox(height: 16),
                                                                Text(
                                                                  'Choose Add‑Ons for ${p.name}',
                                                                  style: MyTextStyle.f16(
                                                                    weight: FontWeight.bold,
                                                                    blackColor,
                                                                  ),
                                                                  textAlign: TextAlign.left,
                                                                ),
                                                                SizedBox(height: 12),
                                                                Column(
                                                                  children: p.addons!.map((e) {
                                                                    return Padding(
                                                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                                      child: Container(
                                                                        padding: const EdgeInsets.all(8),
                                                                        decoration: BoxDecoration(
                                                                          border: Border.all(color: blackColor),
                                                                          borderRadius: BorderRadius.circular(8),
                                                                        ),
                                                                        child: Row(
                                                                          children: [
                                                                            Expanded(
                                                                              child: Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: [
                                                                                  Text(
                                                                                    e.name ?? '',
                                                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                                                  ),
                                                                                  const SizedBox(height: 4),
                                                                                  Text(
                                                                                    e.isFree == true ? "Free (Max: ${e.maxQuantity})" : "₹ ${e.price?.toStringAsFixed(2) ?? '0.00'} (Max: ${e.maxQuantity})",
                                                                                    style: TextStyle(color: Colors.grey.shade600),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                            Row(
                                                                              children: [
                                                                                IconButton(
                                                                                  icon: const Icon(Icons.remove),
                                                                                  onPressed: (e.quantity) > 0
                                                                                      ? () {
                                                                                    setState(() {
                                                                                      e.quantity = (e.quantity) - 1;
                                                                                    });
                                                                                  }
                                                                                      : null,
                                                                                ),
                                                                                Text('${e.quantity}'),
                                                                                IconButton(
                                                                                  icon: const Icon(Icons.add, color: Colors.brown),
                                                                                  onPressed: (e.quantity) < (e.maxQuantity ?? 1)
                                                                                      ? () {
                                                                                    setState(() {
                                                                                      e.quantity = (e.quantity) + 1;
                                                                                    });
                                                                                  }
                                                                                      : null,
                                                                                ),
                                                                              ],
                                                                            )
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    );
                                                                  }).toList(),
                                                                ),
                                                                SizedBox(height: 20),
                                                                Row(
                                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                                  children: [
                                                                    ElevatedButton(
                                                                      onPressed: () {
                                                                        setState(() {
                                                                          if (counter > 1 || counter == 1) {
                                                                            counter--;
                                                                          }
                                                                        });
                                                                        Navigator.of(context).pop();
                                                                      },
                                                                      style: ElevatedButton.styleFrom(
                                                                        backgroundColor: greyColor.shade400,
                                                                        minimumSize: Size(80, 40),
                                                                        padding: EdgeInsets.all(20),
                                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                                      ),
                                                                      child: Text('Cancel', style: MyTextStyle.f14(blackColor)),
                                                                    ),
                                                                    SizedBox(width: 8),
                                                                    ElevatedButton(
                                                                      onPressed: () {
                                                                        final currentQtyInCart = getCurrentQuantity(p.id.toString());
                                                                        bool canAdd;

                                                                        if (p.isStock == true) {
                                                                          if ((widget.isEditingOrder == true && widget.existingOrder?.data?.orderStatus == "COMPLETED") || (widget.isEditingOrder == true && widget.existingOrder?.data?.orderStatus == "WAITLIST")) {
                                                                            final paidQty = widget.existingOrder?.data?.items?.firstWhereOrNull((item) => item.product?.id == p.id)?.quantity ?? 0;
                                                                            canAdd = currentQtyInCart < ((p.availableQuantity ?? 0) + paidQty);
                                                                          } else {
                                                                            canAdd = currentQtyInCart < (p.availableQuantity ?? 0);
                                                                          }
                                                                        } else {
                                                                          canAdd = true;
                                                                        }

                                                                        if (!canAdd) {
                                                                          showToast("Cannot add more items. Stock limit reached.", context, color: false);
                                                                          return;
                                                                        }

                                                                        setState(() {
                                                                          isSplitPayment = false;
                                                                          if (widget.isEditingOrder != true) {
                                                                            if (billingItems.isEmpty) _resetToDefaultOrderType();
                                                                          }
                                                                          final index = billingItems.indexWhere((item) => item['_id'] == p.id);
                                                                          if (index != -1) {
                                                                            billingItems[index]['qty'] = billingItems[index]['qty'] + 1;
                                                                            updateControllerText(p.id.toString(), billingItems[index]['qty']);
                                                                          } else {
                                                                            billingItems.add({
                                                                              "_id": p.id,
                                                                              "basePrice": p.basePrice,
                                                                              "image": p.image,
                                                                              "qty": 1,
                                                                              "name": p.name,
                                                                              "availableQuantity": p.availableQuantity,
                                                                              "unitmasterid": p.unitmasterid,
                                                                              "selectedAddons": p.addons!
                                                                                  .where((addon) => addon.quantity > 0)
                                                                                  .map((addon) => {
                                                                                "_id": addon.id,
                                                                                "price": addon.price,
                                                                                "quantity": addon.quantity,
                                                                                "name": addon.name,
                                                                                "isAvailable": addon.isAvailable,
                                                                                "maxQuantity": addon.maxQuantity,
                                                                                "isFree": addon.isFree,
                                                                              })
                                                                                  .toList()
                                                                            });
                                                                            updateControllerText(p.id.toString(), 1);
                                                                          }
                                                                          context.read<FoodCategoryBloc>().add(AddToBilling(List.from(billingItems), isDiscountApplied, selectedOrderType));

                                                                          setState(() {
                                                                            for (var addon in p.addons!) {
                                                                              addon.isSelected = false;
                                                                              addon.quantity = 0;
                                                                            }
                                                                          });
                                                                          Navigator.of(context).pop();
                                                                        });
                                                                      },
                                                                      style: ElevatedButton.styleFrom(
                                                                        backgroundColor: appPrimaryColor,
                                                                        minimumSize: Size(80, 40),
                                                                        padding: EdgeInsets.all(20),
                                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                                      ),
                                                                      child: Text('Add to Bill', style: MyTextStyle.f14(whiteColor)),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }),
                                                  ),
                                                );
                                              },
                                            );
                                          } else {
                                            final currentQtyInCart =
                                            getCurrentQuantity(p
                                                .id
                                                .toString());
                                            bool canAdd;

                                            if (p.isStock ==
                                                true) {
                                              if ((widget.isEditingOrder ==
                                                  true &&
                                                  widget.existingOrder?.data
                                                      ?.orderStatus ==
                                                      "COMPLETED") ||
                                                  (widget.isEditingOrder ==
                                                      true &&
                                                      widget.existingOrder?.data
                                                          ?.orderStatus ==
                                                          "WAITLIST")) {
                                                final paidQty = widget
                                                    .existingOrder
                                                    ?.data
                                                    ?.items
                                                    ?.firstWhereOrNull((item) =>
                                                item.product?.id ==
                                                    p.id)
                                                    ?.quantity ??
                                                    0;
                                                canAdd = currentQtyInCart <
                                                    ((p.availableQuantity ??
                                                        0) +
                                                        paidQty);
                                              } else {
                                                canAdd =
                                                    currentQtyInCart <
                                                        (p.availableQuantity ??
                                                            0);
                                              }
                                            } else {
                                              canAdd = true;
                                            }

                                            if (!canAdd) {
                                              showToast(
                                                  "Cannot add more items. Stock limit reached.",
                                                  context,
                                                  color: false);
                                              return;
                                            }

                                            setState(() {
                                              isSplitPayment =
                                              false;
                                              if (widget.isEditingOrder != true && billingItems.isEmpty) {
                                                _resetToDefaultOrderType();
                                              }
                                              final index = billingItems
                                                  .indexWhere(
                                                      (item) =>
                                                  item[
                                                  '_id'] ==
                                                      p.id);
                                              if (index != -1) {
                                                billingItems[
                                                index][
                                                'qty'] = billingItems[
                                                index]
                                                [
                                                'qty'] +
                                                    1;
                                                updateControllerText(
                                                    p.id
                                                        .toString(),
                                                    billingItems[
                                                    index]
                                                    [
                                                    'qty']);
                                              } else {
                                                billingItems
                                                    .add({
                                                  "_id": p.id,
                                                  "basePrice": p
                                                      .basePrice,
                                                  "image":
                                                  p.image,
                                                  "qty": 1,
                                                  "name":
                                                  p.name,
                                                  "availableQuantity":
                                                  p.availableQuantity,
                                                  "unitmasterid": p.unitmasterid,
                                                  "selectedAddons": p
                                                      .addons!
                                                      .where((addon) =>
                                                  addon
                                                      .quantity >
                                                      0)
                                                      .map(
                                                          (addon) =>
                                                      {
                                                        "_id": addon.id,
                                                        "price": addon.price,
                                                        "quantity": addon.quantity,
                                                        "name": addon.name,
                                                        "isAvailable": addon.isAvailable,
                                                        "maxQuantity": addon.maxQuantity,
                                                        "isFree": addon.isFree,
                                                      })
                                                      .toList()
                                                });
                                                updateControllerText(
                                                    p.id.toString(),
                                                    1);
                                              }
                                              context
                                                  .read<
                                                  FoodCategoryBloc>()
                                                  .add(AddToBilling(
                                                  List.from(
                                                      billingItems),
                                                  isDiscountApplied,
                                                  selectedOrderType));
                                            });
                                          }
                                        });
                                      },
                                      child: Opacity(
                                        opacity:
                                        (p.availableQuantity ??
                                            0) >
                                            0 ||
                                            p.isStock ==
                                                false
                                            ? 1.0
                                            : 0.5,
                                        child: Card(
                                          color: whiteColor,
                                          shadowColor:
                                          greyColor,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius
                                                  .circular(
                                                  12)),
                                          child: Padding(
                                            padding:
                                            const EdgeInsets
                                                .all(12),
                                            child: Column(
                                              mainAxisSize:
                                              MainAxisSize
                                                  .min,
                                              children: [
                                                SizedBox(
                                                  height:
                                                  size.height *
                                                      0.12,
                                                  child:
                                                  ClipRRect(
                                                      borderRadius: BorderRadius.circular(
                                                          15.0),
                                                      child:
                                                      CachedNetworkImage(
                                                        imageUrl:
                                                        p.image ?? "",
                                                        width:
                                                        size.width * 0.2,
                                                        height:
                                                        size.height * 0.12,
                                                        fit:
                                                        BoxFit.cover,
                                                        errorWidget: (context,
                                                            url,
                                                            error) {
                                                          return const Icon(
                                                            Icons.error,
                                                            size: 30,
                                                            color: appHomeTextColor,
                                                          );
                                                        },
                                                        progressIndicatorBuilder: (context, url, downloadProgress) =>
                                                        const SpinKitCircle(color: appPrimaryColor, size: 30),
                                                      )),
                                                ),
                                                verticalSpace(
                                                    height: 5),
                                                SizedBox(
                                                  width:
                                                  size.width *
                                                      0.25,
                                                  child: Text(
                                                    p.name ??
                                                        '',
                                                    style:
                                                    MyTextStyle
                                                        .f13(
                                                      blackColor,
                                                      weight: FontWeight
                                                          .w500,
                                                    ),
                                                    maxLines: 3,
                                                    overflow:
                                                    TextOverflow
                                                        .ellipsis,
                                                    textAlign:
                                                    TextAlign
                                                        .center,
                                                  ),
                                                ),
                                                verticalSpace(
                                                    height: 5),
                                                if (p.isStock ==
                                                    true)
                                                  SizedBox(
                                                    width: size
                                                        .width *
                                                        0.25,
                                                    child:
                                                    FittedBox(
                                                      fit: BoxFit
                                                          .scaleDown,
                                                      child:
                                                      Row(
                                                        children: [
                                                          Text(
                                                            'Available: ',
                                                            style:
                                                            MyTextStyle.f12(greyColor, weight: FontWeight.w500),
                                                            maxLines:
                                                            1,
                                                            overflow:
                                                            TextOverflow.ellipsis,
                                                          ),
                                                          Text(
                                                            '${p.availableQuantity ?? 0}',
                                                            style:
                                                            MyTextStyle.f12((p.availableQuantity ?? 0) > 0 ? greyColor : redColor, weight: FontWeight.w500),
                                                            maxLines:
                                                            1,
                                                            overflow:
                                                            TextOverflow.ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                if ((p.availableQuantity ??
                                                    0) <=
                                                    0 &&
                                                    p.isStock ==
                                                        true) ...[
                                                  verticalSpace(
                                                      height:
                                                      5),
                                                  Container(
                                                    padding: EdgeInsets.symmetric(
                                                        horizontal:
                                                        8,
                                                        vertical:
                                                        4),
                                                    decoration:
                                                    BoxDecoration(
                                                      color: redColor
                                                          .withOpacity(
                                                          0.1),
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                          4),
                                                    ),
                                                    child: Text(
                                                      'Out of Stock',
                                                      style: MyTextStyle.f12(
                                                          redColor,
                                                          weight:
                                                          FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                                if (currentQuantity ==
                                                    0 &&
                                                    (p.availableQuantity ??
                                                        0) >
                                                        0 ||
                                                    (currentQuantity ==
                                                        0 &&
                                                        p.isStock ==
                                                            false))
                                                  verticalSpace(
                                                      height:
                                                      5),
                                                if (currentQuantity ==
                                                    0 &&
                                                    (p.availableQuantity ??
                                                        0) >
                                                        0 ||
                                                    (currentQuantity ==
                                                        0 &&
                                                        p.isStock ==
                                                            false))
                                                  SizedBox(
                                                    width: size
                                                        .width *
                                                        0.25,
                                                    child:
                                                    FittedBox(
                                                      fit: BoxFit
                                                          .scaleDown,
                                                      child:
                                                      Text(
                                                        '₹ ${p.basePrice}',
                                                        style: MyTextStyle.f14(
                                                            blackColor,
                                                            weight:
                                                            FontWeight.w600),
                                                        maxLines:
                                                        1,
                                                        overflow:
                                                        TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                if (currentQuantity != 0 && (p.availableQuantity ?? 0) > 0 && p.isVariant != true)
                                                  verticalSpace(
                                                      height:
                                                      10),
                                                if (currentQuantity != 0 && (p.availableQuantity ?? 0) > 0 && p.isVariant != true)
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .only(
                                                        left:
                                                        5.0,
                                                        right:
                                                        5.0),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .start,
                                                      children: [
                                                        Expanded(
                                                          child:
                                                          Text(
                                                            '₹ ${p.basePrice}',
                                                            style:
                                                            MyTextStyle.f14(blackColor, weight: FontWeight.w600),
                                                            maxLines:
                                                            1,
                                                            overflow:
                                                            TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        horizontalSpace(
                                                            width:
                                                            5),
                                                        CircleAvatar(
                                                          radius:
                                                          15,
                                                          backgroundColor:
                                                          greyColor200,
                                                          child:
                                                          IconButton(
                                                            icon: const Icon(Icons.remove,
                                                                size: 15,
                                                                color: blackColor),
                                                            onPressed:
                                                                () {
                                                              setState(() {
                                                                isSplitPayment = false;
                                                                if (widget.isEditingOrder != true) {
                                                                  if (billingItems.isEmpty) _resetToDefaultOrderType();
                                                                }
                                                                final index = billingItems.indexWhere((item) => item['_id'] == p.id);
                                                                if (index != -1 && billingItems[index]['qty'] > 1) {
                                                                  billingItems[index]['qty'] = billingItems[index]['qty'] - 1;
                                                                  updateControllerText(p.id.toString(), billingItems[index]['qty']);
                                                                } else {
                                                                  billingItems.removeWhere((item) => item['_id'] == p.id);
                                                                  quantityControllers.remove(p.id);
                                                                  if (billingItems.isEmpty || billingItems == []) {
                                                                    isDiscountApplied = false;
                                                                    widget.isEditingOrder = false;
                                                                    tableId = null;
                                                                    waiterId = null;
                                                                    selectedValue = null;
                                                                    selectedValueWaiter = null;
                                                                  }
                                                                }
                                                                context.read<FoodCategoryBloc>().add(AddToBilling(List.from(billingItems), isDiscountApplied, selectedOrderType));
                                                              });
                                                            },
                                                          ),
                                                        ),
                                                        Container(
                                                          width:
                                                          45,
                                                          height:
                                                          32,
                                                          margin: const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 12),
                                                          decoration:
                                                          BoxDecoration(
                                                            border:
                                                            Border.all(color: greyColor),
                                                            borderRadius:
                                                            BorderRadius.circular(4),
                                                          ),
                                                          child:
                                                          TextField(
                                                            controller:
                                                            currentController,
                                                            textAlign:
                                                            TextAlign.center,
                                                            keyboardType:
                                                            (p.unitmasterid != null && p.unitmasterid!.isNotEmpty) ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
                                                            style:
                                                            MyTextStyle.f16(blackColor),
                                                            decoration:
                                                            const InputDecoration(
                                                              border: InputBorder.none,
                                                              isDense: true,
                                                              contentPadding: EdgeInsets.all(8),
                                                            ),
                                                            onChanged:
                                                                (value) {
                                                              final isWeighted = p.unitmasterid != null && p.unitmasterid!.isNotEmpty;
                                                               final newQty = isWeighted ? double.tryParse(value) : int.tryParse(value);
                                                              if (newQty != null && newQty > 0) {
                                                                bool canSetQuantity;
                                                                if (p.isStock == true) {
                                                                  if ((widget.isEditingOrder == true && widget.existingOrder?.data?.orderStatus == "COMPLETED") || (widget.isEditingOrder == true && widget.existingOrder?.data?.orderStatus == "WAITLIST")) {
                                                                    final paidQty = widget.existingOrder?.data?.items?.firstWhereOrNull((item) => item.product?.id == p.id)?.quantity ?? 0;
                                                                    canSetQuantity = newQty <= ((p.availableQuantity ?? 0) + paidQty);
                                                                  } else {
                                                                    canSetQuantity = newQty <= (p.availableQuantity ?? 0);
                                                                  }
                                                                } else {
                                                                  canSetQuantity = true;
                                                                }

                                                                if (canSetQuantity) {
                                                                  setState(() {
                                                                    isSplitPayment = false;
                                                                    if (widget.isEditingOrder != true && billingItems.isEmpty) {
                                                                      _resetToDefaultOrderType();
                                                                    }

                                                                    final index = billingItems.indexWhere((item) => item['_id'] == p.id);
                                                                    if (index != -1) {
                                                                      billingItems[index]['qty'] = newQty;
                                                                    } else {
                                                                      billingItems.add({
                                                                        "_id": p.id,
                                                                        "basePrice": p.basePrice,
                                                                        "image": p.image,
                                                                        "qty": newQty,
                                                                        "name": p.name,
                                                                        "availableQuantity": p.availableQuantity,
                                                                        "unitmasterid": p.unitmasterid,
                                                                        "selectedAddons": p.addons!
                                                                            .where((addon) => addon.quantity > 0)
                                                                            .map((addon) => {
                                                                          "_id": addon.id,
                                                                          "price": addon.price,
                                                                          "quantity": addon.quantity,
                                                                          "name": addon.name,
                                                                          "isAvailable": addon.isAvailable,
                                                                          "maxQuantity": addon.maxQuantity,
                                                                          "isFree": addon.isFree,
                                                                        })
                                                                            .toList()
                                                                      });
                                                                    }
                                                                    context.read<FoodCategoryBloc>().add(AddToBilling(List.from(billingItems), isDiscountApplied, selectedOrderType));
                                                                  });
                                                                } else {
                                                                  currentController.text = getCurrentQuantity(p.id.toString()).toString();
                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                    SnackBar(content: Text("Maximum available quantity is ${p.availableQuantity ?? 0}")),
                                                                  );
                                                                }
                                                              } else if (newQty == 0 || value.isEmpty) {
                                                                setState(() {
                                                                  billingItems.removeWhere((item) => item['_id'] == p.id);
                                                                  quantityControllers.remove(p.id);
                                                                  if (billingItems.isEmpty || billingItems == []) {
                                                                    isDiscountApplied = false;
                                                                    widget.isEditingOrder = false;
                                                                    tableId = null;
                                                                    waiterId = null;
                                                                    selectedValue = null;
                                                                    selectedValueWaiter = null;
                                                                  }
                                                                  context.read<FoodCategoryBloc>().add(AddToBilling(List.from(billingItems), isDiscountApplied, selectedOrderType));
                                                                });
                                                              }
                                                            },
                                                            onTap:
                                                                () {
                                                              currentController.selection = TextSelection(
                                                                baseOffset: 0,
                                                                extentOffset: currentController.text.length,
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                        Builder(builder:
                                                            (context) {
                                                          final currentQtyInCart = getCurrentQuantity(p
                                                              .id
                                                              .toString());
                                                          bool
                                                          canAddMore;
                                                          if (p.isStock ==
                                                              true) {
                                                            if ((widget.isEditingOrder == true && widget.existingOrder?.data?.orderStatus == "COMPLETED") ||
                                                                (widget.isEditingOrder == true && widget.existingOrder?.data?.orderStatus == "WAITLIST")) {
                                                              final paidQty = widget.existingOrder?.data?.items?.firstWhereOrNull((item) => item.product?.id == p.id)?.quantity ?? 0;
                                                              canAddMore = currentQtyInCart < ((p.availableQuantity ?? 0) + paidQty);
                                                            } else {
                                                              canAddMore = (p.availableQuantity ?? 0) > 0 && currentQtyInCart < (p.availableQuantity ?? 0);
                                                            }
                                                          } else {
                                                            canAddMore =
                                                            true;
                                                          }

                                                          return CircleAvatar(
                                                            radius:
                                                            15,
                                                            backgroundColor: canAddMore
                                                                ? appPrimaryColor
                                                                : greyColor,
                                                            child:
                                                            IconButton(
                                                              icon: Icon(
                                                                Icons.add,
                                                                size: 16,
                                                                color: canAddMore ? whiteColor : blackColor,
                                                              ),
                                                              onPressed: canAddMore
                                                                  ? () {
                                                                setState(() {
                                                                  isSplitPayment = false;
                                                                  if (widget.isEditingOrder != true) {
                                                                    if (billingItems.isEmpty) _resetToDefaultOrderType();
                                                                  }
                                                                  final index = billingItems.indexWhere((item) => item['_id'] == p.id);
                                                                  if (index != -1) {
                                                                    billingItems[index]['qty'] = billingItems[index]['qty'] + 1;
                                                                    updateControllerText(p.id.toString(), billingItems[index]['qty']);
                                                                  } else {
                                                                    billingItems.add({
                                                                      "_id": p.id,
                                                                      "basePrice": p.basePrice,
                                                                      "image": p.image,
                                                                      "qty": 1,
                                                                      "name": p.name,
                                                                      "availableQuantity": p.availableQuantity,
                                                                      "selectedAddons": p.addons!
                                                                          .where((addon) => addon.quantity > 0)
                                                                          .map((addon) => {
                                                                        "_id": addon.id,
                                                                        "price": addon.price,
                                                                        "quantity": addon.quantity,
                                                                        "name": addon.name,
                                                                        "isAvailable": addon.isAvailable,
                                                                        "maxQuantity": addon.maxQuantity,
                                                                        "isFree": addon.isFree,
                                                                      })
                                                                          .toList()
                                                                    });
                                                                    updateControllerText(p.id.toString(), 1);
                                                                  }
                                                                  context.read<FoodCategoryBloc>().add(AddToBilling(List.from(billingItems), isDiscountApplied, selectedOrderType));
                                                                });
                                                              }
                                                                  : () {
                                                                if (p.isStock == true && (p.availableQuantity ?? 0) == 0) {
                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                    const SnackBar(content: Text("Out of stock")),
                                                                  );
                                                                }
                                                              },
                                                            ),
                                                          );
                                                        }),
                                                      ],
                                                    ),
                                                  ),
                                                if (currentQuantity != 0 && p.isStock == false && p.isVariant != true)
                                                  verticalSpace(
                                                      height:
                                                      10),
                                                if (currentQuantity != 0 && p.isStock == false && p.isVariant != true)
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .only(
                                                        left:
                                                        5.0,
                                                        right:
                                                        5.0),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .start,
                                                      children: [
                                                        Expanded(
                                                          child:
                                                          Text(
                                                            '₹ ${p.basePrice}',
                                                            style:
                                                            MyTextStyle.f14(blackColor, weight: FontWeight.w600),
                                                            maxLines:
                                                            1,
                                                            overflow:
                                                            TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        horizontalSpace(
                                                            width:
                                                            5),
                                                        CircleAvatar(
                                                          radius:
                                                          15,
                                                          backgroundColor:
                                                          greyColor200,
                                                          child:
                                                          IconButton(
                                                            icon: const Icon(Icons.remove,
                                                                size: 15,
                                                                color: blackColor),
                                                            onPressed:
                                                                () {
                                                              setState(() {
                                                                isSplitPayment = false;
                                                                if (widget.isEditingOrder != true) {
                                                                  if (billingItems.isEmpty) _resetToDefaultOrderType();
                                                                }
                                                                final index = billingItems.indexWhere((item) => item['_id'] == p.id);
                                                                if (index != -1 && billingItems[index]['qty'] > 1) {
                                                                  billingItems[index]['qty'] = billingItems[index]['qty'] - 1;
                                                                  updateControllerText(p.id.toString(), billingItems[index]['qty']);
                                                                } else {
                                                                  billingItems.removeWhere((item) => item['_id'] == p.id);
                                                                  quantityControllers.remove(p.id);
                                                                  if (billingItems.isEmpty || billingItems == []) {
                                                                    isDiscountApplied = false;
                                                                    widget.isEditingOrder = false;
                                                                    tableId = null;
                                                                    waiterId = null;
                                                                    selectedValue = null;
                                                                    selectedValueWaiter = null;
                                                                  }
                                                                }
                                                                context.read<FoodCategoryBloc>().add(AddToBilling(List.from(billingItems), isDiscountApplied, selectedOrderType));
                                                              });
                                                            },
                                                          ),
                                                        ),
                                                        Container(
                                                          width:
                                                          45,
                                                          height:
                                                          32,
                                                          margin: const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 12),
                                                          decoration:
                                                          BoxDecoration(
                                                            border:
                                                            Border.all(color: greyColor),
                                                            borderRadius:
                                                            BorderRadius.circular(4),
                                                          ),
                                                          child:
                                                          TextField(
                                                            controller:
                                                            currentController,
                                                            textAlign:
                                                            TextAlign.center,
                                                            keyboardType:
                                                            (p.unitmasterid != null && p.unitmasterid!.isNotEmpty) ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
                                                            style:
                                                            MyTextStyle.f16(blackColor),
                                                            decoration:
                                                            const InputDecoration(
                                                              border: InputBorder.none,
                                                              isDense: true,
                                                              contentPadding: EdgeInsets.all(8),
                                                            ),
                                                            onChanged:
                                                                (value) {
                                                              final isWeighted = p.unitmasterid != null && p.unitmasterid!.isNotEmpty;
                                                               final newQty = isWeighted ? double.tryParse(value) : int.tryParse(value);
                                                              if (newQty != null && newQty > 0) {
                                                                bool canSetQuantity;
                                                                if (p.isStock == true) {
                                                                  if ((widget.isEditingOrder == true && widget.existingOrder?.data?.orderStatus == "COMPLETED") || (widget.isEditingOrder == true && widget.existingOrder?.data?.orderStatus == "WAITLIST")) {
                                                                    final paidQty = widget.existingOrder?.data?.items?.firstWhereOrNull((item) => item.product?.id == p.id)?.quantity ?? 0;
                                                                    canSetQuantity = newQty <= ((p.availableQuantity ?? 0) + paidQty);
                                                                  } else {
                                                                    canSetQuantity = newQty <= (p.availableQuantity ?? 0);
                                                                  }
                                                                } else {
                                                                  canSetQuantity = true;
                                                                }

                                                                if (canSetQuantity) {
                                                                  setState(() {
                                                                    isSplitPayment = false;
                                                                    if (widget.isEditingOrder != true) {
                                                                    if (billingItems.isEmpty) _resetToDefaultOrderType();
                                                                    }

                                                                    final index = billingItems.indexWhere((item) => item['_id'] == p.id);
                                                                    if (index != -1) {
                                                                      billingItems[index]['qty'] = newQty;
                                                                    } else {
                                                                      billingItems.add({
                                                                        "_id": p.id,
                                                                        "basePrice": p.basePrice,
                                                                        "image": p.image,
                                                                        "qty": newQty,
                                                                        "name": p.name,
                                                                        "availableQuantity": p.availableQuantity,
                                                                        "selectedAddons": p.addons!
                                                                            .where((addon) => addon.quantity > 0)
                                                                            .map((addon) => {
                                                                          "_id": addon.id,
                                                                          "price": addon.price,
                                                                          "quantity": addon.quantity,
                                                                          "name": addon.name,
                                                                          "isAvailable": addon.isAvailable,
                                                                          "maxQuantity": addon.maxQuantity,
                                                                          "isFree": addon.isFree,
                                                                        })
                                                                            .toList()
                                                                      });
                                                                    }
                                                                    context.read<FoodCategoryBloc>().add(AddToBilling(List.from(billingItems), isDiscountApplied, selectedOrderType));
                                                                  });
                                                                } else {
                                                                  currentController.text = getCurrentQuantity(p.id.toString()).toString();
                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                    SnackBar(content: Text("Maximum available quantity is ${p.availableQuantity ?? 0}")),
                                                                  );
                                                                }
                                                              } else if (newQty == 0 || value.isEmpty) {
                                                                setState(() {
                                                                  billingItems.removeWhere((item) => item['_id'] == p.id);
                                                                  quantityControllers.remove(p.id);
                                                                  if (billingItems.isEmpty || billingItems == []) {
                                                                    isDiscountApplied = false;
                                                                    widget.isEditingOrder = false;
                                                                    tableId = null;
                                                                    waiterId = null;
                                                                    selectedValue = null;
                                                                    selectedValueWaiter = null;
                                                                  }
                                                                  context.read<FoodCategoryBloc>().add(AddToBilling(List.from(billingItems), isDiscountApplied, selectedOrderType));
                                                                });
                                                              }
                                                            },
                                                            onTap:
                                                                () {
                                                              currentController.selection = TextSelection(
                                                                baseOffset: 0,
                                                                extentOffset: currentController.text.length,
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                        Builder(builder:
                                                            (context) {
                                                          final currentQtyInCart = getCurrentQuantity(p
                                                              .id
                                                              .toString());
                                                          bool
                                                          canAddMore;
                                                          if (p.isStock ==
                                                              true) {
                                                            if ((widget.isEditingOrder == true && widget.existingOrder?.data?.orderStatus == "COMPLETED") ||
                                                                (widget.isEditingOrder == true && widget.existingOrder?.data?.orderStatus == "WAITLIST")) {
                                                              final paidQty = widget.existingOrder?.data?.items?.firstWhereOrNull((item) => item.product?.id == p.id)?.quantity ?? 0;
                                                              canAddMore = currentQtyInCart < ((p.availableQuantity ?? 0) + paidQty);
                                                            } else {
                                                              canAddMore = (p.availableQuantity ?? 0) > 0 && currentQtyInCart < (p.availableQuantity ?? 0);
                                                            }
                                                          } else {
                                                            canAddMore =
                                                            true;
                                                          }

                                                          return CircleAvatar(
                                                            radius:
                                                            15,
                                                            backgroundColor: canAddMore
                                                                ? appPrimaryColor
                                                                : greyColor,
                                                            child:
                                                            IconButton(
                                                              icon: Icon(
                                                                Icons.add,
                                                                size: 15,
                                                                color: canAddMore ? whiteColor : blackColor,
                                                              ),
                                                              onPressed: canAddMore
                                                                  ? () {
                                                                setState(() {
                                                                  isSplitPayment = false;
                                                                  if (widget.isEditingOrder != true) {
                                                                    if (billingItems.isEmpty) _resetToDefaultOrderType();
                                                                  }
                                                                  final index = billingItems.indexWhere((item) => item['_id'] == p.id);
                                                                  if (index != -1) {
                                                                    billingItems[index]['qty'] = billingItems[index]['qty'] + 1;
                                                                    updateControllerText(p.id.toString(), billingItems[index]['qty']);
                                                                  } else {
                                                                    billingItems.add({
                                                                      "_id": p.id,
                                                                      "basePrice": p.basePrice,
                                                                      "image": p.image,
                                                                      "qty": 1,
                                                                      "name": p.name,
                                                                      "availableQuantity": p.availableQuantity,
                                                                      "selectedAddons": p.addons!
                                                                          .where((addon) => addon.quantity > 0)
                                                                          .map((addon) => {
                                                                        "_id": addon.id,
                                                                        "price": addon.price,
                                                                        "quantity": addon.quantity,
                                                                        "name": addon.name,
                                                                        "isAvailable": addon.isAvailable,
                                                                        "maxQuantity": addon.maxQuantity,
                                                                        "isFree": addon.isFree,
                                                                      })
                                                                          .toList()
                                                                    });
                                                                    updateControllerText(p.id.toString(), 1);
                                                                  }
                                                                  context.read<FoodCategoryBloc>().add(AddToBilling(List.from(billingItems), isDiscountApplied, selectedOrderType));
                                                                });
                                                              }
                                                                  : () {
                                                                if (p.isStock == true && (p.availableQuantity ?? 0) == 0) {
                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                    const SnackBar(content: Text("Out of stock")),
                                                                  );
                                                                }
                                                              },
                                                            ),
                                                          );
                                                        }),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ]),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                        width: size.width * 0.32,
                        child: Container(
                            padding: EdgeInsets.only(left: 15, right: 10),
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: whiteColor,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: blackColor.withOpacity(0.1),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                                child:
                                postAddToBillingModel.items == null ||
                                    postAddToBillingModel
                                        .items!.isEmpty ||
                                    postAddToBillingModel.items ==
                                        []
                                    ? SingleChildScrollView(
                                  child: Container(
                                    margin: EdgeInsets.only(
                                        top: 30),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                      children: [
                                        Row(
                                          children: [
                                            if (isPriceTypeAvailable("basePrice")) ...[
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      selectedOrderType = OrderType.line;
                                                      selectedValue = null;
                                                      selectedValueWaiter = null;
                                                      tableId = null;
                                                      waiterId = null;
                                                      isSplitPayment = false;
                                                      context.read<FoodCategoryBloc>().add(AddToBilling(
                                                          List.from(billingItems),
                                                          isDiscountApplied,
                                                          selectedOrderType));
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                    decoration: BoxDecoration(
                                                      color: selectedOrderType == OrderType.line
                                                          ? appPrimaryColor
                                                          : whiteColor,
                                                      borderRadius: BorderRadius.circular(30),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        "Line",
                                                        style: MyTextStyle.f12(
                                                          selectedOrderType == OrderType.line
                                                              ? whiteColor
                                                              : blackColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            if (isPriceTypeAvailable("parcelPrice")) ...[
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      selectedOrderType = OrderType.parcel;
                                                      selectedValue = null;
                                                      selectedValueWaiter = null;
                                                      tableId = null;
                                                      waiterId = null;
                                                      isSplitPayment = false;
                                                      context.read<FoodCategoryBloc>().add(AddToBilling(
                                                          List.from(billingItems),
                                                          isDiscountApplied,
                                                          selectedOrderType));
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                    decoration: BoxDecoration(
                                                      color: selectedOrderType == OrderType.parcel
                                                          ? appPrimaryColor
                                                          : whiteColor,
                                                      borderRadius: BorderRadius.circular(30),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        "Parcel",
                                                        style: MyTextStyle.f12(
                                                          selectedOrderType == OrderType.parcel
                                                              ? whiteColor
                                                              : blackColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            if (isPriceTypeAvailable("acPrice")) ...[
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      selectedOrderType = OrderType.ac;
                                                      selectedValue = null;
                                                      selectedValueWaiter = null;
                                                      tableId = null;
                                                      waiterId = null;
                                                      isSplitPayment = false;
                                                      context.read<FoodCategoryBloc>().add(AddToBilling(
                                                          List.from(billingItems),
                                                          isDiscountApplied,
                                                          selectedOrderType));
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                    decoration: BoxDecoration(
                                                      color: selectedOrderType == OrderType.ac
                                                          ? appPrimaryColor
                                                          : whiteColor,
                                                      borderRadius: BorderRadius.circular(30),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        "AC",
                                                        style: MyTextStyle.f12(
                                                          selectedOrderType == OrderType.ac
                                                              ? whiteColor
                                                              : blackColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            if (isPriceTypeAvailable("hdPrice")) ...[
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      selectedOrderType = OrderType.hd;
                                                      selectedValue = null;
                                                      selectedValueWaiter = null;
                                                      tableId = null;
                                                      waiterId = null;
                                                      isSplitPayment = false;
                                                      context.read<FoodCategoryBloc>().add(AddToBilling(
                                                          List.from(billingItems),
                                                          isDiscountApplied,
                                                          selectedOrderType));
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                    decoration: BoxDecoration(
                                                      color: selectedOrderType == OrderType.hd
                                                          ? appPrimaryColor
                                                          : whiteColor,
                                                      borderRadius: BorderRadius.circular(30),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        "HD",
                                                        style: MyTextStyle.f12(
                                                          selectedOrderType == OrderType.hd
                                                              ? whiteColor
                                                              : blackColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            if (isPriceTypeAvailable("swiggyPrice")) ...[
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      selectedOrderType = OrderType.swiggy;
                                                      selectedValue = null;
                                                      selectedValueWaiter = null;
                                                      tableId = null;
                                                      waiterId = null;
                                                      isSplitPayment = false;
                                                      context.read<FoodCategoryBloc>().add(AddToBilling(
                                                          List.from(billingItems),
                                                          isDiscountApplied,
                                                          selectedOrderType));
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                    decoration: BoxDecoration(
                                                      color: selectedOrderType == OrderType.swiggy
                                                          ? appPrimaryColor
                                                          : whiteColor,
                                                      borderRadius: BorderRadius.circular(30),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        "SWIGGY",
                                                        style: MyTextStyle.f12(
                                                          selectedOrderType == OrderType.swiggy
                                                              ? whiteColor
                                                              : blackColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            const SizedBox(
                                                width: 16),
                                            Text(
                                              "Bills",
                                              style: MyTextStyle.f14(
                                                  blackColor,
                                                  weight:
                                                  FontWeight
                                                      .bold),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  billingItems
                                                      .clear();
                                                  selectedValue =
                                                  null;
                                                  selectedValueWaiter =
                                                  null;
                                                  tableId =
                                                  null;
                                                  waiterId =
                                                  null;
                                                  selectedOrderType =
                                                      OrderType
                                                          .line;
                                                  isCompleteOrder =
                                                  false;
                                                  isSplitPayment =
                                                  false;
                                                  amountController
                                                      .clear();
                                                  selectedFullPaymentMethod =
                                                  "";
                                                  widget.isEditingOrder =
                                                  false;
                                                  balance = 0;
                                                  if (billingItems
                                                      .isEmpty) {
                                                    isDiscountApplied =
                                                    false;
                                                  }
                                                });
                                                context
                                                    .read<
                                                    FoodCategoryBloc>()
                                                    .add(
                                                  AddToBilling(
                                                      List.from(
                                                          billingItems),
                                                      isDiscountApplied,
                                                      selectedOrderType),
                                                );
                                              },
                                              icon: const Icon(
                                                  Icons
                                                      .refresh),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 25),
                                        Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                            children: [
                                              Text(
                                                "No.items in bill",
                                                style: MyTextStyle.f14(
                                                    greyColor,
                                                    weight:
                                                    FontWeight
                                                        .w400),
                                              ),
                                              SizedBox(
                                                  height: 8),
                                              Text("₹ 0.00")
                                            ]),
                                        Divider(),
                                        Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                            children: [
                                              Text(
                                                "Subtotal",
                                                style: MyTextStyle.f14(
                                                    greyColor,
                                                    weight:
                                                    FontWeight
                                                        .w400),
                                              ),
                                              SizedBox(
                                                  height: 8),
                                              Text("₹ 0.00")
                                            ]),
                                        Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                            children: [
                                              Text(
                                                "Total Tax",
                                                style: MyTextStyle.f14(
                                                    greyColor,
                                                    weight:
                                                    FontWeight
                                                        .w400),
                                              ),
                                              Text("₹ 0.00"),
                                            ]),
                                        SizedBox(height: 8),
                                        Divider(),
                                        Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                            children: [
                                              Text(
                                                "Total",
                                                style: MyTextStyle.f14(
                                                    blackColor,
                                                    weight:
                                                    FontWeight
                                                        .w600),
                                              ),
                                              Text("₹ 0.00",
                                                  style: MyTextStyle.f18(
                                                      blackColor,
                                                      weight: FontWeight
                                                          .w600)),
                                            ]),
                                        SizedBox(height: 12),
                                        Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                            children: [
                                              Text(
                                                "Current Payment Amount",
                                                style: MyTextStyle.f14(
                                                    blackColor,
                                                    weight:
                                                    FontWeight
                                                        .w400),
                                              ),
                                              Text("₹ 0.00",
                                                  style: MyTextStyle.f14(
                                                      blackColor,
                                                      weight: FontWeight
                                                          .w400)),
                                            ]),
                                        SizedBox(height: 12),
                                        Container(
                                          decoration:
                                          BoxDecoration(
                                            color: greyColor200,
                                            borderRadius:
                                            BorderRadius
                                                .circular(
                                                30),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child:
                                                Container(
                                                  padding: EdgeInsets
                                                      .symmetric(
                                                      vertical:
                                                      8),
                                                  decoration:
                                                  BoxDecoration(
                                                    color:
                                                    appPrimaryColor,
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                        30),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      "Full Payment",
                                                      style: MyTextStyle
                                                          .f12(
                                                        whiteColor,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child:
                                                Container(
                                                  padding: EdgeInsets
                                                      .symmetric(
                                                      vertical:
                                                      8),
                                                  decoration:
                                                  BoxDecoration(
                                                    color:
                                                    greyColor200,
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                        30),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      "Split Payment",
                                                      style: MyTextStyle
                                                          .f12(
                                                        blackColor,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Text("Payment Method",
                                            style: MyTextStyle.f12(
                                                blackColor,
                                                weight:
                                                FontWeight
                                                    .bold)),
                                        SizedBox(height: 12),
                                        SingleChildScrollView(
                                          scrollDirection:
                                          Axis.horizontal,
                                          child: Wrap(
                                            spacing: 12,
                                            runSpacing: 12,
                                            children: [
                                              PaymentOption(
                                                  icon: Icons
                                                      .money,
                                                  label: "Cash",
                                                  selected:
                                                  false),
                                              PaymentOption(
                                                  icon: Icons
                                                      .credit_card,
                                                  label: "Card",
                                                  selected:
                                                  false),
                                              PaymentOption(
                                                  icon: Icons
                                                      .qr_code,
                                                  label: "UPI",
                                                  selected:
                                                  false),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child:
                                              ElevatedButton(
                                                onPressed: () {
                                                  setState(() {
                                                    if (billingItems ==
                                                        [] ||
                                                        billingItems
                                                            .isEmpty) {
                                                      showToast(
                                                          "No items in the bill to save or complete.",
                                                          context,
                                                          color:
                                                          false);
                                                    }
                                                  });
                                                },
                                                style: ElevatedButton
                                                    .styleFrom(
                                                  backgroundColor:
                                                  appGreyColor,
                                                  minimumSize:
                                                  const Size(
                                                      0,
                                                      50), // Height only
                                                  shape:
                                                  RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                        30),
                                                  ),
                                                ),
                                                child:
                                                const Text(
                                                  "Save Order",
                                                  style: TextStyle(
                                                      color:
                                                      blackColor),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                                width:
                                                10), // Space between buttons
                                            Expanded(
                                              child:
                                              ElevatedButton(
                                                onPressed: () {
                                                  setState(() {
                                                    if (billingItems ==
                                                        [] ||
                                                        billingItems
                                                            .isEmpty) {
                                                      showToast(
                                                          "No items in the bill to save or complete.",
                                                          context,
                                                          color:
                                                          false);
                                                    }
                                                  });
                                                },
                                                style: ElevatedButton
                                                    .styleFrom(
                                                  backgroundColor:
                                                  appGreyColor,
                                                  minimumSize:
                                                  const Size(
                                                      0,
                                                      50),
                                                  shape:
                                                  RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                        30),
                                                  ),
                                                ),
                                                child:
                                                const Text(
                                                  "Complete Order",
                                                  style: TextStyle(
                                                      color:
                                                      blackColor),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                )
                                    : Container(
                                  margin:
                                  EdgeInsets.only(top: 30),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                    children: [
                                      /* Row(
                                                        children: [
                                                          Text(
                                                            "Bills",
                                                            style: MyTextStyle.f13(
                                                                blackColor,
                                                                weight:
                                                                FontWeight
                                                                    .bold),
                                                          ),
                                                          IconButton(
                                                            onPressed: () {
                                                              setState(() {
                                                                billingItems
                                                                    .clear();
                                                                selectedValue =
                                                                null;
                                                                selectedValueWaiter =
                                                                null;
                                                                tableId = null;
                                                                waiterId = null;
                                                                selectedOrderType =
                                                                    OrderType
                                                                        .line;
                                                                isCompleteOrder =
                                                                false;
                                                                isSplitPayment =
                                                                false;
                                                                amountController
                                                                    .clear();
                                                                selectedFullPaymentMethod =
                                                                "";
                                                                widget.isEditingOrder =
                                                                false;
                                                                balance = 0;
                                                                if (billingItems
                                                                    .isEmpty) {
                                                                  isDiscountApplied =
                                                                  false;
                                                                }
                                                              });
                                                              context
                                                                  .read<
                                                                  FoodCategoryBloc>()
                                                                  .add(
                                                                AddToBilling(
                                                                    List.from(
                                                                        billingItems),
                                                                    isDiscountApplied,
                                                                    selectedOrderType),
                                                              );
                                                            },
                                                            icon: const Icon(
                                                                Icons.refresh),
                                                          ),
                                                        ],
                                                      ),*/
                                      Row(
                                        children: [
                                           if (isPriceTypeAvailable("basePrice")) ...[
                                            Expanded(
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    selectedOrderType =
                                                        OrderType
                                                            .line;
                                                    if (widget
                                                        .isEditingOrder !=
                                                        true) {
                                                      selectedValue =
                                                      null;
                                                      selectedValueWaiter =
                                                      null;
                                                      tableId =
                                                      null;
                                                      waiterId =
                                                      null;
                                                    }
                                                    isSplitPayment =
                                                    false;
                                                    context.read<FoodCategoryBloc>().add(AddToBilling(
                                                        List.from(
                                                            billingItems),
                                                        isDiscountApplied,
                                                        selectedOrderType));
                                                  });
                                                },
                                                child: Container(
                                                  padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                      vertical:
                                                      8),
                                                  constraints:
                                                  const BoxConstraints(
                                                      minWidth:
                                                      70),
                                                  decoration:
                                                  BoxDecoration(
                                                    color: selectedOrderType ==
                                                        OrderType
                                                            .line
                                                        ? appPrimaryColor
                                                        : whiteColor,
                                                    borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                        30),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      "Line",
                                                      style:
                                                      MyTextStyle
                                                          .f12(
                                                        selectedOrderType ==
                                                            OrderType.line
                                                            ? whiteColor
                                                            : blackColor,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                             const SizedBox(width: 8),
                                           ],
                                           if (isPriceTypeAvailable("parcelPrice")) ...[
                                            Expanded(
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    selectedOrderType =
                                                        OrderType
                                                            .parcel;
                                                    if (widget
                                                        .isEditingOrder !=
                                                        true) {
                                                      selectedValue =
                                                      null;
                                                      selectedValueWaiter =
                                                      null;
                                                      tableId =
                                                      null;
                                                      waiterId =
                                                      null;
                                                    }
                                                    isSplitPayment =
                                                    false;
                                                    context.read<FoodCategoryBloc>().add(AddToBilling(
                                                        List.from(
                                                            billingItems),
                                                        isDiscountApplied,
                                                        selectedOrderType));
                                                  });
                                                },
                                                child: Container(
                                                  alignment:
                                                  Alignment
                                                      .center,
                                                  padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                    vertical: 8,
                                                  ),
                                                  constraints:
                                                  const BoxConstraints(
                                                      minWidth:
                                                      70),
                                                  decoration:
                                                  BoxDecoration(
                                                    color: selectedOrderType ==
                                                        OrderType
                                                            .parcel
                                                        ? appPrimaryColor
                                                        : whiteColor,
                                                    borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                        30),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      "Parcel",
                                                      style: MyTextStyle.f12(
                                                        selectedOrderType == OrderType.parcel
                                                            ? whiteColor
                                                            : blackColor,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          if (isPriceTypeAvailable("acPrice")) ...[
                                            Expanded(
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    selectedOrderType = OrderType.ac;
                                                    if (widget.isEditingOrder != true) {
                                                      selectedValue = null;
                                                      selectedValueWaiter = null;
                                                      tableId = null;
                                                      waiterId = null;
                                                    }
                                                    isSplitPayment = false;
                                                    context.read<FoodCategoryBloc>().add(AddToBilling(
                                                        List.from(billingItems),
                                                        isDiscountApplied,
                                                        selectedOrderType));
                                                  });
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: selectedOrderType == OrderType.ac
                                                        ? appPrimaryColor
                                                        : whiteColor,
                                                    borderRadius: BorderRadius.circular(30),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      "AC",
                                                      style: MyTextStyle.f12(
                                                        selectedOrderType == OrderType.ac
                                                            ? whiteColor
                                                            : blackColor,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          if (isPriceTypeAvailable("hdPrice")) ...[
                                            Expanded(
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    selectedOrderType = OrderType.hd;
                                                    if (widget.isEditingOrder != true) {
                                                      selectedValue = null;
                                                      selectedValueWaiter = null;
                                                      tableId = null;
                                                      waiterId = null;
                                                    }
                                                    isSplitPayment = false;
                                                    context.read<FoodCategoryBloc>().add(AddToBilling(
                                                        List.from(billingItems),
                                                        isDiscountApplied,
                                                        selectedOrderType));
                                                  });
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: selectedOrderType == OrderType.hd
                                                        ? appPrimaryColor
                                                        : whiteColor,
                                                    borderRadius: BorderRadius.circular(30),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      "HD",
                                                      style: MyTextStyle.f12(
                                                        selectedOrderType == OrderType.hd
                                                            ? whiteColor
                                                            : blackColor,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          if (isPriceTypeAvailable("swiggyPrice")) ...[
                                            Expanded(
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    selectedOrderType = OrderType.swiggy;
                                                    if (widget.isEditingOrder != true) {
                                                      selectedValue = null;
                                                      selectedValueWaiter = null;
                                                      tableId = null;
                                                      waiterId = null;
                                                    }
                                                    isSplitPayment = false;
                                                    context.read<FoodCategoryBloc>().add(AddToBilling(
                                                        List.from(billingItems),
                                                        isDiscountApplied,
                                                        selectedOrderType));
                                                  });
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: selectedOrderType == OrderType.swiggy
                                                        ? appPrimaryColor
                                                        : whiteColor,
                                                    borderRadius: BorderRadius.circular(30),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      "SWIGGY",
                                                      style: MyTextStyle.f12(
                                                        selectedOrderType == OrderType.swiggy
                                                            ? whiteColor
                                                            : blackColor,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Text(
                                            "Bills",
                                            style: MyTextStyle.f13(
                                                blackColor,
                                                weight:
                                                FontWeight
                                                    .bold),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              setState(() {
                                                billingItems
                                                    .clear();
                                                selectedValue =
                                                null;
                                                selectedValueWaiter =
                                                null;
                                                tableId = null;
                                                waiterId = null;
                                                 _resetToDefaultOrderType();


                                                isCompleteOrder =
                                                false;
                                                isSplitPayment =
                                                false;
                                                amountController
                                                    .clear();
                                                selectedFullPaymentMethod =
                                                "";
                                                widget.isEditingOrder =
                                                false;
                                                balance = 0;
                                                if (billingItems
                                                    .isEmpty) {
                                                  isDiscountApplied =
                                                  false;
                                                }
                                              });
                                              context
                                                  .read<
                                                  FoodCategoryBloc>()
                                                  .add(
                                                AddToBilling(
                                                    List.from(
                                                        billingItems),
                                                    isDiscountApplied,
                                                    selectedOrderType),
                                              );
                                            },
                                            icon: const Icon(
                                                Icons.refresh),
                                          ),
                                        ],
                                      ),
                                      /* SizedBox(height: 10),
                                                      if (selectedOrderType ==
                                                              OrderType.line ||
                                                          selectedOrderType ==
                                                              OrderType.ac)
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        10.0),
                                                                child: Text(
                                                                  'Select Table',
                                                                  style:
                                                                      MyTextStyle
                                                                          .f14(
                                                                    blackColor,
                                                                    weight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        10.0),
                                                                child: Text(
                                                                  'Select Waiter',
                                                                  style:
                                                                      MyTextStyle
                                                                          .f14(
                                                                    blackColor,
                                                                    weight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      if (selectedOrderType ==
                                                              OrderType.line ||
                                                          selectedOrderType ==
                                                              OrderType.ac)
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: Container(
                                                                margin:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        10),
                                                                child:
                                                                    DropdownButtonFormField<
                                                                        String>(
                                                                  value: (getTableModel.data?.any((item) =>
                                                                              item.name ==
                                                                              selectedValue) ??
                                                                          false)
                                                                      ? selectedValue
                                                                      : null,
                                                                  icon:
                                                                      const Icon(
                                                                    Icons
                                                                        .arrow_drop_down,
                                                                    color:
                                                                        appPrimaryColor,
                                                                  ),
                                                                  isExpanded:
                                                                      true,
                                                                  decoration:
                                                                      InputDecoration(
                                                                    border:
                                                                        OutlineInputBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              8),
                                                                      borderSide:
                                                                          const BorderSide(
                                                                        color:
                                                                            appPrimaryColor,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  items: getTableModel
                                                                      .data
                                                                      ?.map(
                                                                          (item) {
                                                                    return DropdownMenuItem<
                                                                        String>(
                                                                      value: item
                                                                          .name,
                                                                      child:
                                                                          Text(
                                                                        "Table ${item.name}",
                                                                        style: MyTextStyle
                                                                            .f14(
                                                                          blackColor,
                                                                          weight:
                                                                              FontWeight.normal,
                                                                        ),
                                                                      ),
                                                                    );
                                                                  }).toList(),
                                                                  onChanged:
                                                                      (String?
                                                                          newValue) {
                                                                    if (newValue !=
                                                                        null) {
                                                                      setState(
                                                                          () {
                                                                        selectedValue =
                                                                            newValue;
                                                                        final selectedItem = getTableModel.data?.firstWhere((item) =>
                                                                            item.name ==
                                                                            newValue);
                                                                        tableId = selectedItem
                                                                            ?.id
                                                                            .toString();
                                                                      });
                                                                    }
                                                                  },
                                                                  hint: Text(
                                                                    '-- Select Table --',
                                                                    style:
                                                                        MyTextStyle
                                                                            .f14(
                                                                      blackColor,
                                                                      weight: FontWeight
                                                                          .normal,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: Container(
                                                                margin:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        10),
                                                                child:
                                                                    DropdownButtonFormField<
                                                                        String>(
                                                                  value: (getWaiterModel.data?.any((item) =>
                                                                              item.name ==
                                                                              selectedValueWaiter) ??
                                                                          false)
                                                                      ? selectedValueWaiter
                                                                      : null,
                                                                  icon:
                                                                      const Icon(
                                                                    Icons
                                                                        .arrow_drop_down,
                                                                    color:
                                                                        appPrimaryColor,
                                                                  ),
                                                                  isExpanded:
                                                                      true,
                                                                  decoration:
                                                                      InputDecoration(
                                                                    border:
                                                                        OutlineInputBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              8),
                                                                      borderSide:
                                                                          const BorderSide(
                                                                        color:
                                                                            appPrimaryColor,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  items: getWaiterModel
                                                                      .data
                                                                      ?.map(
                                                                          (item) {
                                                                    return DropdownMenuItem<
                                                                        String>(
                                                                      value: item
                                                                          .name,
                                                                      child:
                                                                          Text(
                                                                        "${item.name}",
                                                                        style: MyTextStyle
                                                                            .f14(
                                                                          blackColor,
                                                                          weight:
                                                                              FontWeight.normal,
                                                                        ),
                                                                      ),
                                                                    );
                                                                  }).toList(),
                                                                  onChanged:
                                                                      (String?
                                                                          newValue) {
                                                                    if (newValue !=
                                                                        null) {
                                                                      setState(
                                                                          () {
                                                                        selectedValueWaiter =
                                                                            newValue;
                                                                        final selectedItem = getWaiterModel.data?.firstWhere((item) =>
                                                                            item.name ==
                                                                            newValue);
                                                                        waiterId = selectedItem
                                                                            ?.id
                                                                            .toString();
                                                                        debugPrint(
                                                                            "waitername:$selectedValueWaiter");
                                                                        debugPrint(
                                                                            "waiterId:$waiterId");
                                                                      });
                                                                    }
                                                                  },
                                                                  hint: Text(
                                                                    '-- Select Waiter --',
                                                                    style:
                                                                        MyTextStyle
                                                                            .f14(
                                                                      blackColor,
                                                                      weight: FontWeight
                                                                          .normal,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),*/
                                      Divider(),
                                      Column(
                                        children:
                                        postAddToBillingModel
                                            .items!
                                            .map((e) {
                                          final localItem = billingItems.firstWhereOrNull((bi) => bi['_id'] == e.id && bi['variantId'] == e.variantId);
                                          final unitmasterId = localItem?['unitmasterid'] ?? e.unitmasterid;
                                          final isWeighted = unitmasterId != null && unitmasterId.toString().isNotEmpty;
                                          final paidQty = widget
                                              .existingOrder
                                              ?.data
                                              ?.items
                                              ?.firstWhereOrNull(
                                                  (item) =>
                                              item.product
                                                  ?.id ==
                                                  e.id)
                                              ?.quantity ??
                                              0;

                                          final currentQty =
                                              billingItems
                                                  .firstWhere(
                                                    (item) =>
                                                item[
                                                '_id'] ==
                                                    e.id,
                                                orElse: () =>
                                                <String,
                                                    dynamic>{
                                                  'qty': 0
                                                },
                                              )['qty'] ??
                                                  0;

                                          final availableQty =
                                              e.availableQuantity ??
                                                  0;

                                          bool canAddMore;

                                          if (e.isStock ==
                                              true) {
                                            if ((widget.isEditingOrder ==
                                                true &&
                                                widget
                                                    .existingOrder
                                                    ?.data
                                                    ?.orderStatus ==
                                                    "COMPLETED") ||
                                                (widget.isEditingOrder ==
                                                    true &&
                                                    widget
                                                        .existingOrder
                                                        ?.data
                                                        ?.orderStatus ==
                                                        "WAITLIST")) {
                                              canAddMore = currentQty <
                                                  (availableQty +
                                                      paidQty);
                                            } else {
                                              canAddMore =
                                                  currentQty <
                                                      availableQty;
                                            }
                                          } else {
                                            canAddMore = true;
                                          }

                                          return Padding(
                                            padding:
                                            const EdgeInsets
                                                .symmetric(
                                                vertical:
                                                8.0),
                                            child: Row(
                                              crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                      10.0),
                                                  child:
                                                  CachedNetworkImage(
                                                    imageUrl:
                                                    e.image ??
                                                        "",
                                                    width: size
                                                        .width *
                                                        0.04,
                                                    height: size
                                                        .height *
                                                        0.05,
                                                    fit: BoxFit
                                                        .cover,
                                                    errorWidget:
                                                        (context,
                                                        url,
                                                        error) {
                                                      return const Icon(
                                                        Icons
                                                            .error,
                                                        size:
                                                        30,
                                                        color:
                                                        appHomeTextColor,
                                                      );
                                                    },
                                                    progressIndicatorBuilder: (context,
                                                        url,
                                                        downloadProgress) =>
                                                    const SpinKitCircle(
                                                        color:
                                                        appPrimaryColor,
                                                        size:
                                                        30),
                                                  ),
                                                ),
                                                SizedBox(
                                                    width: 5),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child:
                                                            Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text("${e.name}", style: MyTextStyle.f12(blackColor, weight: FontWeight.bold)),
                                                                Text("x ${e.qty}", style: MyTextStyle.f12(blackColor, weight: FontWeight.bold)),
                                                                e.isStock == true
                                                                    ? Text(
                                                                  (widget.isEditingOrder == true && widget.existingOrder?.data?.orderStatus == "COMPLETED") ? "Available: $availableQty (+ $paidQty paid)" : "Available: $availableQty",
                                                                  style: MyTextStyle.f10(
                                                                    availableQty > 0 ? greyColor : redColor,
                                                                    weight: FontWeight.w400,
                                                                  ),
                                                                )
                                                                    : const SizedBox.shrink(),
                                                              ],
                                                            ),
                                                          ),
                                                          Row(
                                                            mainAxisSize:
                                                            MainAxisSize.min,
                                                            children: [
                                                              // Decrease button
                                                              CircleAvatar(
                                                                radius: 15,
                                                                backgroundColor: greyColor200,
                                                                child: IconButton(
                                                                  icon: const Icon(Icons.remove, size: 15, color: blackColor),
                                                                  padding: EdgeInsets.zero,
                                                                  constraints: BoxConstraints(),
                                                                  onPressed: () {
                                                                    setState(() {
                                                                      isSplitPayment = false;
                                                                      if (widget.isEditingOrder != true) {
                                                                        selectedOrderType = OrderType.line;
                                                                      }
                                                                      final index = billingItems.indexWhere((item) => item['_id'] == e.id && item['variantId'] == e.variantId);
                                                                      if (index != -1 && billingItems[index]['qty'] > 1) {
                                                                        billingItems[index]['qty'] = billingItems[index]['qty'] - 1;
                                                                        updateControllerText(getCartItemKey(e.id.toString(), e.variantId), billingItems[index]['qty']);
                                                                      } else {
                                                                        billingItems.removeWhere((item) => item['_id'] == e.id && item['variantId'] == e.variantId);
                                                                        quantityControllers.remove(getCartItemKey(e.id.toString(), e.variantId));
                                                                        if (billingItems.isEmpty || billingItems == []) {
                                                                          isDiscountApplied = false;
                                                                          widget.isEditingOrder = false;
                                                                          tableId = null;
                                                                          waiterId = null;
                                                                          selectedValue = null;
                                                                          selectedValueWaiter = null;
                                                                        }
                                                                      }
                                                                      context.read<FoodCategoryBloc>().add(AddToBilling(List.from(billingItems), isDiscountApplied, selectedOrderType));
                                                                    });
                                                                  },
                                                                ),
                                                              ),

                                                              // TextField for quantity input
                                                              Container(
                                                                width: 60,
                                                                height: 32,
                                                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                                                decoration: BoxDecoration(
                                                                  border: Border.all(color: greyColor),
                                                                  borderRadius: BorderRadius.circular(4),
                                                                ),
                                                                child: TextField(
                                                                  controller: getOrCreateController(getCartItemKey(e.id.toString(), e.variantId), e.qty ?? 0),
                                                                  textAlign: TextAlign.center,
                                                                  keyboardType: isWeighted ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
                                                                  style: MyTextStyle.f16(blackColor),
                                                                  decoration: const InputDecoration(
                                                                    border: InputBorder.none,
                                                                    isDense: true,
                                                                    contentPadding: EdgeInsets.all(8),
                                                                  ),
                                                                  onChanged: (value) {
                                                                     final newQty = isWeighted ? double.tryParse(value) : int.tryParse(value);
                                                                    if (newQty != null && newQty > 0) {
                                                                      bool canSetQuantity;
                                                                      if (e.isStock == true) {
                                                                        if ((widget.isEditingOrder == true && widget.existingOrder?.data?.orderStatus == "COMPLETED") || (widget.isEditingOrder == true && widget.existingOrder?.data?.orderStatus == "WAITLIST")) {
                                                                          final paidQty = widget.existingOrder?.data?.items?.firstWhereOrNull((item) => item.product?.id == e.id && item.variant == e.variantId)?.quantity ?? 0;
                                                                          canSetQuantity = newQty <= ((availableQty) + paidQty);
                                                                        } else {
                                                                          canSetQuantity = newQty <= availableQty;
                                                                        }
                                                                      } else {
                                                                        canSetQuantity = true;
                                                                      }

                                                                      if (canSetQuantity) {
                                                                        setState(() {
                                                                          isSplitPayment = false;
                                                                          if (widget.isEditingOrder != true) {
                                                                            selectedOrderType = OrderType.line;
                                                                          }

                                                                          final index = billingItems.indexWhere((item) => item['_id'] == e.id && item['variantId'] == e.variantId);
                                                                          if (index != -1) {
                                                                            billingItems[index]['qty'] = newQty;
                                                                          } else {
                                                                            // This shouldn't happen in cart, but keeping for safety
                                                                            billingItems.add({
                                                                              "_id": e.id,
                                                                              "basePrice": e.basePrice,
                                                                              "image": e.image,
                                                                              "qty": newQty,
                                                                              "name": e.name,
                                                                              "availableQuantity": e.availableQuantity,
                                                                              "unitmasterid": unitmasterId,
                                                                              "selectedAddons": (e.selectedAddons != null)
                                                                                  ? e.selectedAddons!
                                                                                  .where((addon) => (addon.quantity ?? 0) > 0)
                                                                                  .map((addon) => {
                                                                                "_id": addon.id,
                                                                                "price": addon.price ?? 0,
                                                                                "quantity": addon.quantity ?? 0,
                                                                                "name": addon.name,
                                                                                "isAvailable": addon.isAvailable,
                                                                                "maxQuantity": addon.quantity,
                                                                                "isFree": addon.isFree,
                                                                              })
                                                                                  .toList()
                                                                                  : []
                                                                            });
                                                                          }
                                                                          context.read<FoodCategoryBloc>().add(AddToBilling(List.from(billingItems), isDiscountApplied, selectedOrderType));
                                                                        });
                                                                      } else {
                                                                        getOrCreateController(getCartItemKey(e.id.toString(), e.variantId), e.qty ?? 0).text = getCurrentQuantity(e.id.toString(), variantId: e.variantId).toString();
                                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                                          SnackBar(content: Text("Maximum available quantity is ${availableQty}")),
                                                                        );
                                                                      }
                                                                    } else if (newQty == 0 || value.isEmpty) {
                                                                      setState(() {
                                                                        billingItems.removeWhere((item) => item['_id'] == e.id && item['variantId'] == e.variantId);
                                                                        quantityControllers.remove(getCartItemKey(e.id.toString(), e.variantId));
                                                                        if (billingItems.isEmpty || billingItems == []) {
                                                                          isDiscountApplied = false;
                                                                          widget.isEditingOrder = false;
                                                                          tableId = null;
                                                                          waiterId = null;
                                                                          selectedValue = null;
                                                                          selectedValueWaiter = null;
                                                                        }
                                                                        context.read<FoodCategoryBloc>().add(AddToBilling(List.from(billingItems), isDiscountApplied, selectedOrderType));
                                                                      });
                                                                    }
                                                                  },
                                                                  onTap: () {
                                                                    final controller = getOrCreateController(getCartItemKey(e.id.toString(), e.variantId), e.qty ?? 0);
                                                                    controller.selection = TextSelection(
                                                                      baseOffset: 0,
                                                                      extentOffset: controller.text.length,
                                                                    );
                                                                  },
                                                                ),
                                                              ),

                                                              // Increase button
                                                              Builder(builder: (context) {
                                                                return CircleAvatar(
                                                                  radius: 15,
                                                                  backgroundColor: canAddMore ? appPrimaryColor : greyColor,
                                                                  child: IconButton(
                                                                    icon: Icon(
                                                                      Icons.add,
                                                                      size: 15,
                                                                      color: canAddMore ? whiteColor : blackColor,
                                                                    ),
                                                                    padding: EdgeInsets.zero,
                                                                    constraints: BoxConstraints(),
                                                                    onPressed: canAddMore
                                                                        ? () {
                                                                      setState(() {
                                                                        final index = billingItems.indexWhere((item) => item['_id'] == e.id && item['variantId'] == e.variantId);
                                                                        if (index != -1) {
                                                                          billingItems[index]['qty'] = billingItems[index]['qty'] + 1;
                                                                          updateControllerText(getCartItemKey(e.id.toString(), e.variantId), billingItems[index]['qty']);
                                                                        }
                                                                        context.read<FoodCategoryBloc>().add(AddToBilling(List.from(billingItems), isDiscountApplied, selectedOrderType));
                                                                      });
                                                                    }
                                                                        : () {
                                                                      if (e.isStock == true && availableQty == 0) {
                                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                                          const SnackBar(content: Text("Out of stock")),
                                                                        );
                                                                      }
                                                                    },
                                                                  ),
                                                                );
                                                              }),

                                                              // Keep your existing delete button
                                                              IconButton(
                                                                icon: Icon(Icons.delete, color: redColor, size: 20),
                                                                padding: EdgeInsets.all(4),
                                                                constraints: BoxConstraints(),
                                                                onPressed: () {
                                                                  setState(() {
                                                                    billingItems.removeWhere((item) => item['_id'] == e.id && item['variantId'] == e.variantId);
                                                                    quantityControllers.remove(getCartItemKey(e.id.toString(), e.variantId));
                                                                    if (billingItems.isEmpty || billingItems == []) {
                                                                      isDiscountApplied = false;
                                                                      widget.isEditingOrder = false;
                                                                      tableId = null;
                                                                      waiterId = null;
                                                                      selectedValue = null;
                                                                      selectedValueWaiter = null;
                                                                    }
                                                                    context.read<FoodCategoryBloc>().add(AddToBilling(List.from(billingItems), isDiscountApplied, selectedOrderType));
                                                                  });
                                                                },
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                      if (!canAddMore) ...[
                                                        Container(
                                                          margin:
                                                          EdgeInsets.only(top: 4),
                                                          padding: EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4),
                                                          decoration:
                                                          BoxDecoration(
                                                            color:
                                                            Colors.orange.withOpacity(0.1),
                                                            borderRadius:
                                                            BorderRadius.circular(4),
                                                          ),
                                                          child: (widget.isEditingOrder == true && widget.existingOrder?.data?.orderStatus == "WAITLIST")
                                                              ? Text(
                                                            'Maximum stock limit reached',
                                                            style: MyTextStyle.f10(orangeColor, weight: FontWeight.bold),
                                                          )
                                                              : Text(
                                                            ((widget.isEditingOrder == true && widget.existingOrder?.data?.orderStatus == "COMPLETED")) ? 'Maximum limit reached (Available: $availableQty + Paid: $paidQty)' : 'Maximum stock limit reached',
                                                            style: MyTextStyle.f10(orangeColor, weight: FontWeight.bold),
                                                          ),
                                                        ),
                                                      ],
                                                      Column(
                                                        crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                        children: [
                                                          if (e.selectedAddons != null &&
                                                              e.selectedAddons!.isNotEmpty)
                                                            ...e.selectedAddons!.where((addon) => addon.quantity != null && addon.quantity! > 0).map((addon) {
                                                              return Padding(
                                                                padding: const EdgeInsets.symmetric(vertical: 3),
                                                                child: Row(
                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                  children: [
                                                                    Expanded(
                                                                      child: Text(
                                                                        "${addon.name} ${addon.isFree == true ? ' (Free)' : ' ₹${addon.price}'}",
                                                                        style: TextStyle(fontSize: 12, color: greyColor),
                                                                      ),
                                                                    ),
                                                                    Row(
                                                                      children: [
                                                                        IconButton(
                                                                          icon: Icon(Icons.remove_circle_outline),
                                                                          onPressed: () {
                                                                            final currentItem = billingItems.firstWhere((item) => item['_id'] == e.id && item['variantId'] == e.variantId);
                                                                            final addonsList = currentItem['selectedAddons'] as List;
                                                                            final addonIndex = addonsList.indexWhere((a) => a['_id'] == addon.id);

                                                                            if (addonsList[addonIndex]['quantity'] > 1) {
                                                                              setState(() {
                                                                                addonsList[addonIndex]['quantity'] = addonsList[addonIndex]['quantity'] - 1;
                                                                                if (billingItems.isEmpty || billingItems == []) {
                                                                                  isDiscountApplied = false;
                                                                                  widget.isEditingOrder = false;
                                                                                  tableId = null;
                                                                                  waiterId = null;
                                                                                  selectedValue = null;
                                                                                  selectedValueWaiter = null;
                                                                                }
                                                                                context.read<FoodCategoryBloc>().add(AddToBilling(List.from(billingItems), isDiscountApplied, selectedOrderType));
                                                                              });
                                                                            } else {
                                                                              setState(() {
                                                                                addonsList.removeAt(addonIndex);
                                                                                if (billingItems.isEmpty || billingItems == []) {
                                                                                  isDiscountApplied = false;
                                                                                  widget.isEditingOrder = false;
                                                                                  tableId = null;
                                                                                  waiterId = null;
                                                                                  selectedValue = null;
                                                                                  selectedValueWaiter = null;
                                                                                }
                                                                                context.read<FoodCategoryBloc>().add(AddToBilling(List.from(billingItems), isDiscountApplied, selectedOrderType));
                                                                              });
                                                                            }
                                                                          },
                                                                        ),
                                                                        Text('${addon.quantity}', style: TextStyle(fontSize: 14)),
                                                                        IconButton(
                                                                          icon: Icon(Icons.add_circle_outline),
                                                                          onPressed: () {
                                                                            final currentItem = billingItems.firstWhere((item) => item['_id'] == e.id && item['variantId'] == e.variantId);
                                                                            final addonsList = currentItem['selectedAddons'] as List;
                                                                            final addonIndex = addonsList.indexWhere((a) => a['_id'] == addon.id);

                                                                            setState(() {
                                                                              addonsList[addonIndex]['quantity'] = addonsList[addonIndex]['quantity'] + 1;
                                                                              context.read<FoodCategoryBloc>().add(AddToBilling(List.from(billingItems), isDiscountApplied, selectedOrderType));
                                                                            });
                                                                          },
                                                                        ),
                                                                      ],
                                                                    )
                                                                  ],
                                                                ),
                                                              );
                                                            }),
                                                          price(
                                                              "Base Price",
                                                              isBold: true,
                                                              "₹ ${(e.basePrice! * e.qty!).toStringAsFixed(2)}"),
                                                          if (e.addonTotal !=
                                                              0)
                                                            price(
                                                                'Addons Total',
                                                                isBold: true,
                                                                "₹ ${e.addonTotal!.toStringAsFixed(2)}"),
                                                          price(
                                                              "Item Total",
                                                              "₹ ${(e.basePrice! * e.qty! + (e.addonTotal ?? 0)).toStringAsFixed(2)}",
                                                              isBold: true),
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                      Divider(
                                          color: greyColor200,
                                          thickness: 2),
                                      Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment
                                              .spaceBetween,
                                          children: [
                                            Text("Subtotal",
                                                style: MyTextStyle.f12(
                                                    greyColor,
                                                    weight: FontWeight
                                                        .bold)),
                                            SizedBox(height: 8),
                                            Text(
                                                "₹ ${postAddToBillingModel.subtotal}",
                                                style: MyTextStyle.f12(
                                                    greyColor,
                                                    weight:
                                                    FontWeight
                                                        .bold))
                                          ]),
                                      Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment
                                              .spaceBetween,
                                          children: [
                                            Text("Total Tax",
                                                style: MyTextStyle
                                                    .f12(
                                                    greyColor)),
                                            Text(
                                                "₹ ${postAddToBillingModel.totalTax}"),
                                          ]),
                                      SizedBox(height: 8),
                                      const Divider(
                                          thickness: 1),
                                      Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment
                                              .spaceBetween,
                                          children: [
                                            Text("Total",
                                                style: MyTextStyle.f18(
                                                    blackColor,
                                                    weight: FontWeight
                                                        .bold)),
                                            Text(
                                                "₹ ${postAddToBillingModel.total!.toStringAsFixed(2)}",
                                                style: MyTextStyle.f18(
                                                    blackColor,
                                                    weight: FontWeight
                                                        .bold)),
                                          ]),
                                      const Divider(
                                          thickness: 1),
                                      SizedBox(height: 12),
                                      Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment
                                              .spaceBetween,
                                          children: [
                                            Text(
                                                "Current Payment Amount",
                                                style: MyTextStyle.f14(
                                                    blackColor,
                                                    weight: FontWeight
                                                        .w400)),
                                            Text(
                                                "₹ ${postAddToBillingModel.total!.toStringAsFixed(2)}",
                                                style: MyTextStyle.f14(
                                                    blackColor,
                                                    weight: FontWeight
                                                        .w400)),
                                          ]),
                                      if (isCompleteOrder ==
                                          false)
                                        SizedBox(height: 12),
                                      if (isCompleteOrder ==
                                          false &&
                                          (widget.isEditingOrder ==
                                              null ||
                                              widget.isEditingOrder ==
                                                  false))
                                        Text(
                                          "Save order to waitlist or complete with payment.",
                                          style: MyTextStyle.f14(
                                              greyColor,
                                              weight: FontWeight
                                                  .w400),
                                        ),
                                      if (widget.isEditingOrder ==
                                          true &&
                                          widget
                                              .existingOrder
                                              ?.data
                                              ?.orderStatus ==
                                              "COMPLETED") ...[
                                        if (balance > 0) ...[
                                          Text(
                                            "Additional payment of ₹${balance.toStringAsFixed(2)} required.",
                                            style: MyTextStyle.f14(
                                                redColor,
                                                weight:
                                                FontWeight
                                                    .bold),
                                          )
                                        ] else if (balance <
                                            0) ...[
                                          Text(
                                            "₹${(balance * -1).toStringAsFixed(2)} will be refunded or adjusted.",
                                            style: MyTextStyle.f14(
                                                Colors.green,
                                                weight:
                                                FontWeight
                                                    .bold),
                                          )
                                        ] else ...[
                                          Text(
                                            "Order already paid. No additional payment required unless items are added",
                                            style: MyTextStyle.f14(
                                                greyColor,
                                                weight:
                                                FontWeight
                                                    .w400),
                                          )
                                        ]
                                      ],
                                      if ((isCompleteOrder == true &&
                                          postAddToBillingModel
                                              .total !=
                                              widget
                                                  .existingOrder
                                                  ?.data!
                                                  .total &&
                                          widget.isEditingOrder ==
                                              true &&
                                          widget
                                              .existingOrder
                                              ?.data!
                                              .orderStatus ==
                                              "COMPLETED") ||
                                          ((widget.isEditingOrder ==
                                              false ||
                                              widget.isEditingOrder ==
                                                  null) &&
                                              isCompleteOrder ==
                                                  true) ||
                                          (isCompleteOrder ==
                                              true &&
                                              widget.isEditingOrder ==
                                                  true &&
                                              widget
                                                  .existingOrder
                                                  ?.data!
                                                  .orderStatus ==
                                                  "WAITLIST"))
                                        activePaymentOption == PaymentOptionType.all
                                            ? Container(
                                                margin: const EdgeInsets.only(top: 15),
                                                decoration: BoxDecoration(
                                                  color: greyColor200,
                                                  borderRadius: BorderRadius.circular(30),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          setState(() {
                                                            splitChange = false;
                                                            isSplitPayment = false;
                                                          });
                                                        },
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                                          decoration: BoxDecoration(
                                                            color: isSplitPayment
                                                                ? greyColor200
                                                                : appPrimaryColor,
                                                            borderRadius: BorderRadius.circular(30),
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              "Full Payment",
                                                              style: MyTextStyle.f12(
                                                                isSplitPayment
                                                                    ? blackColor
                                                                    : whiteColor,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          setState(() {
                                                            isSplitPayment = true;
                                                            selectedFullPaymentMethod = "";
                                                            _paymentFieldCount = 1;
                                                            splitAmountControllers = [
                                                              TextEditingController()
                                                            ];
                                                            selectedPaymentMethods = [
                                                              null
                                                            ];
                                                            totalSplit = 0.0;
                                                          });
                                                        },
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                                          decoration: BoxDecoration(
                                                            color: isSplitPayment
                                                                ? appPrimaryColor
                                                                : greyColor200,
                                                            borderRadius: BorderRadius.circular(30),
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              "Split Payment",
                                                              style: MyTextStyle.f12(
                                                                isSplitPayment
                                                                    ? whiteColor
                                                                    : blackColor,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : const SizedBox(),
                                      if ((isCompleteOrder == true &&
                                          postAddToBillingModel
                                              .total !=
                                              widget
                                                  .existingOrder
                                                  ?.data!
                                                  .total &&
                                          widget.isEditingOrder ==
                                              true &&
                                          widget
                                              .existingOrder
                                              ?.data!
                                              .orderStatus ==
                                              "COMPLETED") ||
                                          ((widget.isEditingOrder ==
                                              false ||
                                              widget.isEditingOrder ==
                                                  null) &&
                                              isCompleteOrder ==
                                                  true) ||
                                          (isCompleteOrder ==
                                              true &&
                                              widget.isEditingOrder ==
                                                  true &&
                                              widget
                                                  .existingOrder
                                                  ?.data!
                                                  .orderStatus ==
                                                  "WAITLIST"))
                                        !isSplitPayment
                                            ? Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                            children: [
                                              SizedBox(
                                                  height:
                                                  12),
                                              Text(
                                                  "Payment Method",
                                                  style: MyTextStyle.f14(
                                                      blackColor,
                                                      weight:
                                                      FontWeight.bold)),
                                              SizedBox(
                                                  height:
                                                  12),
                                              SingleChildScrollView(
                                                scrollDirection:
                                                Axis.horizontal,
                                                child:
                                                Wrap(
                                                  spacing:
                                                  12,
                                                  runSpacing:
                                                  12,
                                                  children: [
                                                    if (isPaymentMethodAllowed("Cash"))
                                                      GestureDetector(
                                                        onTap: () {
                                                          setState(() {
                                                            selectedFullPaymentMethod = "Cash";
                                                          });
                                                        },
                                                        child: PaymentOption(
                                                          icon: Icons.money,
                                                          label: "Cash",
                                                          selected: selectedFullPaymentMethod == "Cash",
                                                        ),
                                                      ),
                                                    if (isPaymentMethodAllowed("Card"))
                                                      GestureDetector(
                                                        onTap: () {
                                                          setState(() {
                                                            selectedFullPaymentMethod = "Card";
                                                          });
                                                        },
                                                        child: PaymentOption(
                                                          icon: Icons.credit_card,
                                                          label: "Card",
                                                          selected: selectedFullPaymentMethod == "Card",
                                                        ),
                                                      ),
                                                    if (isPaymentMethodAllowed("UPI"))
                                                      GestureDetector(
                                                        onTap: () {
                                                          setState(() {
                                                            selectedFullPaymentMethod = "UPI";
                                                          });

                                                          if (getStockMaintanencesModel.data?.image != null && getStockMaintanencesModel.data!.image!.isNotEmpty) {
                                                            showDialog(
                                                              context: context,
                                                              builder: (context) {
                                                                return AlertDialog(
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius: BorderRadius.circular(12),
                                                                  ),
                                                                  title: const Text("Scan to Pay"),
                                                                  content: SizedBox(
                                                                    width: 250,
                                                                    height: 250,
                                                                    child: Image.network(
                                                                      getStockMaintanencesModel.data!.image!,
                                                                      fit: BoxFit.contain,
                                                                      errorBuilder: (context, error, stackTrace) => const Text("Failed to load QR"),
                                                                    ),
                                                                  ),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed: () => Navigator.pop(context),
                                                                      child: const Text("Close", style: TextStyle(color: appPrimaryColor)),
                                                                    ),
                                                                  ],
                                                                );
                                                              },
                                                            );
                                                          } else {
                                                            showToast("QR code not available", context, color: false);
                                                          }
                                                        },
                                                        child: PaymentOption(
                                                          icon: Icons.qr_code,
                                                          label: "UPI",
                                                          selected: selectedFullPaymentMethod == "UPI",
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ])
                                            : Container(),
                                      if ((isCompleteOrder == true &&
                                          postAddToBillingModel
                                              .total !=
                                              widget
                                                  .existingOrder
                                                  ?.data!
                                                  .total &&
                                          widget.isEditingOrder ==
                                              true &&
                                          widget
                                              .existingOrder
                                              ?.data!
                                              .orderStatus ==
                                              "COMPLETED") ||
                                          ((widget.isEditingOrder ==
                                              false ||
                                              widget.isEditingOrder ==
                                                  null) &&
                                              isCompleteOrder ==
                                                  true) ||
                                          (isCompleteOrder ==
                                              true &&
                                              widget.isEditingOrder ==
                                                  true &&
                                              widget
                                                  .existingOrder
                                                  ?.data!
                                                  .orderStatus ==
                                                  "WAITLIST"))
                                        isSplitPayment
                                            ? Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                          children: [
                                            SizedBox(
                                              height: 20,
                                            ),
                                            Text(
                                              "Split Payment",
                                              style: MyTextStyle.f20(
                                                  blackColor,
                                                  weight:
                                                  FontWeight.bold),
                                            ),
                                            SizedBox(
                                              height: 20,
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                              children: [
                                                for (int i =
                                                0;
                                                i < _paymentFieldCount;
                                                i++)
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 6),
                                                    child:
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: DropdownButtonFormField<String>(
                                                            value: selectedPaymentMethods[i],
                                                            decoration: InputDecoration(
                                                              labelText: "Select",
                                                              labelStyle: MyTextStyle.f14(greyColor),
                                                              filled: true,
                                                              fillColor: whiteColor,
                                                              enabledBorder: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(12),
                                                                borderSide: BorderSide(color: appPrimaryColor, width: 1.5),
                                                              ),
                                                              focusedBorder: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(12),
                                                                borderSide: BorderSide(color: appPrimaryColor, width: 2),
                                                              ),
                                                            ),
                                                            dropdownColor: whiteColor,
                                                            icon: Icon(Icons.keyboard_arrow_down_rounded, color: appPrimaryColor),
                                                            style: MyTextStyle.f14(blackColor, weight: FontWeight.w500),
                                                            items: [
                                                              if (isPaymentMethodAllowed("Cash"))
                                                                const DropdownMenuItem(value: "Cash", child: Text("Cash")),
                                                              if (isPaymentMethodAllowed("Card"))
                                                                const DropdownMenuItem(value: "Card", child: Text("Card")),
                                                              if (isPaymentMethodAllowed("UPI"))
                                                                const DropdownMenuItem(value: "UPI", child: Text("UPI")),
                                                            ],
                                                            onChanged: (value) {
                                                              setState(() {
                                                                selectedPaymentMethods[i] = value ?? "";
                                                              });
                                                            },
                                                          ),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        Expanded(
                                                          child: TextField(
                                                            controller: splitAmountControllers[i],
                                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                            inputFormatters: [
                                                              FilteringTextInputFormatter.digitsOnly
                                                            ],
                                                            decoration: InputDecoration(
                                                              hintText: "₹ Amount",
                                                              filled: true,
                                                              fillColor: whiteColor,
                                                              enabledBorder: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(8),
                                                                borderSide: BorderSide(color: appPrimaryColor, width: 1.5),
                                                              ),
                                                              focusedBorder: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(8),
                                                                borderSide: BorderSide(color: appPrimaryColor, width: 2),
                                                              ),
                                                            ),
                                                            onChanged: (value) {
                                                              setState(() {
                                                                splitChange = true;
                                                                double total = 0.0;
                                                                for (var controller in splitAmountControllers) {
                                                                  total += double.tryParse(controller.text) ?? 0.0;
                                                                }
                                                                totalSplit = total;
                                                              });
                                                            },
                                                          ),
                                                        ),
                                                        if (i > 0) ...[
                                                          const SizedBox(width: 5),
                                                          IconButton(
                                                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                                                            onPressed: () => removePaymentField(i),
                                                            padding: EdgeInsets.zero,
                                                            constraints: const BoxConstraints(),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                Align(
                                                  alignment:
                                                  Alignment.centerLeft,
                                                  child:
                                                  GestureDetector(
                                                    onTap: _paymentFieldCount < 3
                                                        ? addPaymentField
                                                        : null,
                                                    child:
                                                    Text(
                                                      _paymentFieldCount < 3
                                                          ? "+ Add Another Payment"
                                                          : "",
                                                      style:
                                                      TextStyle(
                                                        decoration: _paymentFieldCount < 3 ? TextDecoration.underline : null,
                                                        color: _paymentFieldCount < 3 ? appPrimaryColor : greyColor,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                                height:
                                                12),
                                            Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                              children: [
                                                Text(
                                                  "Total Split",
                                                  style: MyTextStyle.f14(
                                                      blackColor,
                                                      weight:
                                                      FontWeight.bold),
                                                ),
                                                Text(
                                                  "₹ ${totalSplit.toStringAsFixed(2)}",
                                                  style: MyTextStyle.f14(
                                                      blackColor,
                                                      weight:
                                                      FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                            if ((splitChange ==
                                                true &&
                                                totalSplit !=
                                                    postAddToBillingModel
                                                        .total))
                                              Text(
                                                "Split payments must sum to ₹ ${widget.isEditingOrder == true && widget.existingOrder?.data!.orderStatus == "COMPLETED" ? (balance < 0 ? 0 : balance) : (postAddToBillingModel.total ?? 0).toDouble()}",
                                                style: MyTextStyle.f12(
                                                    redColor,
                                                    weight:
                                                    FontWeight.bold),
                                              ),
                                          ],
                                        )
                                            : Container(),
                                      SizedBox(height: 12),
                                      !isSplitPayment
                                          ? Row(
                                        children: [
                                          selectedOrderType ==
                                              OrderType
                                                  .line ||
                                              selectedOrderType ==
                                                  OrderType.ac
                                              ? Expanded(
                                            child: orderLoad
                                                ? SpinKitCircle(color: appPrimaryColor, size: 30)
                                                : ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  isCompleteOrder = false;
                                                });
                                                List<Map<String, dynamic>> payments = [
                                                  {
                                                    "amount": (postAddToBillingModel.total ?? 0).toDouble(),
                                                    "balanceAmount": 0,
                                                    "method": selectedFullPaymentMethod.toUpperCase(),
                                                  },
                                                ];
                                                final orderPayload = buildOrderPayload(
                                                  postAddToBillingModel: postAddToBillingModel,
                                                  tableId: selectedOrderType == OrderType.line || selectedOrderType == OrderType.ac ? tableId : null,
                                                  waiterId: selectedOrderType == OrderType.line || selectedOrderType == OrderType.ac ? waiterId : null,
                                                  orderStatus: 'WAITLIST',
                                                  orderType: selectedOrderType == OrderType.line
                                                      ? 'LINE'
                                                      : selectedOrderType == OrderType.parcel
                                                      ? 'PARCEL'
                                                      : selectedOrderType == OrderType.ac
                                                      ? "AC"
                                                      : selectedOrderType == OrderType.hd
                                                      ? "HD"
                                                      : "SWIGGY",
                                                  discountAmount: postAddToBillingModel.totalDiscount!.toStringAsFixed(2),
                                                  isDiscountApplied: isDiscountApplied,
                                                  tipAmount: tipController.text,
                                                  payments: widget.isEditingOrder == true ? [] : payments,
                                                );
                                                debugPrint("payloadSave:${widget.existingOrder?.data!.id}");
                                                debugPrint("payloadSave:${jsonEncode(orderPayload)}");
                                                setState(() {
                                                  orderLoad = true;
                                                });
                                                if (widget.isEditingOrder == true && (postAddToBillingModel.total != widget.existingOrder?.data!.total && widget.existingOrder?.data!.orderStatus == "WAITLIST")) {
                                                  /* if (((selectedValue == null || selectedValue == 'N/A') && selectedOrderType == OrderType.line) || (selectedValue == null || selectedValue == 'N/A') && selectedOrderType == OrderType.ac) {
                                                                                      showToast("Table number is required for LINE/AC orders", context, color: false);
                                                                                      setState(() {
                                                                                        orderLoad = false;
                                                                                      });
                                                                                    } else if (((selectedValueWaiter == null || selectedValueWaiter == 'N/A') && selectedOrderType == OrderType.line) || (selectedValueWaiter == null || selectedValueWaiter == 'N/A') && selectedOrderType == OrderType.ac) {
                                                                                      showToast("Waiter name is required for LINE/AC orders", context, color: false);
                                                                                      setState(() {
                                                                                        orderLoad = false;
                                                                                      });
                                                                                    } else {
                                                                                      setState(() {
                                                                                        isCompleteOrder = false;
                                                                                      });
                                                                                      context.read<FoodCategoryBloc>().add(UpdateOrder(jsonEncode(orderPayload), widget.existingOrder?.data!.id));
                                                                                    }*/
                                                  context.read<FoodCategoryBloc>().add(UpdateOrder(jsonEncode(orderPayload), widget.existingOrder?.data!.id));

                                                } else {
                                                  setState(() {
                                                    isCompleteOrder = false;
                                                  });
                                                  context.read<FoodCategoryBloc>().add(GenerateOrder(jsonEncode(orderPayload)));
                                                }
                                                /* if ((selectedValue == null && selectedOrderType == OrderType.line) || (selectedValue == null && selectedOrderType == OrderType.ac)) {
                                                                                    // setState(() {
                                                                                    //  // isCompleteOrder = false;
                                                                                    // });
                                                                                    // // showToast("Table number is required for LINE/AC orders", context, color: false);
                                                                                    // // return;
                                                                                  } else if ((selectedValueWaiter == null && selectedOrderType == OrderType.line) || (selectedValueWaiter == null && selectedOrderType == OrderType.ac)) {
                                                                                    // setState(() {
                                                                                    //   isCompleteOrder = false;
                                                                                    // });
                                                                                    // showToast("Waiter name is required for LINE/AC orders", context, color: false);
                                                                                    // return;
                                                                                  } else if (((widget.isEditingOrder == null || widget.isEditingOrder == false)) || (widget.isEditingOrder == true && (postAddToBillingModel.total != widget.existingOrder?.data!.total && widget.existingOrder?.data!.orderStatus == "WAITLIST"))) {

                                                                                  }*/
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: (widget.isEditingOrder == null || widget.isEditingOrder == false) || (widget.isEditingOrder == true && (postAddToBillingModel.total != widget.existingOrder?.data!.total && widget.existingOrder?.data!.orderStatus == "WAITLIST")) ? appPrimaryColor : greyColor,
                                                minimumSize: const Size(0, 50), // Height only
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(30),
                                                ),
                                              ),
                                              child: Text(
                                                "Save Order",
                                                style: TextStyle(color: (widget.isEditingOrder == null || widget.isEditingOrder == false) || (widget.isEditingOrder == true && (postAddToBillingModel.total != widget.existingOrder?.data!.total && widget.existingOrder?.data!.orderStatus == "WAITLIST")) ? whiteColor : blackColor),
                                              ),
                                            ),
                                          )
                                              : Container(),
                                          const SizedBox(
                                              width: 10),
                                          Expanded(
                                            child:
                                            completeLoad
                                                ? SpinKitCircle(
                                                color: appPrimaryColor,
                                                size: 30)
                                                : ElevatedButton(
                                              onPressed: () {
                                                /* Full payment */
                                                if (false) {
                                                  showToast("Table number is required for LINE/AC orders", context, color: false);
                                                } else if (false) {
                                                  showToast("Waiter name is required for LINE/AC orders", context, color: false);
                                                } else {
                                                  if ((widget.isEditingOrder == false || widget.isEditingOrder == null) || (widget.isEditingOrder == true && widget.existingOrder?.data!.orderStatus == "WAITLIST")) {
                                                    setState(() {
                                                      isCompleteOrder = true;
                                                    });
                                                    if (selectedFullPaymentMethod.isEmpty || (selectedFullPaymentMethod != "Cash" && selectedFullPaymentMethod != "Card" && selectedFullPaymentMethod != "UPI")) {
                                                      showToast("Select any one of the payment method", context, color: false);
                                                      return;
                                                    }
                                                    if (selectedFullPaymentMethod == "Cash" || selectedFullPaymentMethod == "Card" || selectedFullPaymentMethod == "UPI") {
                                                      List<Map<String, dynamic>> payments = [];
                                                      payments = [
                                                        {
                                                          "amount": (postAddToBillingModel.total ?? 0).toDouble(),
                                                          "balanceAmount": 0,
                                                          "method": selectedFullPaymentMethod.toUpperCase(),
                                                        }
                                                      ];
                                                      final orderPayload = buildOrderPayload(
                                                        postAddToBillingModel: postAddToBillingModel,
                                                        tableId: selectedOrderType == OrderType.line || selectedOrderType == OrderType.ac ? tableId : null,
                                                        waiterId: selectedOrderType == OrderType.line || selectedOrderType == OrderType.ac ? waiterId : null,
                                                        orderStatus: 'COMPLETED',
                                                        orderType: selectedOrderType == OrderType.line
                                                            ? 'LINE'
                                                            : selectedOrderType == OrderType.parcel
                                                            ? 'PARCEL'
                                                            : selectedOrderType == OrderType.ac
                                                            ? "AC"
                                                            : selectedOrderType == OrderType.hd
                                                            ? "HD"
                                                            : "SWIGGY",
                                                        discountAmount: postAddToBillingModel.totalDiscount!.toStringAsFixed(2),
                                                        isDiscountApplied: isDiscountApplied,
                                                        tipAmount: tipController.text,
                                                        payments: payments,
                                                      );
                                                      debugPrint("payloadComplete:${widget.existingOrder?.data!.id}");
                                                      debugPrint("payloadComplete:${jsonEncode(orderPayload)}");
                                                      setState(() {
                                                        completeLoad = true;
                                                      });
                                                      if ((widget.isEditingOrder == true && widget.existingOrder?.data!.orderStatus == "WAITLIST")) {
                                                        context.read<FoodCategoryBloc>().add(UpdateOrder(jsonEncode(orderPayload), widget.existingOrder!.data!.id));
                                                      } else {
                                                        context.read<FoodCategoryBloc>().add(GenerateOrder(jsonEncode(orderPayload)));
                                                      }
                                                    }
                                                  }
                                                  if ((widget.isEditingOrder == true && (postAddToBillingModel.total != widget.existingOrder?.data!.total && widget.existingOrder?.data!.orderStatus == "COMPLETED"))) {
                                                    if (balance < 0) {
                                                      setState(() {
                                                        isCompleteOrder = false;
                                                      });
                                                      List<Map<String, dynamic>> payments = [];
                                                      debugPrint("payment<0:$payments");
                                                      final orderPayload = buildOrderPayload(
                                                        postAddToBillingModel: postAddToBillingModel,
                                                        tableId: selectedOrderType == OrderType.line || selectedOrderType == OrderType.ac ? tableId : null,
                                                        waiterId: selectedOrderType == OrderType.line || selectedOrderType == OrderType.ac ? waiterId : null,
                                                        orderStatus: 'COMPLETED',
                                                        orderType: selectedOrderType == OrderType.line
                                                            ? 'LINE'
                                                            : selectedOrderType == OrderType.parcel
                                                            ? 'PARCEL'
                                                            : selectedOrderType == OrderType.ac
                                                            ? "AC"
                                                            : selectedOrderType == OrderType.hd
                                                            ? "HD"
                                                            : "SWIGGY",
                                                        discountAmount: postAddToBillingModel.totalDiscount!.toStringAsFixed(2),
                                                        isDiscountApplied: isDiscountApplied,
                                                        tipAmount: tipController.text,
                                                        payments: payments,
                                                      );
                                                      debugPrint("payloadComplete<0:${widget.existingOrder?.data!.id}");
                                                      debugPrint("payloadComplete<0:${jsonEncode(orderPayload)}");
                                                      setState(() {
                                                        completeLoad = true;
                                                      });
                                                      context.read<FoodCategoryBloc>().add(UpdateOrder(jsonEncode(orderPayload), widget.existingOrder!.data!.id));
                                                      balance = 0;
                                                    }
                                                    if (balance >= 0) {
                                                      setState(() {
                                                        isCompleteOrder = true;
                                                      });
                                                      if (selectedFullPaymentMethod.isEmpty || (selectedFullPaymentMethod != "Cash" && selectedFullPaymentMethod != "Card" && selectedFullPaymentMethod != "UPI")) {
                                                        showToast("Select any one of the payment method", context, color: false);
                                                        return;
                                                      }
                                                      if (selectedFullPaymentMethod == "Cash" || selectedFullPaymentMethod == "Card" || selectedFullPaymentMethod == "UPI") {
                                                        List<Map<String, dynamic>> payments = [];
                                                        payments = [
                                                          {
                                                            "amount": widget.existingOrder?.data!.orderStatus == "COMPLETED" ? (balance < 0 ? 0 : balance) : (postAddToBillingModel.total ?? 0).toDouble(),
                                                            "balanceAmount": 0,
                                                            "method": selectedFullPaymentMethod.toUpperCase(),
                                                          }
                                                        ];
                                                        debugPrint("payment>=0:$payments");
                                                        final orderPayload = buildOrderPayload(
                                                          postAddToBillingModel: postAddToBillingModel,
                                                          tableId: selectedOrderType == OrderType.line || selectedOrderType == OrderType.ac ? tableId : null,
                                                          waiterId: selectedOrderType == OrderType.line || selectedOrderType == OrderType.ac ? waiterId : null,
                                                          orderStatus: 'COMPLETED',
                                                          orderType: selectedOrderType == OrderType.line
                                                              ? 'LINE'
                                                              : selectedOrderType == OrderType.parcel
                                                              ? 'PARCEL'
                                                              : selectedOrderType == OrderType.ac
                                                              ? "AC"
                                                              : selectedOrderType == OrderType.hd
                                                              ? "HD"
                                                              : "SWIGGY",
                                                          discountAmount: postAddToBillingModel.totalDiscount!.toStringAsFixed(2),
                                                          isDiscountApplied: isDiscountApplied,
                                                          tipAmount: tipController.text,
                                                          payments: payments,
                                                        );
                                                        debugPrint("payloadComplete>=0:${widget.existingOrder?.data!.id}");
                                                        debugPrint("payloadComplete>=0:${jsonEncode(orderPayload)}");
                                                        setState(() {
                                                          completeLoad = true;
                                                        });
                                                        debugPrint("editIdCompleted:${widget.existingOrder!.data!.id}");
                                                        context.read<FoodCategoryBloc>().add(UpdateOrder(jsonEncode(orderPayload), widget.existingOrder!.data!.id));
                                                        balance = 0;
                                                      }
                                                    }
                                                  }
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: appPrimaryColor,
                                                minimumSize: const Size(0, 50),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(30),
                                                ),
                                              ),
                                              child: Text(
                                                widget.isEditingOrder == true && widget.existingOrder?.data!.orderStatus == "COMPLETED" ? "Update Order" : "Complete Order",
                                                style: TextStyle(color: whiteColor),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                          : completeLoad
                                          ? SpinKitCircle(
                                          color:
                                          appPrimaryColor,
                                          size: 30)
                                          : ElevatedButton(
                                        onPressed:
                                            () {
                                          if (!allSplitAmountsFilled() ||
                                              !allPaymentMethodsSelected()) {
                                            showToast(
                                              "Please complete payment method and amount fields",
                                              context,
                                              color:
                                              false,
                                            );
                                            return;
                                          }

                                          if ((widget.isEditingOrder !=
                                              true &&
                                              totalSplit !=
                                                  postAddToBillingModel.total)) {
                                            showToast(
                                              "Split payments must sum to ₹ ${widget.isEditingOrder == true && widget.existingOrder?.data!.orderStatus == "COMPLETED" ? (balance < 0 ? 0 : balance) : (postAddToBillingModel.total ?? 0).toDouble()}",
                                              context,
                                              color:
                                              false,
                                            );
                                            return;
                                          }

                                          if ((selectedValue ==
                                              null &&
                                              selectedOrderType ==
                                                  OrderType
                                                      .line) ||
                                              (selectedValue ==
                                                  null &&
                                                  selectedOrderType ==
                                                      OrderType.ac)) {
                                            showToast(
                                              "Table number is required for LINE/AC orders",
                                              context,
                                              color:
                                              false,
                                            );
                                            return;
                                          }
                                          if ((selectedValueWaiter ==
                                              null &&
                                              selectedOrderType ==
                                                  OrderType
                                                      .line) ||
                                              (selectedValueWaiter ==
                                                  null &&
                                                  selectedOrderType ==
                                                      OrderType.ac)) {
                                            showToast(
                                              "Waiter name is required for LINE/AC orders",
                                              context,
                                              color:
                                              false,
                                            );
                                            return;
                                          }
                                          List<Map<String, dynamic>>
                                          payments =
                                          [];
                                          if ((widget.isEditingOrder ==
                                              false ||
                                              widget.isEditingOrder ==
                                                  null) ||
                                              (widget.isEditingOrder ==
                                                  true &&
                                                  widget.existingOrder?.data!.orderStatus ==
                                                      "WAITLIST")) {
                                            if (isSplitPayment) {
                                              for (int i =
                                              0;
                                              i < _paymentFieldCount;
                                              i++) {
                                                final method =
                                                selectedPaymentMethods[i];
                                                final amountText =
                                                    splitAmountControllers[i].text;
                                                final amount =
                                                    double.tryParse(amountText) ?? 0;
                                                if (method == null ||
                                                    method.isEmpty) {
                                                  showToast("Please select a payment method for split #${i + 1}",
                                                      context,
                                                      color: false);
                                                  return;
                                                }

                                                payments
                                                    .add({
                                                  "amount":
                                                  amount,
                                                  "balanceAmount":
                                                  0,
                                                  "method":
                                                  method.toUpperCase(),
                                                });
                                              }
                                            }
                                            final orderPayload =
                                            buildOrderPayload(
                                              postAddToBillingModel:
                                              postAddToBillingModel,
                                              tableId: selectedOrderType == OrderType.line ||
                                                  selectedOrderType == OrderType.ac
                                                  ? tableId
                                                  : null,
                                              waiterId: selectedOrderType == OrderType.line ||
                                                  selectedOrderType == OrderType.ac
                                                  ? waiterId
                                                  : null,
                                              orderStatus:
                                              'COMPLETED',
                                              orderType: selectedOrderType ==
                                                  OrderType.line
                                                  ? 'LINE'
                                                  : selectedOrderType == OrderType.parcel
                                                  ? 'PARCEL'
                                                  : selectedOrderType == OrderType.ac
                                                  ? "AC"
                                                  : selectedOrderType == OrderType.hd
                                                  ? "HD"
                                                  : "SWIGGY",
                                              discountAmount: postAddToBillingModel
                                                  .totalDiscount!
                                                  .toStringAsFixed(2),
                                              isDiscountApplied:
                                              isDiscountApplied,
                                              tipAmount:
                                              tipController.text,
                                              payments:
                                              payments,
                                            );
                                            setState(
                                                    () {
                                                  completeLoad =
                                                  true;
                                                });
                                            if ((widget.isEditingOrder ==
                                                true &&
                                                widget.existingOrder?.data!.orderStatus ==
                                                    "WAITLIST")) {
                                              context.read<FoodCategoryBloc>().add(UpdateOrder(
                                                  jsonEncode(orderPayload),
                                                  widget.existingOrder!.data!.id));
                                            } else {
                                              context
                                                  .read<FoodCategoryBloc>()
                                                  .add(GenerateOrder(jsonEncode(orderPayload)));
                                            }
                                          }
                                          if ((widget.isEditingOrder ==
                                              true &&
                                              (postAddToBillingModel.total != widget.existingOrder?.data!.total &&
                                                  widget.existingOrder?.data!.orderStatus ==
                                                      "COMPLETED"))) {
                                            if (balance <
                                                0) {
                                              if (isSplitPayment) {
                                                for (int i = 0;
                                                i < _paymentFieldCount;
                                                i++) {
                                                  final method =
                                                  selectedPaymentMethods[i];
                                                  final amountText =
                                                      splitAmountControllers[i].text;
                                                  final amount =
                                                      double.tryParse(amountText) ?? 0;
                                                  if (method == null ||
                                                      method.isEmpty) {
                                                    showToast("Please select a payment method for split #${i + 1}", context, color: false);
                                                    return;
                                                  }
                                                }
                                              }

                                              final orderPayload =
                                              buildOrderPayload(
                                                postAddToBillingModel:
                                                postAddToBillingModel,
                                                tableId: selectedOrderType == OrderType.line || selectedOrderType == OrderType.ac
                                                    ? tableId
                                                    : null,
                                                waiterId: selectedOrderType == OrderType.line || selectedOrderType == OrderType.ac
                                                    ? waiterId
                                                    : null,
                                                orderStatus:
                                                'COMPLETED',
                                                orderType: selectedOrderType == OrderType.line
                                                    ? 'LINE'
                                                    : selectedOrderType == OrderType.parcel
                                                    ? 'PARCEL'
                                                    : selectedOrderType == OrderType.ac
                                                    ? "AC"
                                                    : selectedOrderType == OrderType.hd
                                                    ? "HD"
                                                    : "SWIGGY",
                                                discountAmount: postAddToBillingModel
                                                    .totalDiscount!
                                                    .toStringAsFixed(2),
                                                isDiscountApplied:
                                                isDiscountApplied,
                                                tipAmount:
                                                tipController.text,
                                                payments:
                                                payments,
                                              );
                                              setState(
                                                      () {
                                                    completeLoad =
                                                    true;
                                                  });
                                              context.read<FoodCategoryBloc>().add(UpdateOrder(
                                                  jsonEncode(orderPayload),
                                                  widget.existingOrder!.data!.id));
                                              balance =
                                              0;
                                            }
                                            if (balance >=
                                                0) {
                                              if (isSplitPayment) {
                                                for (int i = 0;
                                                i < _paymentFieldCount;
                                                i++) {
                                                  final method =
                                                  selectedPaymentMethods[i];
                                                  final amountText =
                                                      splitAmountControllers[i].text;
                                                  final amount =
                                                      double.tryParse(amountText) ?? 0;
                                                  if (method == null ||
                                                      method.isEmpty) {
                                                    showToast("Please select a payment method for split #${i + 1}", context, color: false);
                                                    return;
                                                  }
                                                  if (widget.isEditingOrder == true &&
                                                      widget.existingOrder!.data!.orderStatus == "COMPLETED" &&
                                                      balance != amount) {
                                                    showToast("Amount not matching", context, color: false);
                                                    return;
                                                  }

                                                  payments.add({
                                                    "amount": widget.existingOrder?.data!.orderStatus == "COMPLETED" ? (balance < 0 ? 0 : balance) : amount,
                                                    "balanceAmount": 0,
                                                    "method": method.toUpperCase(),
                                                  });
                                                }
                                              }

                                              final orderPayload =
                                              buildOrderPayload(
                                                postAddToBillingModel:
                                                postAddToBillingModel,
                                                tableId: selectedOrderType == OrderType.line || selectedOrderType == OrderType.ac
                                                    ? tableId
                                                    : null,
                                                waiterId: selectedOrderType == OrderType.line || selectedOrderType == OrderType.ac
                                                    ? waiterId
                                                    : null,
                                                orderStatus:
                                                'COMPLETED',
                                                orderType: selectedOrderType == OrderType.line
                                                    ? 'LINE'
                                                    : selectedOrderType == OrderType.parcel
                                                    ? 'PARCEL'
                                                    : selectedOrderType == OrderType.ac
                                                    ? "AC"
                                                    : selectedOrderType == OrderType.hd
                                                    ? "HD"
                                                    : "SWIGGY",
                                                discountAmount: postAddToBillingModel
                                                    .totalDiscount!
                                                    .toStringAsFixed(2),
                                                isDiscountApplied:
                                                isDiscountApplied,
                                                tipAmount:
                                                tipController.text,
                                                payments:
                                                payments,
                                              );
                                              setState(
                                                      () {
                                                    completeLoad =
                                                    true;
                                                  });
                                              context.read<FoodCategoryBloc>().add(UpdateOrder(
                                                  jsonEncode(orderPayload),
                                                  widget.existingOrder!.data!.id));
                                              balance =
                                              0;
                                            }
                                          }
                                        },
                                        style: ElevatedButton
                                            .styleFrom(
                                          backgroundColor: (allSplitAmountsFilled() &&
                                              allPaymentMethodsSelected() &&
                                              totalSplit == postAddToBillingModel.total) ||
                                              (widget.isEditingOrder == true && widget.existingOrder?.data!.orderStatus == "COMPLETED")
                                              ? appPrimaryColor
                                              : greyColor,
                                          minimumSize:
                                          Size(
                                              double.infinity,
                                              50),
                                          shape:
                                          RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(
                                                30),
                                          ),
                                        ),
                                        child: Text(
                                          "Print Bills",
                                          style: TextStyle(
                                              color:
                                              whiteColor),
                                        ),
                                      )
                                    ],
                                  ),
                                )))),
                  )
                ])),
      );
    }

    return BlocBuilder<FoodCategoryBloc, dynamic>(
      buildWhen: ((previous, current) {
        if (current is GetCategoryModel) {
          getCategoryModel = current;
          if (getCategoryModel.success == true) {
            setState(() {
              categoryLoad = false;
            });
          }
          if (getCategoryModel.errorResponse?.isUnauthorized == true) {
            _handle401Error();
            return true;
          }
          return true;
        }
        if (current is GetProductByCatIdModel) {
          getProductByCatIdModel = current;
          if (getProductByCatIdModel.errorResponse?.isUnauthorized == true) {
            _handle401Error();
            return true;
          }
          if (getProductByCatIdModel.success == true) {
            setState(() {
              categoryLoad = false;
            });
          }
          return true;
        }
        if (current is PostAddToBillingModel) {
          postAddToBillingModel = current;
          if (postAddToBillingModel.errorResponse?.isUnauthorized == true) {
            _handle401Error();
            return true;
          }
          return true;
        }
        if (current is PostGenerateOrderModel) {
          postGenerateOrderModel = current;
          if (postGenerateOrderModel.errorResponse?.isUnauthorized == true) {
            _handle401Error();
            return true;
          }
          if (postGenerateOrderModel.errorResponse?.statusCode == 500) {
            showToast("${postGenerateOrderModel.message}", context,
                color: false);
            setState(() {
              orderLoad = false;
              completeLoad = false;
            });
            return true;
          }
          if (postGenerateOrderModel.errorResponse != null) {
            showToast(
                postGenerateOrderModel.errorResponse?.message ??
                    "An error occurred",
                context,
                color: false);
            setState(() {
              orderLoad = false;
              completeLoad = false;
            });
            return true;
          }
          showToast("${postGenerateOrderModel.message}", context, color: true);
          bool shouldPrintReceipt = isCompleteOrder;
          setState(() {
            orderLoad = false;
            completeLoad = false;
            billingItems.clear();
            selectedValue = null;
            selectedValueWaiter = null;
            tableId = null;
            waiterId = null;
            _resetToDefaultOrderType();
            isCompleteOrder = false;
            isSplitPayment = false;
            amountController.clear();
            selectedFullPaymentMethod = "";
            widget.isEditingOrder = false;
            balance = 0;
            if (billingItems.isEmpty || billingItems == []) {
              isDiscountApplied = false;
            }
          });

          context.read<FoodCategoryBloc>().add(AddToBilling(
              List.from(billingItems), isDiscountApplied, selectedOrderType));
          context.read<FoodCategoryBloc>().add(FoodProductItem(
              selectedCatId.toString(),
              searchController.text,
              searchProdIdController.text));
          if (postGenerateOrderModel.message != null) {
            printGenerateOrderReceipt();
            // if (shouldPrintReceipt == true &&
            //     postGenerateOrderModel.message != null) {
            //   printGenerateOrderReceipt();
          } else {
            debugPrint("Receipt not printed - shouldPrintReceipt is false");
          }
          return true;
        }
        if (current is UpdateGenerateOrderModel) {
          updateGenerateOrderModel = current;
          if (updateGenerateOrderModel.errorResponse?.isUnauthorized == true) {
            _handle401Error();
            return true;
          }
          if (updateGenerateOrderModel.errorResponse?.statusCode == 500) {
            showToast(
                updateGenerateOrderModel.errorResponse?.message ??
                    "Server error occurred",
                context,
                color: false);
            setState(() {
              orderLoad = false;
              completeLoad = false;
            });
            return true;
          }
          if (updateGenerateOrderModel.errorResponse != null) {
            showToast(
                updateGenerateOrderModel.errorResponse?.message ??
                    "An error occurred",
                context,
                color: false);
            setState(() {
              orderLoad = false;
              completeLoad = false;
            });
            return true;
          }
          showToast("${updateGenerateOrderModel.message}", context,
              color: true);
          bool shouldPrintReceipt = isCompleteOrder;
          setState(() {
            completeLoad = false;
            billingItems.clear();
            selectedValue = null;
            selectedValueWaiter = null;
            tableId = null;
            waiterId = null;
            _resetToDefaultOrderType();
            isCompleteOrder = false;
            isSplitPayment = false;
            amountController.clear();
            selectedFullPaymentMethod = "";
            widget.isEditingOrder = false;
            balance = 0;
            if (billingItems.isEmpty || billingItems == []) {
              isDiscountApplied = false;
            }
          });
          context.read<FoodCategoryBloc>().add(AddToBilling(
              List.from(billingItems), isDiscountApplied, selectedOrderType));
          context.read<FoodCategoryBloc>().add(FoodProductItem(
              selectedCatId.toString(),
              searchController.text,
              searchProdIdController.text));
          if (updateGenerateOrderModel.message != null) {
            printUpdateOrderReceipt();
            // if (shouldPrintReceipt == true &&
            //     updateGenerateOrderModel.message != null) {
            //   printUpdateOrderReceipt();
          } else {
            debugPrint("Receipt not printed - shouldPrintReceipt is false");
          }
          return true;
        }
        if (current is GetTableModel) {
          getTableModel = current;
          if (getTableModel.errorResponse?.isUnauthorized == true) {
            _handle401Error();
            return true;
          }
          if (getTableModel.success == true) {
            setState(() {
              categoryLoad = false;
            });
          } else {
            setState(() {
              categoryLoad = false;
            });
            showToast("No Tables found", context, color: false);
          }
          return true;
        }
        if (current is GetWaiterModel) {
          getWaiterModel = current;
          if (getWaiterModel.errorResponse?.isUnauthorized == true) {
            _handle401Error();
            return true;
          }
          if (getWaiterModel.success == true) {
            setState(() {
              categoryLoad = false;
            });
          } else {
            setState(() {
              categoryLoad = false;
            });
            showToast("No Waiter found", context, color: false);
          }
          return true;
        }
        if (current is GetStockMaintanencesModel) {
          getStockMaintanencesModel = current;
          if (getStockMaintanencesModel.errorResponse?.isUnauthorized == true) {
            _handle401Error();
            return true;
          }
          if (getStockMaintanencesModel.success == true) {
            setState(() {
              categoryLoad = false;
              _shopLogo = getStockMaintanencesModel.data?.logo;
            });
            if (getStockMaintanencesModel.data?.logo != null) {
              SharedPreferences.getInstance().then((prefs) {
                prefs.setString('shop_logo', getStockMaintanencesModel.data!.logo!);
              });
            }
          } else {
            setState(() {
              categoryLoad = false;
            });
            showToast("No Stock found", context, color: false);
          }
          return true;
        }
        if (current is GetCompanyModel) {
          getCompanyModelData = current;
          if (getCompanyModelData.errorResponse?.isUnauthorized == true) {
            _handle401Error();
            return true;
          }
          if (getCompanyModelData.success == true) {
            // Set default order type based on available prices
            if (selectedOrderType == OrderType.line && !isPriceTypeAvailable("basePrice")) {
              _resetToDefaultOrderType();
            }

            // Set default payment method if restricted
            String? defaultMethod = getCompanyModelData.data?.defaultPaymentMethod;
            if (defaultMethod != null && defaultMethod.toLowerCase() != "all") {
              final Map<String, String> paymentMap = {
                "card": "Card",
                "cash": "Cash",
                "upi": "UPI"
              };
              if (paymentMap.containsKey(defaultMethod.toLowerCase())) {
                selectedFullPaymentMethod = paymentMap[defaultMethod.toLowerCase()]!;
              }
            }
            setState(() {});
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
