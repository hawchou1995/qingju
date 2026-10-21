import 'package:flutter_test/flutter_test.dart';
import 'package:fluxdo/services/update_service.dart';

void main() {
  group('GitHubReleaseParser', () {
    test('只移除完整的青橘或 v 发布前缀', () {
      expect(GitHubReleaseParser.normalizeTag('qingju-v0.2.31'), '0.2.31');
      expect(GitHubReleaseParser.normalizeTag('v0.2.31'), '0.2.31');
      expect(GitHubReleaseParser.normalizeTag('qingju-v0.2.28.3'), '0.2.28.3');
      expect(
        GitHubReleaseParser.compareVersions('0.2.28.3', '0.2.28.2'),
        greaterThan(0),
      );
      expect(GitHubReleaseParser.normalizeTag('qingju-0.2.31'), '0.2.31');
      expect(GitHubReleaseParser.normalizeTag('0.2.31'), '0.2.31');
    });

    test('按数字段比较版本', () {
      expect(
        GitHubReleaseParser.compareVersions('0.2.31', '0.2.30'),
        greaterThan(0),
      );
      expect(
        GitHubReleaseParser.compareVersions('0.10.0', '0.9.9'),
        greaterThan(0),
      );
      expect(GitHubReleaseParser.compareVersions('0.2.31', '0.2.31'), 0);
    });

    test('识别青橘版本化 ARM64 debug APK', () {
      expect(
        GitHubReleaseParser.architectureFromAsset(
          'qingju-0.2.31-android-arm64-debug.apk',
        ),
        'arm64-v8a',
      );
      expect(
        GitHubReleaseParser.architectureFromAsset('old-arm64-v8a.apk'),
        'arm64-v8a',
      );
      expect(
        GitHubReleaseParser.architectureFromAsset(
          'qingju-0.2.31-linux-x64.tar.gz',
        ),
        isNull,
      );
    });

    test('拒绝无法解析的发布 tag', () {
      expect(
        () => GitHubReleaseParser.normalizeTag('qingju-latest'),
        throwsFormatException,
      );
    });
  });
}
