import 'package:simple/ModelClass/HomeScreen/Category&Product/Get_category_model.dart';
import 'package:simple/ModelClass/Products/get_products_cat_model.dart';

abstract class ProductRepository {
  Future<GetCategoryModel> getCategory();
  Future<GetProductsCatModel> getProductsCat(String? catId);
}
