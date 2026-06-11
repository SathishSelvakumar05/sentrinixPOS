import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:simple/Reusable/constant.dart';
import 'package:simple/data/Network/interceptors/api_interceptor.dart';
import 'package:simple/injector/injector.dart';
import 'package:simple/services/auth_service/auth_service.dart';
import 'package:simple/services/log_service/log_service.dart';


class DioClient {
  DioClient._();

  static const String dioInstanceName = 'dioInstance';
  static final GetIt _injector = Injector.instance;

  static void setup() {
    _setupDio();
  }

  static void _setupDio() {
    /// Dio
    _injector.registerLazySingleton<Dio>(
          () {
        // TODO(boilerplate): custom DIO here
        final Dio dio = Dio(
          BaseOptions(
            baseUrl: Constants.baseUrl,
            connectTimeout: const Duration(seconds: 10), // connection timeout
            receiveTimeout: const Duration(seconds: 10), // receiving data timeout
          ),
        );

        dio.interceptors.add(ApiInterceptor(_injector<AuthService>(),_injector<LogService>()));

        if (!kReleaseMode) {
          dio.interceptors.add(
            PrettyDioLogger(
              requestHeader: true,
              requestBody: true,
              responseHeader: true,
              request: false,
            ),
          );
        }
        return dio;
      },
      instanceName: dioInstanceName,
    );
  }
}