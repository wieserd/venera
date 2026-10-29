part of 'comic_source.dart';

extension _ComicSourceParserExploreCategory on ComicSourceParser {
  List<ExplorePageData> _loadExploreData() {
    if (!_checkExists("explore")) {
      return const [];
    }
    var length = JsEngine().runCode("ComicSource.sources.$_key.explore.length");
    var pages = <ExplorePageData>[];
    for (int i = 0; i < length; i++) {
      final String title = _getValue("explore[$i].title");
      final String type = _getValue("explore[$i].type");
      Future<Res<List<ExplorePagePart>>> Function()? loadMultiPart;
      Future<Res<List<Comic>>> Function(int page)? loadPage;
      Future<Res<List<Comic>>> Function(String? next)? loadNext;
      Future<Res<List<Object>>> Function(int index)? loadMixed;
      if (type == "singlePageWithMultiPart") {
        loadMultiPart = () async {
          try {
            var res = await JsEngine().runCode(
              "ComicSource.sources.$_key.explore[$i].load()",
            );
            return Res(
              List.from(
                res.keys
                    .map(
                      (e) => ExplorePagePart(
                        e,
                        (res[e] as List)
                            .map<Comic>((e) => Comic.fromJson(e, _key!))
                            .toList(),
                        null,
                      ),
                    )
                    .toList(),
              ),
            );
          } catch (e, s) {
            Log.error("Data Analysis", "$e\n$s");
            return Res.error(e.toString());
          }
        };
      } else if (type == "multiPageComicList") {
        if (_checkExists("explore[$i].load")) {
          loadPage = (int page) async {
            try {
              var res = await JsEngine().runCode(
                "ComicSource.sources.$_key.explore[$i].load(${jsonEncode(page)})",
              );
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
          loadNext = (next) async {
            try {
              var res = await JsEngine().runCode(
                "ComicSource.sources.$_key.explore[$i].loadNext(${jsonEncode(next)})",
              );
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
      } else if (type == "multiPartPage") {
        loadMultiPart = () async {
          try {
            var res = await JsEngine().runCode(
              "ComicSource.sources.$_key.explore[$i].load()",
            );
            return Res(
              List.from(
                (res as List).map((e) {
                  return ExplorePagePart(
                    e['title'],
                    (e['comics'] as List).map((e) {
                      return Comic.fromJson(e, _key!);
                    }).toList(),
                    PageJumpTarget.parse(_key!, e['viewMore']),
                  );
                }),
              ),
            );
          } catch (e, s) {
            Log.error("Data Analysis", "$e\n$s");
            return Res.error(e.toString());
          }
        };
      } else if (type == 'mixed') {
        loadMixed = (index) async {
          try {
            var res = await JsEngine().runCode(
              "ComicSource.sources.$_key.explore[$i].load(${jsonEncode(index)})",
            );
            var list = <Object>[];
            for (var data in (res['data'] as List)) {
              if (data is List) {
                list.add(data.map((e) => Comic.fromJson(e, _key!)).toList());
              } else if (data is Map) {
                list.add(
                  ExplorePagePart(
                    data['title'],
                    (data['comics'] as List).map((e) {
                      return Comic.fromJson(e, _key!);
                    }).toList(),
                    data['viewMore'],
                  ),
                );
              }
            }
            return Res(list, subData: res['maxPage']);
          } catch (e, s) {
            Log.error("Network", "$e\n$s");
            return Res.error(e.toString());
          }
        };
      }
      pages.add(
        ExplorePageData(
          title,
          switch (type) {
            "singlePageWithMultiPart" =>
              ExplorePageType.singlePageWithMultiPart,
            "multiPartPage" => ExplorePageType.singlePageWithMultiPart,
            "multiPageComicList" => ExplorePageType.multiPageComicList,
            "mixed" => ExplorePageType.mixed,
            _ => throw ComicSourceParseException(
              "Unknown explore page type $type",
            ),
          },
          loadPage,
          loadNext,
          loadMultiPart,
          loadMixed,
        ),
      );
    }
    return pages;
  }

  CategoryData? _loadCategoryData() {
    var doc = _getValue("category");

    if (doc?["title"] == null) {
      return null;
    }

    final String title = doc["title"];
    final bool? enableRankingPage = doc["enableRankingPage"];

    var categoryParts = <BaseCategoryPart>[];

    for (var c in doc["parts"]) {
      if (c["categories"] != null && c["categories"] is! List) {
        continue;
      }
      List? categories = c["categories"];
      if (categories == null || categories[0] is Map) {
        // new format
        final String name = c["name"];
        final String type = c["type"];
        final cs = categories
            ?.map(
              (e) => CategoryItem(
                e['label'],
                PageJumpTarget.parse(_key!, e['target']),
              ),
            )
            .toList();
        if (type != "dynamic" && (cs == null || cs.isEmpty)) {
          continue;
        }
        if (type == "fixed") {
          categoryParts.add(FixedCategoryPart(name, cs!));
        } else if (type == "random") {
          categoryParts.add(
            RandomCategoryPart(name, cs!, c["randomNumber"] ?? 1),
          );
        } else if (type == "dynamic" && categories == null) {
          var loader = c["loader"];
          if (loader is! JSInvokable) {
            throw "DynamicCategoryPart loader must be a function";
          }
          categoryParts.add(
            DynamicCategoryPart(name, JSAutoFreeFunction(loader), _key!),
          );
        }
      } else {
        // old format
        final String name = c["name"];
        final String type = c["type"];
        final List<String> tags = List.from(c["categories"]);
        final String itemType = c["itemType"];
        List<String>? categoryParams = ListOrNull.from(c["categoryParams"]);
        final String? groupParam = c["groupParam"];
        if (groupParam != null) {
          categoryParams = List.filled(tags.length, groupParam);
        }
        var cs = <CategoryItem>[];
        for (int i = 0; i < tags.length; i++) {
          PageJumpTarget target;
          if (itemType == 'category') {
            target = PageJumpTarget(_key!, 'category', {
              "category": tags[i],
              "param": categoryParams?.elementAtOrNull(i),
            });
          } else if (itemType == 'search') {
            target = PageJumpTarget(_key!, 'search', {"keyword": tags[i]});
          } else if (itemType == 'search_with_namespace') {
            target = PageJumpTarget(_key!, 'search', {
              "keyword": "$name:$tags[i]",
            });
          } else {
            target = PageJumpTarget(_key!, itemType, null);
          }
          cs.add(CategoryItem(tags[i], target));
        }
        if (type == "fixed") {
          categoryParts.add(FixedCategoryPart(name, cs));
        } else if (type == "random") {
          categoryParts.add(
            RandomCategoryPart(name, cs, c["randomNumber"] ?? 1),
          );
        }
      }
    }

    return CategoryData(
      title: title,
      categories: categoryParts,
      enableRankingPage: enableRankingPage ?? false,
      key: title,
    );
  }

  CategoryComicsData? _loadCategoryComicsData() {
    if (!_checkExists("categoryComics")) return null;

    List<CategoryComicsOptions>? options;
    if (_checkExists("categoryComics.optionList")) {
      options = <CategoryComicsOptions>[];
      for (var element in _getValue("categoryComics.optionList") ?? []) {
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
          CategoryComicsOptions(
            element["label"] ?? "",
            map,
            List.from(element["notShowWhen"] ?? []),
            element["showWhen"] == null ? null : List.from(element["showWhen"]),
          ),
        );
      }
    }

    CategoryOptionsLoader? optionLoader;
    if (_checkExists("categoryComics.optionLoader")) {
      optionLoader = (category, param) async {
        try {
          dynamic res = JsEngine().runCode("""
          ComicSource.sources.$_key.categoryComics.optionLoader(
            ${jsonEncode(category)}, ${jsonEncode(param)})
        """);
          if (res is Future) {
            res = await res;
          }
          if (res is! List) {
            return Res.error(
              "Invalid data:\nExpected: List\nGot: ${res.runtimeType}",
            );
          }
          var options = <CategoryComicsOptions>[];
          for (var element in res) {
            if (element is! Map) {
              return Res.error(
                "Invalid option data:\nExpected: Map\nGot: ${element.runtimeType}",
              );
            }
            LinkedHashMap<String, String> map = LinkedHashMap<String, String>();
            for (var option in element["options"] ?? []) {
              if (option.isEmpty || !option.contains("-")) {
                continue;
              }
              var split = option.split("-");
              var key = split.removeAt(0);
              var value = split.join("-");
              map[key] = value;
            }
            options.add(
              CategoryComicsOptions(
                element["label"] ?? "",
                map,
                List.from(element["notShowWhen"] ?? []),
                element["showWhen"] == null
                    ? null
                    : List.from(element["showWhen"]),
              ),
            );
          }
          return Res(options);
        } catch (e) {
          Log.error("Data Analysis", "Failed to load category options.\n$e");
          return Res.error(e.toString());
        }
      };
    }

    RankingData? rankingData;
    if (_checkExists("categoryComics.ranking")) {
      var options = <String, String>{};
      for (var option in _getValue("categoryComics.ranking.options")) {
        if (option.isEmpty || !option.contains("-")) {
          continue;
        }
        var split = option.split("-");
        var key = split.removeAt(0);
        var value = split.join("-");
        options[key] = value;
      }
      Future<Res<List<Comic>>> Function(String option, int page)? load;
      Future<Res<List<Comic>>> Function(String option, String? next)?
      loadWithNext;
      if (_checkExists("categoryComics.ranking.load")) {
        load = (option, page) async {
          try {
            var res = await JsEngine().runCode("""
            ComicSource.sources.$_key.categoryComics.ranking.load(
              ${jsonEncode(option)}, ${jsonEncode(page)})
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
        loadWithNext = (option, next) async {
          try {
            var res = await JsEngine().runCode("""
            ComicSource.sources.$_key.categoryComics.ranking.loadWithNext(
              ${jsonEncode(option)}, ${jsonEncode(next)})
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
      rankingData = RankingData(options, load, loadWithNext);
    }

    if (options == null && optionLoader == null) {
      options = [];
    }

    return CategoryComicsData(
      options: options,
      optionsLoader: optionLoader,
      load: (category, param, options, page) async {
        try {
          var res = await JsEngine().runCode("""
              ComicSource.sources.$_key.categoryComics.load(
                ${jsonEncode(category)},
                ${jsonEncode(param)},
                ${jsonEncode(options)},
                ${jsonEncode(page)}
              )
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
      },
      rankingData: rankingData,
    );
  }

}
