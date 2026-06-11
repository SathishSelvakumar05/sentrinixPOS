import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simple/data/repositories/product/product_repository.dart';
import 'package:simple/services/log_service/log_service.dart';
import 'package:simple/injector/injector.dart';

abstract class ProductCategoryEvent {}

class ProductCategory extends ProductCategoryEvent {}

class ProductItem extends ProductCategoryEvent {
  String catId;
  ProductItem(this.catId);
}

class ProductCategoryBloc extends Bloc<ProductCategoryEvent, dynamic> {
  final ProductRepository _productRepository;
  final LogService _logService;
  static const String tag = 'ProductCategoryBloc';

  ProductCategoryBloc({
    ProductRepository? productRepository,
    LogService? logService,
  })  : _productRepository = productRepository ?? injector<ProductRepository>(),
        _logService = logService ?? injector<LogService>(),
        super(null) {
    on<ProductCategory>(_onProductCategory);
    on<ProductItem>(_onProductItem);
  }

  Future<void> _onProductCategory(
      ProductCategory event, Emitter<dynamic> emit) async {
    try {
      final response = await _productRepository.getCategory();
      emit(response);
    } catch (e, s) {
      _logService.e("$tag ProductCategory error", e, s);
      emit(e);
    }
  }

  Future<void> _onProductItem(
      ProductItem event, Emitter<dynamic> emit) async {
    try {
      final response = await _productRepository.getProductsCat(event.catId);
      emit(response);
    } catch (e, s) {
      _logService.e("$tag ProductItem error", e, s);
      emit(e);
    }
  }
}
