import 'package:dio/dio.dart';
import '../core/constants.dart';
import 'offline_queue_service.dart';

class ApiService {
  late final Dio _dio;
  String? _token;
  String _baseUrl = AppConstants.defaultBaseUrl;
  void Function()? onUnauthorized;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          _token = null;
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    ));
    OfflineQueueService().init(_dio);
  }

  String get baseUrl => _baseUrl;

  void setBaseUrl(String url) {
    _baseUrl = url;
    _dio.options.baseUrl = url;
  }

  void setToken(String? token) => _token = token;

  Future<Response> get(String path, {Map<String, dynamic>? query}) =>
      _dio.get(path, queryParameters: query);

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        await OfflineQueueService().enqueue(path, 'POST', data);
        return Response(
          requestOptions: e.requestOptions,
          statusCode: 202,
          data: {'queued': true, 'message': 'Request queued for offline sync'},
        );
      }
      rethrow;
    }
  }

  Future<Response> patch(String path, {dynamic data}) async {
    try {
      return await _dio.patch(path, data: data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        await OfflineQueueService().enqueue(path, 'PATCH', data);
        return Response(
          requestOptions: e.requestOptions,
          statusCode: 202,
          data: {'queued': true, 'message': 'Request queued for offline sync'},
        );
      }
      rethrow;
    }
  }
}
