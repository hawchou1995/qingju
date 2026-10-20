/// 客户端唯一站点身份；不接受其他论坛会话或深链。
abstract final class SiteIdentity {
  static const name = '青橘';
  static const baseUrl = 'https://qingju.me';
  static const host = 'qingju.me';
  static const applicationId = 'me.qingju.client';
  static const scheme = 'qingju';
  static const repository = 'hawchou1995/qingju';
  static const supportsLinuxDoServices = false;

  /// Cookie、CSRF 只允许发往 HTTPS 主站，子域/CDN 不继承会话。
  static bool isCredentialOrigin(Uri uri) =>
      uri.scheme == 'https' && uri.host.toLowerCase() == host && uri.port == 443;

  static bool isSiteHost(String value) => value.toLowerCase() == host;

  static bool isLegacyHost(String value) {
    final normalized = value.toLowerCase();
    return normalized == 'linux.do' || normalized.endsWith('.linux.do');
  }
}
