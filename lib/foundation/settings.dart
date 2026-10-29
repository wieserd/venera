import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

const defaultCustomImageProcessing = '''
/**
 * Process an image
 * @param image {ArrayBuffer} - The image to process
 * @param cid {string} - The comic ID
 * @param eid {string} - The episode ID
 * @param page {number} - The page number
 * @param sourceKey {string} - The source key
 * @returns {Promise<ArrayBuffer> | {image: Promise<ArrayBuffer>, onCancel: () => void}} - The processed image
 */
async function processImage(image, cid, eid, page, sourceKey) {
    let futureImage = new Promise((resolve, reject) => {
        resolve(image);
    });
    return futureImage;
}
''';

const defaultSourceListUrl =
    "https://cdn.jsdelivr.net/gh/venera-app/venera-configs@main/index.json";

/// Application Settings with strongly typed properties and backwards-compatible index access.
class Settings with ChangeNotifier {
  Settings._create();

  static Settings create() => Settings._create();

  final _data = <String, dynamic>{
    'comicDisplayMode': 'detailed', // detailed, brief
    'comicTileScale': 1.00, // 0.75-1.25
    'color': 'system', // red, pink, purple, green, orange, blue
    'theme_mode': 'system', // light, dark, system
    'newFavoriteAddTo': 'end', // start, end
    'moveFavoriteAfterRead': 'none', // none, end, start
    'proxy': 'system', // direct, system, proxy string
    'explore_pages': [],
    'categories': [],
    'favorites': [],
    'searchSources': null,
    'showFavoriteStatusOnTile': true,
    'showHistoryStatusOnTile': false,
    'blockedWords': [],
    'blockedCommentWords': [],
    'defaultSearchTarget': null,
    'autoPageTurningInterval': 5, // in seconds
    'readerMode': 'galleryLeftToRight', // values of [ReaderMode]
    'readerScreenPicNumberForLandscape': 1, // 1 - 5
    'readerScreenPicNumberForPortrait': 1, // 1 - 5
    'enableTapToTurnPages': true,
    'reverseTapToTurnPages': false,
    'enablePageAnimation': true,
    'language': 'system', // system, zh-CN, zh-TW, en-US
    'cacheSize': 2048, // in MB
    'downloadThreads': 5,
    'enableLongPressToZoom': true,
    'longPressZoomPosition': "press", // press, center
    'checkUpdateOnStart': false,
    'limitImageWidth': true,
    'webdav': [], // empty means not configured
    "disableSyncFields": "", // "field1, field2, ..."
    'dataVersion': 0,
    'quickFavorite': null,
    'enableTurnPageByVolumeKey': true,
    'enableClockAndBatteryInfoInReader': true,
    'quickCollectImage': 'No', // No, DoubleTap, Swipe
    'authorizationRequired': false,
    'onClickFavorite': 'viewDetail', // viewDetail, read
    'enableDnsOverrides': false,
    'dnsOverrides': {},
    'enableCustomImageProcessing': false,
    'customImageProcessing': defaultCustomImageProcessing,
    'sni': true,
    'autoAddLanguageFilter': 'none', // none, chinese, english, japanese
    'comicSourceListUrl': defaultSourceListUrl,
    'preloadImageCount': 4,
    'followUpdatesFolder': null,
    'initialPage': '0',
    'comicListDisplayMode': 'paging', // paging, continuous
    'showPageNumberInReader': true,
    'showSingleImageOnFirstPage': false,
    'enableDoubleTapToZoom': true,
    'reverseChapterOrder': false,
    'showSystemStatusBar': false,
    'comicSpecificSettings': <String, Map<String, dynamic>>{},
    'deviceSpecificSettings': <String, Map<String, dynamic>>{},
    'deviceId': '',
    'ignoreBadCertificate': false,
    'readerScrollSpeed': 1.0, // 0.5 - 3.0
    'localFavoritesFirst': true,
    'autoCloseFavoritePanel': false,
    'showChapterComments': true, // show chapter comments in reader
    'showChapterCommentsAtEnd': false, // show chapter comments at end of chapter
  };

  // Backwards compatibility operators
  operator [](String key) => _data[key];

  operator []=(String key, dynamic value) {
    _data[key] = value;
    if (key != "dataVersion") {
      notifyListeners();
    }
  }

  // Raw data map getter for serialization / sync
  Map<String, dynamic> get rawData => _data;

  // -------------------------------------------------------------
  // 1. UI & Appearance Settings
  // -------------------------------------------------------------
  String get comicDisplayMode => (_data['comicDisplayMode'] as String?) ?? 'detailed';
  set comicDisplayMode(String value) => this['comicDisplayMode'] = value;

  double get comicTileScale => (_data['comicTileScale'] as num?)?.toDouble() ?? 1.0;
  set comicTileScale(double value) => this['comicTileScale'] = value;

  String get color => (_data['color'] as String?) ?? 'system';
  set color(String value) => this['color'] = value;

  String get themeMode => (_data['theme_mode'] as String?) ?? 'system';
  set themeMode(String value) => this['theme_mode'] = value;

  String get language => (_data['language'] as String?) ?? 'system';
  set language(String value) => this['language'] = value;

  String get initialPage => (_data['initialPage'] as String?) ?? '0';
  set initialPage(String value) => this['initialPage'] = value;

  String get comicListDisplayMode => (_data['comicListDisplayMode'] as String?) ?? 'paging';
  set comicListDisplayMode(String value) => this['comicListDisplayMode'] = value;

  bool get showSystemStatusBar => _data['showSystemStatusBar'] == true;
  set showSystemStatusBar(bool value) => this['showSystemStatusBar'] = value;

  // -------------------------------------------------------------
  // 2. Reader Settings
  // -------------------------------------------------------------
  String get readerMode => (_data['readerMode'] as String?) ?? 'galleryLeftToRight';
  set readerMode(String value) => this['readerMode'] = value;

  int get autoPageTurningInterval => (_data['autoPageTurningInterval'] as num?)?.toInt() ?? 5;
  set autoPageTurningInterval(int value) => this['autoPageTurningInterval'] = value;

  int get readerScreenPicNumberForLandscape =>
      (_data['readerScreenPicNumberForLandscape'] as num?)?.toInt() ?? 1;
  set readerScreenPicNumberForLandscape(int value) =>
      this['readerScreenPicNumberForLandscape'] = value;

  int get readerScreenPicNumberForPortrait =>
      (_data['readerScreenPicNumberForPortrait'] as num?)?.toInt() ?? 1;
  set readerScreenPicNumberForPortrait(int value) =>
      this['readerScreenPicNumberForPortrait'] = value;

  bool get enableTapToTurnPages => _data['enableTapToTurnPages'] != false;
  set enableTapToTurnPages(bool value) => this['enableTapToTurnPages'] = value;

  bool get reverseTapToTurnPages => _data['reverseTapToTurnPages'] == true;
  set reverseTapToTurnPages(bool value) => this['reverseTapToTurnPages'] = value;

  bool get enablePageAnimation => _data['enablePageAnimation'] != false;
  set enablePageAnimation(bool value) => this['enablePageAnimation'] = value;

  bool get enableTurnPageByVolumeKey => _data['enableTurnPageByVolumeKey'] != false;
  set enableTurnPageByVolumeKey(bool value) => this['enableTurnPageByVolumeKey'] = value;

  bool get enableClockAndBatteryInfoInReader =>
      _data['enableClockAndBatteryInfoInReader'] != false;
  set enableClockAndBatteryInfoInReader(bool value) =>
      this['enableClockAndBatteryInfoInReader'] = value;

  bool get enableLongPressToZoom => _data['enableLongPressToZoom'] != false;
  set enableLongPressToZoom(bool value) => this['enableLongPressToZoom'] = value;

  bool get enableDoubleTapToZoom => _data['enableDoubleTapToZoom'] != false;
  set enableDoubleTapToZoom(bool value) => this['enableDoubleTapToZoom'] = value;

  int get preloadImageCount => (_data['preloadImageCount'] as num?)?.toInt() ?? 4;
  set preloadImageCount(int value) => this['preloadImageCount'] = value;

  bool get showPageNumberInReader => _data['showPageNumberInReader'] != false;
  set showPageNumberInReader(bool value) => this['showPageNumberInReader'] = value;

  bool get showSingleImageOnFirstPage => _data['showSingleImageOnFirstPage'] == true;
  set showSingleImageOnFirstPage(bool value) => this['showSingleImageOnFirstPage'] = value;

  bool get reverseChapterOrder => _data['reverseChapterOrder'] == true;
  set reverseChapterOrder(bool value) => this['reverseChapterOrder'] = value;

  double get readerScrollSpeed => (_data['readerScrollSpeed'] as num?)?.toDouble() ?? 1.0;
  set readerScrollSpeed(double value) => this['readerScrollSpeed'] = value;

  bool get showChapterComments => _data['showChapterComments'] != false;
  set showChapterComments(bool value) => this['showChapterComments'] = value;

  bool get showChapterCommentsAtEnd => _data['showChapterCommentsAtEnd'] == true;
  set showChapterCommentsAtEnd(bool value) => this['showChapterCommentsAtEnd'] = value;

  String get quickCollectImage => (_data['quickCollectImage'] as String?) ?? 'No';
  set quickCollectImage(String value) => this['quickCollectImage'] = value;

  // -------------------------------------------------------------
  // 3. Network & Proxy Settings
  // -------------------------------------------------------------
  String get proxy => (_data['proxy'] as String?) ?? 'system';
  set proxy(String value) => this['proxy'] = value;

  bool get sni => _data['sni'] != false;
  set sni(bool value) => this['sni'] = value;

  bool get ignoreBadCertificate => _data['ignoreBadCertificate'] == true;
  set ignoreBadCertificate(bool value) => this['ignoreBadCertificate'] = value;

  bool get enableDnsOverrides => _data['enableDnsOverrides'] == true;
  set enableDnsOverrides(bool value) => this['enableDnsOverrides'] = value;

  Map get dnsOverrides => (_data['dnsOverrides'] as Map?) ?? {};
  set dnsOverrides(Map value) => this['dnsOverrides'] = value;

  String get comicSourceListUrl =>
      (_data['comicSourceListUrl'] as String?) ?? defaultSourceListUrl;
  set comicSourceListUrl(String value) => this['comicSourceListUrl'] = value;

  // -------------------------------------------------------------
  // 4. Download & Storage Settings
  // -------------------------------------------------------------
  int get cacheSize => (_data['cacheSize'] as num?)?.toInt() ?? 2048;
  set cacheSize(int value) => this['cacheSize'] = value;

  int get downloadThreads => (_data['downloadThreads'] as num?)?.toInt() ?? 5;
  set downloadThreads(int value) => this['downloadThreads'] = value;

  bool get limitImageWidth => _data['limitImageWidth'] != false;
  set limitImageWidth(bool value) => this['limitImageWidth'] = value;

  List get webdav => (_data['webdav'] as List?) ?? [];
  set webdav(List value) => this['webdav'] = value;

  // -------------------------------------------------------------
  // 5. Favorites & Organization Settings
  // -------------------------------------------------------------
  String get newFavoriteAddTo => (_data['newFavoriteAddTo'] as String?) ?? 'end';
  set newFavoriteAddTo(String value) => this['newFavoriteAddTo'] = value;

  String get moveFavoriteAfterRead => (_data['moveFavoriteAfterRead'] as String?) ?? 'none';
  set moveFavoriteAfterRead(String value) => this['moveFavoriteAfterRead'] = value;

  String? get followUpdatesFolder => _data['followUpdatesFolder'] as String?;
  set followUpdatesFolder(String? value) => this['followUpdatesFolder'] = value;

  bool get localFavoritesFirst => _data['localFavoritesFirst'] != false;
  set localFavoritesFirst(bool value) => this['localFavoritesFirst'] = value;

  bool get autoCloseFavoritePanel => _data['autoCloseFavoritePanel'] == true;
  set autoCloseFavoritePanel(bool value) => this['autoCloseFavoritePanel'] = value;

  bool get showFavoriteStatusOnTile => _data['showFavoriteStatusOnTile'] != false;
  set showFavoriteStatusOnTile(bool value) => this['showFavoriteStatusOnTile'] = value;

  bool get showHistoryStatusOnTile => _data['showHistoryStatusOnTile'] == true;
  set showHistoryStatusOnTile(bool value) => this['showHistoryStatusOnTile'] = value;

  String? get quickFavorite => _data['quickFavorite'] as String?;
  set quickFavorite(String? value) => this['quickFavorite'] = value;

  String get onClickFavorite => (_data['onClickFavorite'] as String?) ?? 'viewDetail';
  set onClickFavorite(String value) => this['onClickFavorite'] = value;

  // -------------------------------------------------------------
  // 6. Security & Identification
  // -------------------------------------------------------------
  bool get authorizationRequired => _data['authorizationRequired'] == true;
  set authorizationRequired(bool value) => this['authorizationRequired'] = value;

  String get deviceId => (_data['deviceId'] as String?) ?? '';
  set deviceId(String value) => this['deviceId'] = value;

  bool get checkUpdateOnStart => _data['checkUpdateOnStart'] == true;
  set checkUpdateOnStart(bool value) => this['checkUpdateOnStart'] = value;

  int get dataVersion => (_data['dataVersion'] as num?)?.toInt() ?? 0;
  set dataVersion(int value) => this['dataVersion'] = value;

  // -------------------------------------------------------------
  // 7. Comic-Specific & Device-Specific Settings
  // -------------------------------------------------------------
  void setEnabledComicSpecificSettings(
    String comicId,
    String sourceKey,
    bool enabled,
  ) {
    setReaderSetting(comicId, sourceKey, "enabled", enabled);
  }

  bool isComicSpecificSettingsEnabled(String? comicId, String? sourceKey) {
    if (comicId == null || sourceKey == null) {
      return false;
    }
    return _data['comicSpecificSettings']["$comicId@$sourceKey"]?["enabled"] == true;
  }

  dynamic getReaderSetting(String comicId, String sourceKey, String key) {
    if (isComicSpecificSettingsEnabled(comicId, sourceKey)) {
      var comicValue =
          _data['comicSpecificSettings']["$comicId@$sourceKey"]?[key];
      if (comicValue != null) {
        return comicValue;
      }
    }
    return getDeviceReaderSetting(key);
  }

  void setReaderSetting(
    String comicId,
    String sourceKey,
    String key,
    dynamic value,
  ) {
    (_data['comicSpecificSettings'] as Map<String, dynamic>).putIfAbsent(
      "$comicId@$sourceKey",
      () => <String, dynamic>{},
    )[key] = value;
    notifyListeners();
  }

  void resetComicReaderSettings(String key) {
    (_data['comicSpecificSettings'] as Map).remove(key);
    notifyListeners();
  }

  void setEnabledDeviceSpecificSettings(bool enabled) {
    setDeviceReaderSetting("enabled", enabled);
  }

  bool isDeviceSpecificSettingsEnabled() {
    var id = deviceId;
    if (id.isEmpty) {
      return false;
    }
    return _data['deviceSpecificSettings'][id]?["enabled"] == true;
  }

  dynamic getDeviceReaderSetting(String key) {
    if (!isDeviceSpecificSettingsEnabled()) {
      return _data[key];
    }
    var id = deviceId;
    return _data['deviceSpecificSettings'][id]?[key] ?? _data[key];
  }

  void setDeviceReaderSetting(String key, dynamic value) {
    var id = getOrCreateDeviceId();
    (_data['deviceSpecificSettings'] as Map<String, dynamic>).putIfAbsent(
      id,
      () => <String, dynamic>{},
    )[key] = value;
    notifyListeners();
  }

  void resetDeviceReaderSettings() {
    var id = deviceId;
    if (id.isEmpty) {
      return;
    }
    (_data['deviceSpecificSettings'] as Map).remove(id);
    notifyListeners();
  }

  String getOrCreateDeviceId() {
    var id = deviceId;
    if (id.isNotEmpty) {
      return id;
    }
    var newId = const Uuid().v4();
    this['deviceId'] = newId;
    return newId;
  }

  @override
  String toString() => _data.toString();
}
