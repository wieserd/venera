import 'package:flutter_test/flutter_test.dart';
import 'package:venera/foundation/settings.dart';

void main() {
  group('Settings Unit Tests', () {
    late Settings settings;

    setUp(() {
      settings = Settings.create();
    });

    test('default settings values match expectations', () {
      expect(settings.comicDisplayMode, 'detailed');
      expect(settings.comicTileScale, 1.0);
      expect(settings.color, 'system');
      expect(settings.themeMode, 'system');
      expect(settings.proxy, 'system');
      expect(settings.readerMode, 'galleryLeftToRight');
      expect(settings.cacheSize, 2048);
      expect(settings.downloadThreads, 5);
      expect(settings.enableTapToTurnPages, true);
      expect(settings.reverseTapToTurnPages, false);
      expect(settings.showPageNumberInReader, true);
      expect(settings.comicSourceListUrl, defaultSourceListUrl);
    });

    test('typed setters update underlying values and reflect in index operator', () {
      settings.proxy = 'http://127.0.0.1:8080';
      expect(settings.proxy, 'http://127.0.0.1:8080');
      expect(settings['proxy'], 'http://127.0.0.1:8080');

      settings.cacheSize = 4096;
      expect(settings.cacheSize, 4096);
      expect(settings['cacheSize'], 4096);

      settings.readerMode = 'continuous';
      expect(settings.readerMode, 'continuous');
      expect(settings['readerMode'], 'continuous');

      settings.readerScrollSpeed = 2.5;
      expect(settings.readerScrollSpeed, 2.5);
      expect(settings['readerScrollSpeed'], 2.5);

      settings.enableDnsOverrides = true;
      expect(settings.enableDnsOverrides, true);
      expect(settings['enableDnsOverrides'], true);
    });

    test('updating via index operator reflects in typed getters', () {
      settings['comicDisplayMode'] = 'brief';
      expect(settings.comicDisplayMode, 'brief');

      settings['downloadThreads'] = 8;
      expect(settings.downloadThreads, 8);

      settings['ignoreBadCertificate'] = true;
      expect(settings.ignoreBadCertificate, true);

      settings['preloadImageCount'] = 10;
      expect(settings.preloadImageCount, 10);
    });

    test('ChangeNotifier triggers listeners on update', () {
      int notifyCount = 0;
      settings.addListener(() {
        notifyCount++;
      });

      settings.proxy = 'direct';
      expect(notifyCount, 1);

      settings['color'] = 'blue';
      expect(notifyCount, 2);

      // dataVersion update should intentionally not notify listeners
      settings['dataVersion'] = 1;
      expect(notifyCount, 2);
    });

    test('comic-specific and device-specific settings overrides work', () {
      const comicId = 'comic_123';
      const sourceKey = 'picacg';

      // Initially not enabled
      expect(settings.isComicSpecificSettingsEnabled(comicId, sourceKey), false);
      expect(settings.getReaderSetting(comicId, sourceKey, 'readerMode'), 'galleryLeftToRight');

      // Enable and set comic-specific override
      settings.setEnabledComicSpecificSettings(comicId, sourceKey, true);
      settings.setReaderSetting(comicId, sourceKey, 'readerMode', 'webtoon');

      expect(settings.isComicSpecificSettingsEnabled(comicId, sourceKey), true);
      expect(settings.getReaderSetting(comicId, sourceKey, 'readerMode'), 'webtoon');

      // Reset override
      settings.resetComicReaderSettings('$comicId@$sourceKey');
      expect(settings.isComicSpecificSettingsEnabled(comicId, sourceKey), false);
      expect(settings.getReaderSetting(comicId, sourceKey, 'readerMode'), 'galleryLeftToRight');
    });

    test('deviceId generation and persistence', () {
      expect(settings.deviceId, '');
      var id1 = settings.getOrCreateDeviceId();
      expect(id1.isNotEmpty, true);
      expect(settings.deviceId, id1);

      var id2 = settings.getOrCreateDeviceId();
      expect(id2, id1);
    });
  });
}
