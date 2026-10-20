import 'package:dio/dio.dart';

import '../../../config/site_identity.dart';

/// 网络工厂的第一道边界：拒绝旧站点请求，剥离所有跨站凭据。
class SiteBoundaryInterceptor extends Interceptor {
  static void stripCredentials(Map<String, dynamic> headers) {
    const sensitive = {
      'cookie', 'authorization', 'proxy-authorization', 'x-csrf-token',
      'user-api-key', 'user-api-client-id', 'api-key', 'api-username',
      'discourse-present',
    };
    headers.removeWhere((key, _) => sensitive.contains(key.toLowerCase()));
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (SiteIdentity.isLegacyHost(options.uri.host)) {
      stripCredentials(options.headers);
      handler.reject(DioException(
        requestOptions: options,
        type: DioExceptionType.cancel,
        error: '青橘客户端不连接原站专属服务',
      ));
      return;
    }
    if (!SiteIdentity.isCredentialOrigin(options.uri)) {
      stripCredentials(options.headers);
    }
    handler.next(options);
  }
}
