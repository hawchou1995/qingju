/// 判断 WebView 当前页是否位于 GitHub OAuth 提供方。
bool isGithubHostUrl(String? rawUrl) {
  final uri = Uri.tryParse(rawUrl ?? '');
  return uri != null &&
      uri.scheme.toLowerCase() == 'https' &&
      uri.host.toLowerCase() == 'github.com';
}

/// 从 Discourse session probe 响应中提取已认证用户名。
String? currentUsernameFromSessionResponse(Object? data) {
  if (data is! Map) return null;
  final currentUser = data['current_user'];
  if (currentUser is! Map) return null;

  final username = currentUser['username']?.toString().trim();
  if (username == null || username.isEmpty) return null;
  return username;
}
