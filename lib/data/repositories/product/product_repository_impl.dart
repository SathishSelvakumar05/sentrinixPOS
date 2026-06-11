import 'package:simple/ModelClass/HomeScreen/Category&Product/Get_category_model.dart';
import 'package:simple/ModelClass/Products/get_products_cat_model.dart';
import 'package:simple/data/Network/api_client/api_client.dart';
import 'package:simple/data/repositories/product/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;
  late final ApiClient _apiClient;

  @override
  Future<GetCategoryModel> getCategory() async {
    return await _apiClient.getCategory();
  }

  @override
  Future<GetProductsCatModel> getProductsCat(String? catId) async {
    return await _apiClient.getProductsCat(catId);
  }
}
