// Generated by CoffeeScript 1.8.0
(function() {
  'use strict';
  var AddSongModalCtrl, MeltController, song_template, started, transition_search_input, youtube_iframe_template, _setColumnWidth;

  window.MeltApp = angular.module('MeltApp', ['ui.utils', 'ui.bootstrap', 'LocalStorageModule', 'contenteditable']);

  _setColumnWidth = function(column_width) {
    var el, els, w, _i, _len, _results;
    els = document.querySelectorAll(".song");
    w = column_width + "em";
    _results = [];
    for (_i = 0, _len = els.length; _i < _len; _i++) {
      el = els[_i];
      el.style["-webkit-column-width"] = w;
      el.style["-moz-column-width"] = w;
      _results.push(el.style["column-width"] = w);
    }
    return _results;
  };

  song_template = function(scp) {
    return "===\ntitle: " + scp.title + "\nversion: " + scp.version + "\nauthor: " + scp.author + "\nperformed_by: " + scp.performed_by + "\ntube_id: " + scp.tube_id + "\n===\n" + scp.song_data;
  };

  youtube_iframe_template = function(src) {
    return "<iframe id=\"ytplayer\" type=\"text/html\" width=\"213\" height=\"130\"\n    allowfullscreen=\"true\"\n    src=\"" + src + "\"\n    frameborder=\"0\"></iframe>";
  };

  started = false;

  transition_search_input = function(duration) {
    var s;
    if (duration == null) {
      duration = 100;
    }
    if (started) {
      return;
    }
    s = d3.select(".start");
    s.transition().duration(duration).style("margin-top", "1%");
    return started = true;
  };

  MeltController = function($scope, $http, $modal, $location, localStorageService) {
    var hydrate;
    window.lss = localStorageService;
    window.l = $location;
    if ($location.path()) {
      transition_search_input(0);
    }
    window.scope = $scope;
    $scope.results = [];
    $scope.ready_to_select = -1;
    $scope.timeout = null;
    $scope.selected = null;
    $http({
      method: "GET",
      url: "songs.json"
    }).success(function(songs_json) {
      $scope.songs_json = songs_json;
      localStorageService.set('songs_json', songs_json);
      return $scope.onLoad();
    }).error(function() {
      var songs_json;
      songs_json = localStorageService.get('songs_json');
      if (songs_json != null) {
        $scope.songs_json = songs_json;
        localStorageService.bind($scope, 'songs_json', songs_json);
      }
      return $scope.onLoad();
    });
    $scope.onLoad = function() {
      var access_token, path, title, version, _ref;
      document.getElementById("search").focus();
      path = $location.path().split('/')[1];
      if (path !== void 0) {
        _ref = path.split('::'), title = _ref[0], version = _ref[1];
        $scope.select_version(version, title);
      }
      access_token = localStorageService.get('github_access_token');
      if (access_token != null) {
        return $scope.establish_github(access_token);
      }
    };
    $scope.update_results = function() {
      var a, a_search, authorstrs, authstr, filtered_words, res, w, words;
      if (!started) {
        transition_search_input();
      }
      document.getElementById('search-list').scrollTop = 0;
      $scope.ready_to_select = -1;
      words = $scope.query.split(' ');
      authstr = "author:";
      filtered_words = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = words.length; _i < _len; _i++) {
          w = words[_i];
          if (!(w.substring(0, authstr.length) === authstr)) {
            _results.push(w);
          }
        }
        return _results;
      })();
      authorstrs = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = words.length; _i < _len; _i++) {
          w = words[_i];
          if (w.substring(0, authstr.length) === authstr) {
            _results.push(w);
          }
        }
        return _results;
      })();
      a_search = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = authorstrs.length; _i < _len; _i++) {
          a = authorstrs[_i];
          _results.push(a.split(":")[1]);
        }
        return _results;
      })();
      window.filterf = function(datum) {
        var author_word, word, _i, _j, _len, _len1;
        for (_i = 0, _len = filtered_words.length; _i < _len; _i++) {
          word = filtered_words[_i];
          if (datum.title.toLowerCase().indexOf(word.toLowerCase()) < 0) {
            return false;
          }
        }
        if (datum.author != null) {
          for (_j = 0, _len1 = a_search.length; _j < _len1; _j++) {
            author_word = a_search[_j];
            if (datum.author.toLowerCase().indexOf(author_word.toLowerCase()) < 0) {
              return false;
            }
          }
        }
        return true;
      };
      res = _.filter($scope.songs_json, filterf);
      $scope.results = res;
    };
    $scope.query_key = function($event) {
      var can_down, can_select, can_up, has_items, key, not_over, selected;
      $event.preventDefault();
      can_up = $scope.ready_to_select > 0;
      can_down = $scope.ready_to_select < $scope.results.length - 1;
      not_over = $scope.ready_to_select < $scope.results.length;
      has_items = $scope.results.length > 0;
      can_select = $scope.ready_to_select > -1 && not_over && has_items;
      if ($event.keyCode === 40) {
        key = "Down";
      } else if ($event.keyCode === 38) {
        key = "Up";
      } else if ($event.keyCode === 13) {
        key = "Enter";
      } else {
        $scope.ready_to_select = -1;
        $scope.results = [];
        document.getElementById('search-list').scrollTop = 0;
        return;
      }
      if (key === "Down") {
        if (can_down) {
          $scope.ready_to_select += 1;
          if ($scope.ready_to_select > 3) {
            return document.getElementById('search-list').scrollTop += 25;
          }
        } else {
          $scope.ready_to_select = 0;
          return document.getElementById('search-list').scrollTop = 0;
        }
      } else if (key === "Up") {
        if (can_up) {
          $scope.ready_to_select -= 1;
          if ($scope.ready_to_select < $scope.results.length - 3) {
            return document.getElementById('search-list').scrollTop -= 25;
          }
        } else {
          $scope.ready_to_select = $scope.results.length - 1;
          return document.getElementById('search-list').scrollTop = 9999999;
        }
      } else if (key === "Enter" && can_select) {
        selected = $scope.results[$scope.ready_to_select];
        $scope.select(selected, true);
        return $scope.ready_to_select = -1;
      } else if (key === "Enter" && !can_select) {
        return $scope.select_random_song();
      } else {
        return $scope.ready_to_select = -1;
      }
    };
    $scope.mouseover = function(idx) {
      return $scope.ready_to_select = idx;
    };
    $scope.mouseleave = function(idx) {
      return $scope.ready_to_select = -1;
    };
    hydrate = function(song_text) {
      var metal, ytel;
      $scope.song_meta = song_text.split('===')[1].trim();
      $scope.song_data = song_text.split('===')[2].trim();
      metal = jsyaml.load($scope.song_meta);
      $scope.tube_id = metal.tube_id;
      if ($scope.tube_id) {
        ytel = document.getElementById("tube-container");
        ytel.innerHTML = youtube_iframe_template("http://www.youtube.com/embed/" + $scope.tube_id);
      }
      if (metal.title.toLowerCase() !== $location.path().toLowerCase()) {
        $location.path("" + metal.title + "::" + metal.version);
      }
      _setColumnWidth(Math.round(_.max($scope.song_data.split("\n"), function(i) {
        return i.length;
      }).length * 0.618 * (window.devicePixelRatio || 1)));
      document.getElementById('song-meta').innerHTML = $scope.song_meta;
      return $scope.song_edited = false;
    };
    $scope.select = function(datum, reset_results) {
      var local_override, override_key, override_text;
      if (reset_results == null) {
        reset_results = true;
      }
      if ($scope.selected !== null) {
        if ($scope.selected.version === datum.version) {
          return;
        }
      }
      transition_search_input();
      if (reset_results) {
        $scope.query = "";
        $scope.results = [];
      }
      $scope.selected = datum;
      override_key = "override::" + datum.file;
      local_override = localStorageService.get(override_key);
      if (local_override != null) {
        override_text = localStorageService.get(datum.file);
        hydrate(override_text);
      }
      return $http({
        method: "GET",
        url: datum.file
      }).success(function(song_text) {
        if (local_override != null) {
          if (song_text === override_text) {
            localStorageService.remove(override_key);
          }
          return;
        }
        hydrate(song_text);
        return localStorageService.set(datum.version, song_text);
      }).error(function() {
        var song_text;
        song_text = localStorageService.get(datum.file);
        if (song_text != null) {
          return hydrate(song_text);
        }
      });
    };
    $scope.select_random_song = function() {
      var item, list;
      if (!started) {
        transition_search_input();
      }
      if ($scope.results.length > 0) {
        list = $scope.results;
      } else {
        list = $scope.songs_json;
      }
      item = list[Math.floor(Math.random() * list.length)];
      $scope.select(item, false);
      return document.getElementById("search").focus();
    };
    $scope.select_version = function(version, title, reset_results) {
      var d, existing, _i, _len, _ref;
      if (reset_results == null) {
        reset_results = true;
      }
      existing = localStorageService.get(version);
      if (existing != null) {
        hydrate(existing);
        return;
      }
      if ((version != null) && ($scope.songs_json != null)) {
        _ref = $scope.songs_json;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          d = _ref[_i];
          if (d.version === version) {
            $scope.select(d, reset_results);
            return;
          }
        }
      }
      return $scope.select_title(title, reset_results);
    };
    $scope.select_title = function(title, reset_results) {
      var d, _i, _len, _ref;
      if (reset_results == null) {
        reset_results = true;
      }
      if (title !== void 0 && $scope.songs_json !== void 0) {
        _ref = $scope.songs_json;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          d = _ref[_i];
          if (d.title.toLowerCase() === title.toLowerCase()) {
            $scope.select(d, reset_results);
            return;
          }
        }
      }
    };
    $scope.$on('$locationChangeSuccess', function(scope, next, current) {
      var path, title, version, _ref;
      path = $location.path().split('/')[1];
      if (path !== void 0) {
        _ref = path.split('::'), title = _ref[0], version = _ref[1];
        return $scope.select_version(version, title, false);
      }
    });
    $scope.song_edited = false;
    $scope.edit_song = function() {
      var display, el, prev_song_data;
      $scope.song_edited = false;
      el = document.getElementById('pre-song');
      $scope.song_data = $scope.song_data.replace(/<\/?[^>]+(>|$)/g, "");
      prev_song_data = localStorageService.get($scope.selected.file).split("===")[2].trim();
      window.diff = JsDiff.diffChars(prev_song_data, el.innerHTML);
      display = document.getElementById("display");
      display.innerHTML = "";
      return diff.forEach(function(part) {
        var color, span;
        span = document.createElement('span');
        color = 'inherit';
        if (part.added) {
          color = '#dfd';
          $scope.song_edited = true;
          span.style['font-weight'] = "bold";
        }
        if (part.removed) {
          color = '#fdd';
          $scope.song_edited = true;
        }
        span.style["background-color"] = color;
        span.appendChild(document.createTextNode(part.value));
        return display.appendChild(span);
      });
    };
    $scope.keypress_song = function(ev) {
      var newline, range, selection;
      selection = window.getSelection();
      range = selection.getRangeAt(0);
      newline = document.createTextNode('\n');
      range.deleteContents();
      range.insertNode(newline);
      range.setStartAfter(newline);
      range.setEndAfter(newline);
      range.collapse(false);
      selection.removeAllRanges();
      selection.addRange(range);
      $scope.edit_song();
      ev.preventDefault();
      return ev.returnValue = false;
    };
    $scope.establish_github = function(access_token) {
      $scope.github_access_token = access_token;
      window.gh = $scope.github = new Github({
        token: $scope.github_access_token,
        auth: "oauth"
      });
      $scope.user = $scope.github.getUser();
      $scope.user.getInfo().then(function(d) {
        return $scope.userInfo = d;
      });
      $scope.user.follow("pdh");
      $scope.user.follow("skyl");
      $scope.user.putStar("pdh", "meltodies");
      $scope.upstream_repo = $scope.github.getRepo("pdh", "meltodies");
      return $scope.upstream_repo.fork();
    };
    OAuth.initialize('suDFbLhBbbZAzBRH-CFx5WBoQLU');
    $scope.login = function() {
      return OAuth.popup('github', $scope.loginCallback);
    };
    $scope.loginCallback = function(err, github_data) {
      localStorageService.set('github_access_token', github_data.access_token);
      $scope.establish_github(github_data.access_token);
      return $scope.$apply();
    };
    $scope.start_add = function() {
      var complete, dimissed, modalInstance, query;
      query = $scope.query;
      modalInstance = $modal.open({
        templateUrl: 'addSongModal.html',
        controller: AddSongModalCtrl,
        size: 'lg',
        resolve: {
          title: function() {
            return $scope.query;
          }
        }
      });
      complete = function(data) {
        var branchname, changes, file, filename, master, path, user_repo, version, _onBranch;
        branchname = data.title.toLowerCase().replace(/\ /g, '_');
        version = CryptoJS.MD5(data.song_data.trim()).toString();
        data["version"] = version;
        filename = "" + branchname + "_" + version + ".melt";
        file = song_template(data);
        user_repo = $scope.github.getRepo($scope.userInfo.login, "meltodies");
        master = user_repo.getBranch('master');
        path = "melts/" + filename;
        changes = {};
        changes[path] = file;
        _onBranch = function() {
          var branch;
          branch = user_repo.getBranch(branchname);
          branch.writeMany(changes, "add " + data.title).then((function() {
            return $scope.upstream_repo.createPullRequest({
              "title": "add " + data.title,
              "head": "" + $scope.userInfo.login + ":" + branchname,
              "base": "master"
            });
          }), (function(a, b, c) {
            return console.log("FAILED TO CREATE createPullRequest!", a, b, c);
          }));
          $scope.query = "";
          return $scope.$apply();
        };
        return master.createBranch(branchname).then(_onBranch, _onBranch);
      };
      dimissed = function() {
        return console.log("DISMIESSED!");
      };
      return modalInstance.result.then(complete, dimissed);
    };
    return $scope.edit_song_pr = function() {
      var branchname, changes, context, file_text, filename, master, new_version, old_filepath, path, user_repo, _onBranch;
      branchname = $scope.selected.title.toLowerCase().replace(/\ /g, '_');
      new_version = CryptoJS.MD5($scope.song_data.trim()).toString();
      old_filepath = "melts/" + branchname + "_" + $scope.selected.version + ".melt";
      filename = "" + branchname + "_" + new_version + ".melt";
      context = {
        title: $scope.selected.title,
        author: $scope.selected.author,
        version: new_version,
        performed_by: $scope.selected.performed_by,
        tube_id: $scope.selected.tube_id,
        song_data: $scope.song_data
      };
      file_text = song_template(context);
      changes = {};
      path = "melts/" + filename;
      changes[path] = file_text;
      user_repo = $scope.github.getRepo($scope.userInfo.login, "meltodies");
      master = user_repo.getBranch('master');
      _onBranch = function() {
        var branch, _remove_and_pr;
        branch = user_repo.getBranch(branchname);
        _remove_and_pr = function() {
          var _pr;
          _pr = function() {
            $scope.upstream_repo.createPullRequest({
              "title": "Edit " + context.title,
              "head": "" + $scope.userInfo.login + ":" + branchname,
              "base": "master"
            });
            hydrate(file_text);
            localStorageService.set("override::" + path, "please");
            localStorageService.set(path, file_text);
            $scope.song_edited = false;
            return $scope.$apply();
          };
          return branch.remove(old_filepath, "Remove " + old_filepath).then(_pr, _pr);
        };
        return branch.writeMany(changes, "Edit " + context.title).then(_remove_and_pr, _remove_and_pr);
      };
      return master.createBranch(branchname).then(_onBranch, _onBranch);
    };
  };

  AddSongModalCtrl = function($scope, $modalInstance, title) {
    window.modal_scope = $scope;
    $scope.data = {
      title: title,
      author: null,
      performed_by: null,
      tube_id: null,
      song_data: null
    };
    $scope.ok = function() {
      return $modalInstance.close($scope.data);
    };
    return $scope.cancel = function() {
      return $modalInstance.dismiss('cancel');
    };
  };

  MeltController.$inject = ['$scope', '$http', '$modal', '$location', 'localStorageService'];

  angular.module('MeltApp').controller('MeltController', MeltController);

}).call(this);
