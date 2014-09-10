// Generated by CoffeeScript 1.8.0
(function() {
  'use strict';
  var AddSongModalCtrl, MeltController, song_template, started, transition_search_input;

  window.MeltApp = angular.module('MeltApp', ['ui.utils', 'ui.bootstrap']);

  song_template = function(scp) {
    return "===\ntitle: " + scp.title + "\nauthor: " + scp.author + "\ntube_id: " + scp.tube_id + "\n===\n" + scp.song_data;
  };

  started = false;

  transition_search_input = function(duration) {
    var s;
    if (duration == null) {
      duration = 100;
    }
    s = d3.select(".start");
    s.transition().duration(duration).style("margin-top", "1%");
    return started = true;
  };

  MeltController = function($scope, $http, $sce, $modal, $location) {
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
      url: "/songs.json"
    }).success(function(data) {
      $scope.data = data;
      return $scope.onLoad();
    });
    $scope.onLoad = function() {
      var d, title, _i, _len, _ref, _results;
      document.getElementById("search").focus();
      title = $location.path().split('/')[1];
      if (title != null) {
        _ref = $scope.data;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          d = _ref[_i];
          if (d.title.toLowerCase() === title.toLowerCase()) {
            _results.push($scope.select(d));
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      }
    };
    $scope.update_results = function() {
      var res, words;
      if (!started) {
        transition_search_input();
      }
      document.getElementById('search-list').scrollTop = 0;
      $scope.ready_to_select = -1;
      words = $scope.query.split(' ');
      window.filterf = function(datum) {
        var word, _i, _len;
        for (_i = 0, _len = words.length; _i < _len; _i++) {
          word = words[_i];
          if (datum.title.toLowerCase().indexOf(word.toLowerCase()) < 0) {
            return false;
          }
        }
        return true;
      };
      res = _.filter($scope.data, filterf);
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
        $scope.query = "";
        $scope.results = [];
        document.getElementById('search-list').scrollTop = 0;
        return;
      }
      if (key === "Down") {
        if (can_down) {
          $scope.ready_to_select += 1;
          if ($scope.ready_to_select > 3) {
            return document.getElementById('search-list').scrollTop += 20;
          }
        } else {
          $scope.ready_to_select = 0;
          return document.getElementById('search-list').scrollTop = 0;
        }
      } else if (key === "Up") {
        if (can_up) {
          $scope.ready_to_select -= 1;
          if ($scope.ready_to_select < $scope.results.length - 5) {
            return document.getElementById('search-list').scrollTop -= 20;
          }
        } else {
          $scope.ready_to_select = $scope.results.length - 1;
          return document.getElementById('search-list').scrollTop = 9999999;
        }
      } else if (key === "Enter" && can_select) {
        selected = $scope.results[$scope.ready_to_select];
        $scope.select(selected);
        return $scope.ready_to_select = -1;
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
    $scope.select = function(datum) {
      var _setColumnWidth;
      $scope.query = "";
      $scope.results = [];
      $scope.selected = datum;
      $http({
        method: "GET",
        url: datum.file
      }).success(function(data) {
        var error, metal;
        if (data.indexOf('===') > -1) {
          $scope.song_meta = '---\n' + data.split('===')[1];
          $scope.song_data = data.split('===')[2];
          try {
            metal = jsyaml.load($scope.song_meta);
            $scope.tube_id = metal.tube_id;
            if ($scope.tube_id) {
              $scope.tube_url = $sce.trustAsResourceUrl("http://www.youtube.com/embed/" + $scope.tube_id);
            }
            if (metal.title.toLowerCase() !== $location.path().toLowerCase()) {
              $location.path(metal.title);
            }
          } catch (_error) {
            error = _error;
            console.log(error);
          }
        } else {
          $scope.song_meta = null;
          $scope.song_data = data;
        }
        $scope.song_data = $scope.song_data.trim();
        _setColumnWidth(Math.round(_.max($scope.song_data.split("\n")).length * 1.25));
        document.getElementById('song-meta').innerHTML = $scope.song_meta;
        return document.getElementById('pre-song').innerHTML = $scope.song_data;
      });
      return _setColumnWidth = function(column_width) {
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
    };
    OAuth.initialize('suDFbLhBbbZAzBRH-CFx5WBoQLU');
    $scope.login = function() {
      return OAuth.popup('github', $scope.loginCallback);
    };
    $scope.loginCallback = function(err, github_data) {
      console.log(err, github_data);
      $scope.github_access_token = github_data.access_token;
      window.gh = $scope.github = new Github({
        token: $scope.github_access_token,
        auth: "oauth"
      });
      $scope.$apply();
      $scope.user = gh.getUser();
      $scope.user.getInfo().then(function(d) {
        return $scope.userInfo = d;
      });
      $scope.user.follow("pdh");
      $scope.user.follow("skyl");
      $scope.user.putStar("pdh", "meltodies");
      $scope.upstream_repo = gh.getRepo("pdh", "meltodies");
      return $scope.upstream_repo.fork();
    };
    return $scope.start_add = function() {
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
        var branchname, changes, file, filename, master, path, user_repo, _onBranch;
        branchname = data.title.toLowerCase().replace(/\ /g, '_');
        filename = "" + branchname + ".melt";
        file = song_template(data);
        user_repo = $scope.github.getRepo($scope.userInfo.login, "meltodies");
        master = user_repo.getBranch('master');
        path = "melts/" + filename;
        changes = {};
        changes[path] = file;
        _onBranch = function(a, b, c) {
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
  };

  AddSongModalCtrl = function($scope, $modalInstance, title) {
    window.modal_scope = $scope;
    $scope.data = {
      title: title,
      author: null,
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

  MeltController.$inject = ['$scope', '$http', '$sce', '$modal', '$location'];

  angular.module('MeltApp').controller('MeltController', MeltController);

}).call(this);
