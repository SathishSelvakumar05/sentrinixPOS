import 'package:simple/ModelClass/Authentication/Post_login_model.dart';
import 'package:simple/data/Network/api_client/api_client.dart';
import 'package:simple/data/repositories/auth/auth_repository.dart';
import 'package:simple/utilies/exceptions/app_exception.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;
  late final ApiClient _apiClient;

  @override
  Future<PostLoginModel> loginUser(Map<String, String> payLoad) async {
    return  await _apiClient.loginUser(payLoad).onApiError;
  }
}