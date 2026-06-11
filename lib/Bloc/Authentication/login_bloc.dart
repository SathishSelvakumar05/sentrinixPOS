import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple/Api/apiProvider.dart';
import 'package:simple/ModelClass/Authentication/Post_login_model.dart';
import 'package:simple/data/repositories/auth/auth_repository.dart';
import 'package:simple/services/auth_service/auth_service.dart';
import 'package:simple/services/log_service/log_service.dart';
import 'package:simple/injector/injector.dart';

abstract class LoginInEvent {}

class LoginIn extends LoginInEvent {
  String email;
  String password;
  LoginIn(this.email, this.password);
}

abstract class LoginState { const LoginState(); }
class LoginInitial extends LoginState {}
class LoginLoading extends LoginState {}
class LoginSuccess extends LoginState {
  final PostLoginModel response;
  LoginSuccess(this.response);
}
class LoginError extends LoginState {
  final String message;
  LoginError(this.message);
}

class LoginInBloc extends Bloc<LoginInEvent, LoginState> {
  final _storage = const FlutterSecureStorage();
  final _apiProvider = ApiProvider();

  static const tag = 'LoginInBloc';

  LoginInBloc({
    AuthRepository? authRepository,
    LogService? logService,
    AuthService? authService,
  }) : super(LoginInitial()) {
    _authRepository = authRepository ?? injector<AuthRepository>();
    _logService = logService ?? injector<LogService>();
    _authService = authService ?? injector<AuthService>();

    on<LoginIn>(_onLoginIn);
  }

  late final AuthRepository _authRepository;
  late final LogService _logService;
  late final AuthService _authService;


  Future<void> _onLoginIn(LoginIn event, Emitter<LoginState> emit) async {
    emit(LoginLoading());

    try {
      final dataMap = {"email": event.email, "password": event.password};
      final response = await _authRepository.loginUser(dataMap);
      _logService.d("$tag response: ${response.toJson()}");
      // 1. Check if the provider attached an error response
      if (response.errorResponse != null) {
        emit(LoginError(response.errorResponse?.message ?? "Login failed"));
        return;
      }

      // 2. Check for success and token presence
      if (response.success == true && response.token != null) {
        await _storage.write(key: 'auth_token', value: response.token);
        _authService.setTokens(accessToken: response.token, refreshToken: '');
        SharedPreferences sharedPreferences = await SharedPreferences
            .getInstance();

        // Use null-aware operators (??) to prevent .toString() crashes on null values
        sharedPreferences.setString(
            "token", response.token?.toString() ?? "");
        sharedPreferences.setString(
            "role", response.user?.role?.toString() ?? "");
        sharedPreferences.setString(
            "userId", response.user?.id?.toString() ?? "");
        emit(LoginSuccess(response));
      } else {
        emit(LoginError(response.message ?? "Unexpected login error"));
      }
    } catch (e,s) {
      _logService.e('$tag} error', e, s);
      emit(LoginError("System Error: ${e.toString()}"));
    }
  }
}
