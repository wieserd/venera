part of 'comic_source.dart';

extension _ComicSourceParserComicDetails on ComicSourceParser {
  LoadComicFunc? _parseLoadComicFunc() {
    return (id) async {
      try {
        var res = await JsEngine().runCode("""
          ComicSource.sources.$_key.comic.loadInfo(${jsonEncode(id)})
        """);
        if (res is! Map<String, dynamic>) throw "Invalid data";
        res['comicId'] = id;
        res['sourceKey'] = _key;
        return Res(ComicDetails.fromJson(res));
      } catch (e, s) {
        Log.error("Network", "$e\n$s");
        return Res.error(e.toString());
      }
    };
  }

  LoadComicPagesFunc? _parseLoadComicPagesFunc() {
    return (id, ep) async {
      try {
        var res = await JsEngine().runCode("""
          ComicSource.sources.$_key.comic.loadEp(${jsonEncode(id)}, ${jsonEncode(ep)})
        """);
        return Res(List.from(res["images"]));
      } catch (e, s) {
        Log.error("Network", "$e\n$s");
        return Res.error(e.toString());
      }
    };
  }

  CommentsLoader? _parseCommentsLoader() {
    if (!_checkExists("comic.loadComments")) return null;
    return (id, subId, page, replyTo) async {
      try {
        var res = await JsEngine().runCode("""
          ComicSource.sources.$_key.comic.loadComments(
            ${jsonEncode(id)}, ${jsonEncode(subId)}, ${jsonEncode(page)}, ${jsonEncode(replyTo)})
        """);
        return Res(
          (res["comments"] as List).map((e) => Comment.fromJson(e)).toList(),
          subData: res["maxPage"],
        );
      } catch (e, s) {
        Log.error("Network", "$e\n$s");
        return Res.error(e.toString());
      }
    };
  }

  SendCommentFunc? _parseSendCommentFunc() {
    if (!_checkExists("comic.sendComment")) return null;
    return (id, subId, content, replyTo) async {
      Future<Res<bool>> func() async {
        try {
          await JsEngine().runCode("""
            ComicSource.sources.$_key.comic.sendComment(
              ${jsonEncode(id)}, ${jsonEncode(subId)}, ${jsonEncode(content)}, ${jsonEncode(replyTo)})
          """);
          return const Res(true);
        } catch (e, s) {
          Log.error("Network", "$e\n$s");
          return Res.error(e.toString());
        }
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
    };
  }

  ChapterCommentsLoader? _parseChapterCommentsLoader() {
    if (!_checkExists("comic.loadChapterComments")) return null;
    return (comicId, epId, page, replyTo) async {
      try {
        var res = await JsEngine().runCode("""
          ComicSource.sources.$_key.comic.loadChapterComments(
            ${jsonEncode(comicId)}, ${jsonEncode(epId)}, ${jsonEncode(page)}, ${jsonEncode(replyTo)})
        """);
        return Res(
          (res["comments"] as List).map((e) => Comment.fromJson(e)).toList(),
          subData: res["maxPage"],
        );
      } catch (e, s) {
        Log.error("Network", "$e\n$s");
        return Res.error(e.toString());
      }
    };
  }

  SendChapterCommentFunc? _parseSendChapterCommentFunc() {
    if (!_checkExists("comic.sendChapterComment")) return null;
    return (comicId, epId, content, replyTo) async {
      Future<Res<bool>> func() async {
        try {
          await JsEngine().runCode("""
            ComicSource.sources.$_key.comic.sendChapterComment(
              ${jsonEncode(comicId)}, ${jsonEncode(epId)}, ${jsonEncode(content)}, ${jsonEncode(replyTo)})
          """);
          return const Res(true);
        } catch (e, s) {
          Log.error("Network", "$e\n$s");
          return Res.error(e.toString());
        }
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
    };
  }

  GetImageLoadingConfigFunc? _parseImageLoadingConfigFunc() {
    if (!_checkExists("comic.onImageLoad")) {
      return null;
    }
    return (imageKey, comicId, ep) async {
      var res = JsEngine().runCode("""
          ComicSource.sources.$_key.comic.onImageLoad(
            ${jsonEncode(imageKey)}, ${jsonEncode(comicId)}, ${jsonEncode(ep)})
        """);
      if (res is Future) {
        return await res;
      }
      return res;
    };
  }

  GetThumbnailLoadingConfigFunc? _parseThumbnailLoadingConfigFunc() {
    if (!_checkExists("comic.onThumbnailLoad")) {
      return null;
    }
    return (imageKey) {
      var res = JsEngine().runCode("""
          ComicSource.sources.$_key.comic.onThumbnailLoad(${jsonEncode(imageKey)})
        """);
      if (res is! Map) {
        Log.error("Network", "function onThumbnailLoad return invalid data");
        throw "function onThumbnailLoad return invalid data";
      }
      return res as Map<String, dynamic>;
    };
  }

  ComicThumbnailLoader? _parseThumbnailLoader() {
    if (!_checkExists("comic.loadThumbnails")) {
      return null;
    }
    return (id, next) async {
      try {
        var res = await JsEngine().runCode("""
          ComicSource.sources.$_key.comic.loadThumbnails(${jsonEncode(id)}, ${jsonEncode(next)})
        """);
        return Res(List<String>.from(res['thumbnails']), subData: res['next']);
      } catch (e, s) {
        Log.error("Network", "$e\n$s");
        return Res.error(e.toString());
      }
    };
  }

  LikeOrUnlikeComicFunc? _parseLikeFunc() {
    if (!_checkExists("comic.likeComic")) {
      return null;
    }
    return (id, isLiking) async {
      try {
        await JsEngine().runCode("""
          ComicSource.sources.$_key.comic.likeComic(${jsonEncode(id)}, ${jsonEncode(isLiking)})
        """);
        return const Res(true);
      } catch (e, s) {
        Log.error("Network", "$e\n$s");
        return Res.error(e.toString());
      }
    };
  }

  VoteCommentFunc? _parseVoteCommentFunc() {
    if (!_checkExists("comic.voteComment")) {
      return null;
    }
    return (id, subId, commentId, isUp, isCancel) async {
      try {
        var res = await JsEngine().runCode("""
          ComicSource.sources.$_key.comic.voteComment(${jsonEncode(id)}, ${jsonEncode(subId)}, ${jsonEncode(commentId)}, ${jsonEncode(isUp)}, ${jsonEncode(isCancel)})
        """);
        return Res(res is num ? res.toInt() : 0);
      } catch (e, s) {
        Log.error("Network", "$e\n$s");
        return Res.error(e.toString());
      }
    };
  }

  LikeCommentFunc? _parseLikeCommentFunc() {
    if (!_checkExists("comic.likeComment")) {
      return null;
    }
    return (id, subId, commentId, isLiking) async {
      try {
        var res = await JsEngine().runCode("""
          ComicSource.sources.$_key.comic.likeComment(${jsonEncode(id)}, ${jsonEncode(subId)}, ${jsonEncode(commentId)}, ${jsonEncode(isLiking)})
        """);
        return Res(res is num ? res.toInt() : 0);
      } catch (e, s) {
        Log.error("Network", "$e\n$s");
        return Res.error(e.toString());
      }
    };
  }

  Map<String, Map<String, dynamic>> _parseSettings() {
    var value = _getValue("settings");
    if (value is Map) {
      var newMap = <String, Map<String, dynamic>>{};
      for (var e in value.entries) {
        if (e.key is! String) {
          continue;
        }
        var v = <String, dynamic>{};
        for (var e2 in e.value.entries) {
          if (e2.key is! String) {
            continue;
          }
          var v2 = e2.value;
          if (v2 is JSInvokable) {
            v2 = JSAutoFreeFunction(v2);
          }
          v[e2.key] = v2;
        }
        newMap[e.key] = v;
      }
      return newMap;
    }
    return {};
  }

  RegExp? _parseIdMatch() {
    if (!_checkExists("comic.idMatch")) {
      return null;
    }
    return RegExp(_getValue("comic.idMatch"));
  }

  Map<String, Map<String, String>>? _parseTranslation() {
    if (!_checkExists("translation")) {
      return null;
    }
    var data = _getValue("translation");
    var res = <String, Map<String, String>>{};
    for (var e in data.entries) {
      res[e.key] = Map<String, String>.from(e.value);
    }
    return res;
  }

  HandleClickTagEvent? _parseClickTagEvent() {
    if (!_checkExists("comic.onClickTag")) {
      return null;
    }
    return (namespace, tag) {
      var res = JsEngine().runCode("""
          ComicSource.sources.$_key.comic.onClickTag(${jsonEncode(namespace)}, ${jsonEncode(tag)})
        """);
      if (res is! Map) {
        return null;
      }
      var r = Map<String, dynamic>.from(res);
      r.removeWhere((key, value) => value == null);
      return PageJumpTarget.parse(_key!, r);
    };
  }

  TagSuggestionSelectFunc? _parseTagSuggestionSelectFunc() {
    if (!_checkExists("search.onTagSuggestionSelected")) {
      return null;
    }
    return (namespace, tag) {
      var res = JsEngine().runCode("""
          ComicSource.sources.$_key.search.onTagSuggestionSelected(
            ${jsonEncode(namespace)}, ${jsonEncode(tag)})
        """);
      return res is String ? res : "$namespace:$tag";
    };
  }

  LinkHandler? _parseLinkHandler() {
    if (!_checkExists("comic.link")) {
      return null;
    }
    List<String> domains = List.from(_getValue("comic.link.domains"));
    linkToId(String link) {
      var res = JsEngine().runCode("""
          ComicSource.sources.$_key.comic.link.linkToId(${jsonEncode(link)})
        """);
      return res as String?;
    }

    return LinkHandler(domains, linkToId);
  }

  StarRatingFunc? _parseStarRatingFunc() {
    if (!_checkExists("comic.starRating")) {
      return null;
    }
    return (id, rating) async {
      try {
        await JsEngine().runCode("""
          ComicSource.sources.$_key.comic.starRating(${jsonEncode(id)}, ${jsonEncode(rating)})
        """);
        return const Res(true);
      } catch (e, s) {
        Log.error("Network", "$e\n$s");
        return Res.error(e.toString());
      }
    };
  }

  ArchiveDownloader? _parseArchiveDownloader() {
    if (!_checkExists("comic.archive")) {
      return null;
    }
    return ArchiveDownloader(
      (cid) async {
        try {
          var res = await JsEngine().runCode("""
              ComicSource.sources.$_key.comic.archive.getArchives(${jsonEncode(cid)})
            """);
          return Res(
            (res as List).map((e) => ArchiveInfo.fromJson(e)).toList(),
          );
        } catch (e, s) {
          Log.error("Network", "$e\n$s");
          return Res.error(e.toString());
        }
      },
      (cid, aid) async {
        try {
          var res = await JsEngine().runCode("""
              ComicSource.sources.$_key.comic.archive.getDownloadUrl(${jsonEncode(cid)}, ${jsonEncode(aid)})
            """);
          return Res(res as String);
        } catch (e, s) {
          Log.error("Network", "$e\n$s");
          return Res.error(e.toString());
        }
      },
    );
  }
}
}
