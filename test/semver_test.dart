import 'package:flutter_test/flutter_test.dart';
import 'package:venera/foundation/comic_source/comic_source.dart';

void main() {
  group('SemVer Comparison Tests', () {
    test('identical versions return false', () {
      expect(compareSemVer('1.0.0', '1.0.0'), false);
      expect(compareSemVer('2.4.1', '2.4.1'), false);
    });

    test('major version differences', () {
      expect(compareSemVer('2.0.0', '1.9.9'), true);
      expect(compareSemVer('1.0.0', '2.0.0'), false);
    });

    test('minor version differences', () {
      expect(compareSemVer('1.5.0', '1.4.9'), true);
      expect(compareSemVer('1.2.0', '1.3.0'), false);
    });

    test('patch version differences', () {
      expect(compareSemVer('1.0.2', '1.0.1'), true);
      expect(compareSemVer('1.0.0', '1.0.1'), false);
    });

    test('hotfix version comparisons', () {
      expect(compareSemVer('1.0.0.hotfix', '1.0.0'), true);
      expect(compareSemVer('1.0.0', '1.0.0.hotfix'), false);
    });
  });
}
