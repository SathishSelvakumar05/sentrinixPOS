abstract class AuthService {
  String? get accessToken;
  String? get refreshToken;
  setTokens({
    required String? accessToken,
    required String? refreshToken,
  });
}
