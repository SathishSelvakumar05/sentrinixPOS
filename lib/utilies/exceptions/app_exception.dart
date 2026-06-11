import 'package:dio/dio.dart';
import 'dart:developer';
import 'dart:io';
class AppException implements Exception {
  AppException({
    this.statusCode,
    this.code,
    this.errorCode,
    this.message,
    this.data,
  });

  AppException.fromJson(Map<String, dynamic> json) {
    if (json['error'] != null) {
      final Map<String, dynamic> jsons = json['error'] as Map<String, dynamic>;
      code = jsons['code'] as String?;
      errorCode = jsons['errorCode'] as String?;

      message = jsons['message'] as String?;
      if (jsons['data'] != null) {
        data = jsons['data'] as Map<String, dynamic>?;
      }
    }
  }

  int? statusCode;
  String? errorCode;
  String? code;
  String? message;
  Map<String, dynamic>? data;

  @override
  String toString() {
    return errorCode ?? 'Exception';
  }

  factory AppException.fromDioError(DioException dioException) {
    String errorCode = "unknown";
    log("exception type:${dioException.type}");
    switch (dioException.type) {

      case DioExceptionType.badResponse:
        switch (dioException.response?.statusCode) {
          case 400:
            errorCode = "badRequest";
          case 401:
            errorCode = "unauthorized";
          case 403:
            errorCode = "forbidden";
          case 404:
            errorCode = "notFound";
          case 422:
            errorCode = "duplicateEmail";
          case 500:
            errorCode = "internalServerError";
          case 502:
            errorCode = "badGateway";
          default:
            errorCode = errorCode;
        }
        break;
      case DioExceptionType.cancel:
        errorCode = "cancelRequest";
        break;
      case DioExceptionType.connectionTimeout:
        errorCode = "connectionTimeOut";
        break;
      case DioExceptionType.receiveTimeout:
        errorCode = "receiveTimeOut";
        break;
      case DioExceptionType.sendTimeout:
        errorCode = "sendTimeOut";
        break;
      case DioExceptionType.connectionError:
        log("connectionError error:${dioException.error}");
        log("connectionError message:${dioException.message}");

        errorCode = "connectionError";
        break;
      case DioExceptionType.unknown:
        errorCode = dioException.error.toString();
        break;
      default:
        errorCode = errorCode;
        break;
    }
    return AppException(
        statusCode: dioException.response?.statusCode,
        errorCode: errorCode,
        message: errorCode,
        code: errorCode);
  }

  /*factory AppException.fromFBError(FirebaseException error) {
    return AppException(
      code: error.code,
      errorCode: error.errorCode,
    );
  }*/

  factory AppException.fromSocketError(Exception error) {
    return AppException(
      errorCode: "socketException",
      message: "socketException",
    );
  }
}

extension HandleExceptionExtensions<T> on Future<T> {
  Future<T> get onAppError {
    return onError<Exception>(
          (exception, stackTrace) {
        if (exception is SocketException) {
          throw AppException.fromSocketError(exception);
        } else if (exception is DioException) {
          throw AppException.fromDioError(exception);
        } else {
          throw Exception();
        }

        /*  else if(exception is FirebaseException){
          throw AppException.fromFBError(exception);
        }*/
      },
      test: (exception) => exception is DioException,
    );
  }

  Future<T> get onApiError {
    return onError<Exception>(
          (exception, stackTrace) {
        if (exception is SocketException) {
          throw AppException.fromSocketError(exception);
        }
        throw AppException.fromDioError(exception as DioException);
      },
      test: (exception) => exception is DioException,
    );
  }
}