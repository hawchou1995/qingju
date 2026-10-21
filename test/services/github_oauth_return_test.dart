import 'package:flutter_test/flutter_test.dart';
import 'package:fluxdo/services/github_oauth_return.dart';

void main() {
  group('GitHub OAuth return helpers', () {
    test('只识别 HTTPS github.com 页面', () {
      expect(
        isGithubHostUrl('https://github.com/login/oauth/authorize'),
        isTrue,
      );
      expect(isGithubHostUrl('https://github.com.evil.example/'), isFalse);
      expect(isGithubHostUrl('http://github.com/'), isFalse);
      expect(isGithubHostUrl('https://qingju.me/'), isFalse);
      expect(isGithubHostUrl(null), isFalse);
    });

    test('只从已认证 session 响应提取用户名', () {
      expect(
        currentUsernameFromSessionResponse({
          'current_user': {'username': 'hawchou'},
        }),
        'hawchou',
      );
      expect(
        currentUsernameFromSessionResponse({'current_user': null}),
        isNull,
      );
      expect(
        currentUsernameFromSessionResponse({
          'current_user': {'username': '  '},
        }),
        isNull,
      );
      expect(currentUsernameFromSessionResponse(null), isNull);
    });
  });
}
