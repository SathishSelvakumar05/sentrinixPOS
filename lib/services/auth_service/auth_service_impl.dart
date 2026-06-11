import 'auth_service.dart';

class AuthServiceImpl implements AuthService {
  String? _accessToken;
  String? _refreshToken;

  AuthServiceImpl();

  @override
  String? get accessToken => _accessToken;

  @override
  String? get refreshToken => _refreshToken;

  @override
  setTokens({
    required String? accessToken,
    required String? refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }



/* @override
  Future<void> loadTokensFromStorage() async {
    _accessToken = await _localStorage.getString('accessToken');
    _refreshToken = await _localStorage.getString('refreshToken');
  }

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;

    await _localStorage.remove('accessToken');
    await _localStorage.remove('refreshToken');
  }*/
}
