import 'package:flutter_test/flutter_test.dart';
import 'package:fluxdo/config/site_identity.dart';
import 'package:fluxdo/services/webview_session_cookie_refresh_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'qingju skips the Linux.do-only fingerprint session bootstrap',
    () async {
      expect(SiteIdentity.supportsLinuxDoServices, isFalse);

      final result = await WebViewSessionCookieRefreshService.instance
          .ensureSynced(reason: 'test_qingju_unsupported_site');

      expect(result.ok, isFalse);
      expect(result.phase, 'unsupported_site');
    },
  );
}
