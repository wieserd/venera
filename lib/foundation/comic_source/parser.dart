part of 'comic_source.dart';

/// return true if ver1 > ver2
bool compareSemVer(String ver1, String ver2) {
  ver1 = ver1.replaceFirst("-", ".");
  ver2 = ver2.replaceFirst("-", ".");
  List<String> v1 = ver1.split('.');
  List<String> v2 = ver2.split('.');

  for (int i = 0; i < 3; i++) {
    int num1 = int.parse(v1[i]);
    int num2 = int.parse(v2[i]);

    if (num1 > num2) {
      return true;
    } else if (num1 < num2) {
      return false;
    }
  }

  var v14 = v1.elementAtOrNull(3);
  var v24 = v2.elementAtOrNull(3);

  if (v14 != v24) {
    if (v14 == null && v24 != "hotfix") {
      return true;
    } else if (v14 == null) {
      return false;
    }
    if (v24 == null) {
      if (v14 == "hotfix") {
        return true;
      }
      return false;
    }
    return v14.compareTo(v24) > 0;
  }

  return false;
}

class ComicSourceParseException implements Exception {
  final String message;

  ComicSourceParseException(this.message);

  @override
  String toString() {
    return message;
  }
}

class ComicSourceParser {
  /// comic source key
  String? _key;

  String? _name;

  Future<ComicSource> createAndParse(String js, String fileName) async {
    if (!fileName.endsWith("js")) {
      fileName = "$fileName.js";
    }
    var file = File(FilePath.join(App.dataPath, "comic_source", fileName));
    if (file.existsSync()) {
      int i = 0;
      while (file.existsSync()) {
        file = File(
          FilePath.join(
            App.dataPath,
            "comic_source",
            "${fileName.split('.').first}($i).js",
          ),
        );
        i++;
      }
    }
    await file.writeAsString(js);
    try {
      return await parse(js, file.path);
    } catch (e) {
      await file.delete();
      rethrow;
    }
  }

  Future<ComicSource> parse(String js, String filePath) async {
    js = js.replaceAll("\r\n", "\n");
    var line1 = js
        .split('\n')
        .firstWhereOrNull((e) => e.trim().startsWith("class "));
    if (line1 == null ||
        !line1.startsWith("class ") ||
        !line1.contains("extends ComicSource")) {
      throw ComicSourceParseException("Invalid Content");
    }
    var className = line1.split("class")[1].split("extends ComicSource").first;
    className = className.trim();
    JsEngine().runCode("""(() => { $js
        this['temp'] = new $className()
      }).call()
    """, className);
    _name =
        JsEngine().runCode("this['temp'].name") ??
        (throw ComicSourceParseException('name is required'));
    var key =
        JsEngine().runCode("this['temp'].key") ??
        (throw ComicSourceParseException('key is required'));
    var version =
        JsEngine().runCode("this['temp'].version") ??
        (throw ComicSourceParseException('version is required'));
    var minAppVersion = JsEngine().runCode("this['temp'].minAppVersion");
    var url = JsEngine().runCode("this['temp'].url");
    if (minAppVersion != null) {
      if (compareSemVer(minAppVersion, App.version.split('-').first)) {
        throw ComicSourceParseException(
          "minAppVersion @version is required".tlParams({
            "version": minAppVersion,
          }),
        );
      }
    }
    for (var source in ComicSource.all()) {
      if (source.key == key) {
        throw ComicSourceParseException("key($key) already exists");
      }
    }
    _key = key;
    _checkKeyValidation();

    JsEngine().runCode("""
      ComicSource.sources.$_key = this['temp'];
    """);

    var source = ComicSource(
      _name!,
      key,
      _loadAccountConfig(),
      _loadCategoryData(),
      _loadCategoryComicsData(),
      _loadFavoriteData(),
      _loadExploreData(),
      _loadSearchData(),
      _parseSettings(),
      _parseLoadComicFunc(),
      _parseThumbnailLoader(),
      _parseLoadComicPagesFunc(),
      _parseImageLoadingConfigFunc(),
      _parseThumbnailLoadingConfigFunc(),
      filePath,
      url ?? "",
      version ?? "1.0.0",
      _parseCommentsLoader(),
      _parseSendCommentFunc(),
      _parseChapterCommentsLoader(),
      _parseSendChapterCommentFunc(),
      _parseLikeFunc(),
      _parseVoteCommentFunc(),
      _parseLikeCommentFunc(),
      _parseIdMatch(),
      _parseTranslation(),
      _parseClickTagEvent(),
      _parseTagSuggestionSelectFunc(),
      _parseLinkHandler(),
      _getValue("search.enableTagsSuggestions") ?? false,
      _getValue("comic.enableTagsTranslate") ?? false,
      _parseStarRatingFunc(),
      _parseArchiveDownloader(),
    );

    await source.loadData();

    if (_checkExists("init")) {
      Future.delayed(const Duration(milliseconds: 50), () {
        JsEngine().runCode("ComicSource.sources.$_key.init()");
      });
    }

    return source;
  }

  _checkKeyValidation() {
    // 仅允许数字和字母以及下划线
    if (!_key!.contains(RegExp(r"^[a-zA-Z0-9_]+$"))) {
      throw ComicSourceParseException("key $_key is invalid");
    }
  }

  bool _checkExists(String index) {
    return JsEngine().runCode(
      "ComicSource.sources.$_key.$index !== null "
      "&& ComicSource.sources.$_key.$index !== undefined",
    );
  }

  dynamic _getValue(String index) {
    return JsEngine().runCode("ComicSource.sources.$_key.$index");
  }

}
