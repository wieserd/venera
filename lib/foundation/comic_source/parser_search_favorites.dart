part of 'comic_source.dart';

extension _ComicSourceParserSearchFavorites on ComicSourceParser {
  AccountConfig? _loadAccountConfig() {
    if (!_checkExists("account")) {
      return null;
    }

    Future<Res<bool>> Function(String account, String pwd)? login;

    if (_checkExists("account.login")) {
      login = (account, pwd) async {
        try {
          await JsEngine().runCode("""
          ComicSource.sources.$_key.account.login(${jsonEncode(account)},
          ${jsonEncode(pwd)})
        """);
          var source = ComicSource.find(_key!)!;
          source.data["account"] = <String>[account, pwd];
          source.saveData();
          return const Res(true);
        } catch (e, s) {
          Log.error("Network", "$e\n$s");
          return Res.error(e.toString());
        }
      };
    }

    void logout() {
      JsEngine().runCode("ComicSource.sources.$_key.account.logout()");
    }

    bool Function(String url, String title)? checkLoginStatus;

    void Function()? onLoginSuccess;

    if (_checkExists('account.loginWithWebview')) {
      checkLoginStatus = (url, title) {
        return JsEngine().runCode("""
            ComicSource.sources.$_key.account.loginWithWebview.checkStatus(
              ${jsonEncode(url)}, ${jsonEncode(title)})
          """);
      };

      if (_checkExists('account.loginWithWebview.onLoginSuccess')) {
        onLoginSuccess = () {
          JsEngine().runCode("""
            ComicSource.sources.$_key.account.loginWithWebview.onLoginSuccess()
          """);
        };
      }
    }

    Future<bool> Function(List<String>)? validateCookies;

    if (_checkExists('account.loginWithCookies?.validate')) {
      validateCookies = (cookies) async {
        try {
          var res = await JsEngine().runCode("""
            ComicSource.sources.$_key.account.loginWithCookies.validate(${jsonEncode(cookies)})
          """);
          return res;
        } catch (e, s) {
          Log.error("Network", "$e\n$s");
          return false;
        }
      };
    }

    return AccountConfig(
      login,
      _getValue("account.loginWithWebview?.url"),
      _getValue("account.registerWebsite"),
      logout,
      checkLoginStatus,
      onLoginSuccess,
      ListOrNull.from(_getValue("account.loginWithCookies?.fields")),
      validateCookies,
    );
  }

  SearchPageData? _loadSearchData() {
    if (!_checkExists("search")) return null;
    var options = <SearchOptions>[];
    for (var element in _getValue("search.optionList") ?? []) {
      LinkedHashMap<String, String> map = LinkedHashMap<String, String>();
      for (var option in element["options"]) {
        if (option.isEmpty || !option.contains("-")) {
          continue;
        }
        var split = option.split("-");
        var key = split.removeAt(0);
        var value = split.join("-");
        map[key] = value;
      }
      options.add(
        SearchOptions(
          map,
          element["label"],
          element['type'] ?? 'select',
          element['default'] == null ? null : jsonEncode(element['default']),
        ),
      );
    }

    SearchFunction? loadPage;

    SearchNextFunction? loadNext;

    if (_checkExists('search.load')) {
      loadPage = (keyword, page, searchOption) async {
        try {
          var res = await JsEngine().runCode("""
          ComicSource.sources.$_key.search.load(
            ${jsonEncode(keyword)}, ${jsonEncode(searchOption)}, ${jsonEncode(page)})
        """);
          return Res(
            List.generate(
              res["comics"].length,
              (index) => Comic.fromJson(res["comics"][index], _key!),
            ),
            subData: res["maxPage"],
          );
        } catch (e, s) {
          Log.error("Network", "$e\n$s");
          return Res.error(e.toString());
        }
      };
    } else {
      loadNext = (keyword, next, searchOption) async {
        try {
          var res = await JsEngine().runCode("""
          ComicSource.sources.$_key.search.loadNext(
            ${jsonEncode(keyword)}, ${jsonEncode(searchOption)}, ${jsonEncode(next)})
        """);
          return Res(
            List.generate(
              res["comics"].length,
              (index) => Comic.fromJson(res["comics"][index], _key!),
            ),
            subData: res["next"],
          );
        } catch (e, s) {
          Log.error("Network", "$e\n$s");
          return Res.error(e.toString());
        }
      };
    }

    return SearchPageData(options, loadPage, loadNext);
  }

  FavoriteData? _loadFavoriteData() {
    if (!_checkExists("favorites")) return null;

    final bool multiFolder = _getValue("favorites.multiFolder");
    final bool? isOldToNewSort = _getValue("favorites.isOldToNewSort");
    final bool? singleFolderForSingleComic = _getValue(
      "favorites.singleFolderForSingleComic",
    );

    Future<Res<T>> retryZone<T>(Future<Res<T>> Function() func) async {
      if (!ComicSource.find(_key!)!.isLogged) {
        return const Res.error("Not login");
      }
      var res = await func();
      if (res.error && res.errorMessage!.contains("Login expired")) {
        var reLoginRes = await ComicSource.find(_key!)!.reLogin();
        if (!reLoginRes) {
          return const Res.error("Login expired and re-login failed");
        } else {
          return func();
        }
      }
      return res;
    }

    Future<Res<bool>> addOrDelFavFunc(
      String comicId,
      String folderId,
      bool isAdding,
      String? favId,
    ) async {
      func() async {
        try {
          await JsEngine().runCode("""
            ComicSource.sources.$_key.favorites.addOrDelFavorite(
              ${jsonEncode(comicId)}, ${jsonEncode(folderId)}, ${jsonEncode(isAdding)})
          """);
          return const Res(true);
        } catch (e, s) {
          Log.error("Network", "$e\n$s");
          return Res<bool>.error(e.toString());
        }
      }

      return retryZone(func);
    }

    Future<Res<List<Comic>>> Function(int page, [String? folder])? loadComic;

    Future<Res<List<Comic>>> Function(String? next, [String? folder])? loadNext;

    if (_checkExists("favorites.loadComics")) {
      loadComic = (int page, [String? folder]) async {
        Future<Res<List<Comic>>> func() async {
          try {
            var res = await JsEngine().runCode("""
            ComicSource.sources.$_key.favorites.loadComics(
              ${jsonEncode(page)}, ${jsonEncode(folder)})
          """);
            return Res(
              List.generate(
                res["comics"].length,
                (index) => Comic.fromJson(res["comics"][index], _key!),
              ),
              subData: res["maxPage"],
            );
          } catch (e, s) {
            Log.error("Network", "$e\n$s");
            return Res.error(e.toString());
          }
        }

        return retryZone(func);
      };
    }

    if (_checkExists("favorites.loadNext")) {
      loadNext = (String? next, [String? folder]) async {
        Future<Res<List<Comic>>> func() async {
          try {
            var res = await JsEngine().runCode("""
            ComicSource.sources.$_key.favorites.loadNext(
              ${jsonEncode(next)}, ${jsonEncode(folder)})
          """);
            return Res(
              List.generate(
                res["comics"].length,
                (index) => Comic.fromJson(res["comics"][index], _key!),
              ),
              subData: res["next"],
            );
          } catch (e, s) {
            Log.error("Network", "$e\n$s");
            return Res.error(e.toString());
          }
        }

        return retryZone(func);
      };
    }

    Future<Res<Map<String, String>>> Function([String? comicId])? loadFolders;

    Future<Res<bool>> Function(String name)? addFolder;

    Future<Res<bool>> Function(String key)? deleteFolder;

    if (multiFolder) {
      loadFolders = ([String? comicId]) async {
        Future<Res<Map<String, String>>> func() async {
          try {
            var res = await JsEngine().runCode("""
            ComicSource.sources.$_key.favorites.loadFolders(${jsonEncode(comicId)})
          """);
            List<String>? subData;
            if (res["favorited"] != null) {
              subData = List.from(res["favorited"]);
            }
            return Res(Map.from(res["folders"]), subData: subData);
          } catch (e, s) {
            Log.error("Network", "$e\n$s");
            return Res.error(e.toString());
          }
        }

        return retryZone(func);
      };
      if (_checkExists("favorites.addFolder")) {
        addFolder = (name) async {
          try {
            await JsEngine().runCode("""
            ComicSource.sources.$_key.favorites.addFolder(${jsonEncode(name)})
          """);
            return const Res(true);
          } catch (e, s) {
            Log.error("Network", "$e\n$s");
            return Res.error(e.toString());
          }
        };
      }
      if (_checkExists("favorites.deleteFolder")) {
        deleteFolder = (key) async {
          try {
            await JsEngine().runCode("""
            ComicSource.sources.$_key.favorites.deleteFolder(${jsonEncode(key)})
          """);
            return const Res(true);
          } catch (e, s) {
            Log.error("Network", "$e\n$s");
            return Res.error(e.toString());
          }
        };
      }
    }

    return FavoriteData(
      key: _key!,
      title: _name!,
      multiFolder: multiFolder,
      loadComic: loadComic,
      loadNext: loadNext,
      loadFolders: loadFolders,
      addFolder: addFolder,
      deleteFolder: deleteFolder,
      addOrDelFavorite: addOrDelFavFunc,
      isOldToNewSort: isOldToNewSort,
      singleFolderForSingleComic: singleFolderForSingleComic ?? false,
    );
  }

}
