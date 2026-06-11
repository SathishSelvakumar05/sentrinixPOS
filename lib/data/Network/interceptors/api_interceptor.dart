import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:simple/services/auth_service/auth_service.dart';
import 'package:simple/services/log_service/log_service.dart';

class ApiInterceptor extends Interceptor {
  final AuthService _authService;
  final LogService _log;
  ApiInterceptor(this._authService, this._log);
  final tag = "ApiInterceptor----->:";

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token =_authService.accessToken;
    if (token?.isNotEmpty??false) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    _log.d('$tag onRequest ${options.method} ${options.path}');
    _log.d('$tag onRequest Body ${options.data}');
    _log.d('$tag onRequest Body ${options.uri}');


    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _log.d('$tag onResponse ${response.statusCode} ${response.requestOptions.path}');
    _log.d('$tag onResponse data: ${response.data}');
    _log.d('$tag onResponse headers: ${response.headers}');
    _log.d('$tag onResponse data uri: ${response.realUri}');

    return handler.next(response);
  }

  @override
  void onError(err, ErrorInterceptorHandler handler) {
    _log.d('$tag onError: ${err.message}');
    _log.d('$tag onError: ${err.requestOptions.data}');
    _log.d('$tag onError: ${err.requestOptions.path}');
    _log.d('$tag onError: ${err.requestOptions.uri}');




    return handler.next(err);
  }
}
