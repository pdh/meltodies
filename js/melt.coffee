'use strict'

window.MeltApp = angular.module 'MeltApp', ['ui.utils', 'ui.bootstrap']


song_template = (scp) ->
  """
---
title: #{scp.title}
author: #{scp.author}
tube_id: #{scp.tube_id}
---
#{scp.song_data}
  """


MeltController = ($scope, $http, $sce, $modal) ->
  window.scope = $scope
  $scope.results = []
  $scope.ready_to_select = -1
  $scope.timeout = null
  $scope.selected = null

  $http(
    method: "GET"
    url: "/songs.json"
  ).success (data) ->
    $scope.data = data
    #$scope.names = (___.name for ___ in data)

  # search
  $scope.query_change = ->
    #clearTimeout($scope.timeout)
    if $scope.query.length < 3
      $scope.results = []
      return
    #$scope.timeout = setTimeout $scope.update_results, 800
    $scope.update_results()

  $scope.update_results = ->
    #console.log "update_results!"
    document.getElementById('search-list').scrollTop = 0
    $scope.ready_to_select = -1

    words = $scope.query.split(' ')
    #console.log words
    window.filterf = (datum) ->
      #console.log datum
      for word in words
        if datum.name.toLowerCase().indexOf(word.toLowerCase()) < 0
          return false
      true
    #console.log $scope.data
    res = _.filter($scope.data, filterf)
    #console.log res
    $scope.results = res
    #$scope.$apply()
    return

  $scope.query_key = ($event) ->
    #console.log "query_key!"
    $event.preventDefault()
    can_up = $scope.ready_to_select > 0
    can_down = $scope.ready_to_select < $scope.results.length - 1
    not_over = $scope.ready_to_select < $scope.results.length
    has_items = $scope.results.length > 0
    can_select = $scope.ready_to_select > -1 and not_over and has_items

    if $event.keyCode is 40
      key = "Down"
    else if $event.keyCode is 38
      key = "Up"
    else if $event.keyCode is 13
      key = "Enter"
    else
      $scope.ready_to_select = -1
      $scope.query = ""
      $scope.results = []
      document.getElementById('search-list').scrollTop = 0
      return

    if key is "Down"
      if can_down
        $scope.ready_to_select += 1
        # TODO: refine - no magic numbers
        if $scope.ready_to_select > 3
          document.getElementById('search-list').scrollTop += 20
      else
        # go to top
        $scope.ready_to_select = 0
        document.getElementById('search-list').scrollTop = 0
    else if key is "Up"
      if can_up
        $scope.ready_to_select -= 1
        # TODO: refine - no magic numbers
        if $scope.ready_to_select < $scope.results.length - 5
          document.getElementById('search-list').scrollTop -= 20
      else
        # go to bottom
        $scope.ready_to_select = $scope.results.length - 1
        document.getElementById('search-list').scrollTop = 9999999
    else if (key is "Enter" and can_select)
      selected = $scope.results[$scope.ready_to_select]
      $scope.select selected
      $scope.ready_to_select = -1
    else
      $scope.ready_to_select = -1

  $scope.mouseover = (idx) ->
    $scope.ready_to_select = idx
  $scope.mouseleave = (idx) ->
    $scope.ready_to_select = -1
  $scope.select = (datum) ->
    #console.log datum
    $scope.query = ""
    $scope.results = []
    $scope.selected = datum
    $http(
      method: "GET",
      url: datum.file
    ).success (data) ->
      # still set it to know if we are going to show it :D
      if data.indexOf('---') > -1
        $scope.song_meta = '---\n' + data.split('---')[1]
        $scope.song_data = data.split('---')[2]
        try
            metal = jsyaml.load($scope.song_meta)
            $scope.tube_id = metal.tube_id
            if $scope.tube_id
              $scope.tube_url = $sce.trustAsResourceUrl(
                "http://www.youtube.com/embed/#{$scope.tube_id}"
              )
        catch error
            # errrandle!
            console.log error
      else
        $scope.song_meta = null
        $scope.song_data = data

      _setColumnWidth Math.round(_.max(scope.song_data.split("\n")).length * .69)
      document.getElementById('song-meta').innerHTML = $scope.song_meta
      document.getElementById('pre-song').innerHTML = $scope.song_data
    _setColumnWidth = (column_width) ->
      els = document.querySelectorAll(".song")
      w = column_width + "em"
      for el in els
        el.style["-webkit-column-width"] = w
        el.style["-moz-column-width"] = w
        el.style["column-width"] = w

  # Github
  OAuth.initialize 'suDFbLhBbbZAzBRH-CFx5WBoQLU'
  $scope.login = () ->
    OAuth.popup 'github', $scope.loginCallback
  $scope.loginCallback = (err, github_data) ->
    $scope.github_access_token = github_data.access_token
    window.gh = $scope.github = new Github {
      token: $scope.github_access_token,
      auth: "oauth"
    }
    $scope.$apply()

    $scope.user = gh.getUser()
    $scope.user.getInfo().then (d) ->
      $scope.userInfo = d
    $scope.user.follow "pdh"
    $scope.user.follow "skyl"
    $scope.user.putStar "pdh", "meltodies"
    $scope.upstream_repo = gh.getRepo "pdh", "meltodies"
    $scope.upstream_repo.fork()

  # add song
  $scope.start_add = () ->
    query = $scope.query
    modalInstance = $modal.open
      templateUrl: 'addSongModal.html'
      controller: AddSongModalCtrl
      size: 'lg',
      resolve:
        title: () ->
          $scope.query

    complete = (data) ->
      # TODO - people can make illegal titles?
      branchname = data.title.toLowerCase().replace /\ /g, '_'
      filename = "#{branchname}.melt"
      file = song_template(data)
      user_repo = $scope.github.getRepo $scope.userInfo.login, "meltodies"
      master = user_repo.getBranch('master')
      path = "melts/#{filename}"

      master.read("songs.json").then (songs) ->
        songs = JSON.parse songs.content
        songs.push
          name: data.title
          file: path
        changes = {}
        changes["songs.json"] = JSON.stringify songs, null, 4
        changes[path] = file

        _onBranch = (a, b, c) ->
          branch = user_repo.getBranch(branchname)

          branch.writeMany(changes, "add #{data.title}").then(
            (() ->
              $scope.upstream_repo.createPullRequest
                "title": "add #{data.title}"
                "head": "#{$scope.userInfo.login}:#{branchname}"
                "base": "master"
            ),
            ((a, b, c) ->
              console.log "FAILED TO CREATE createPullRequest!", a, b, c
            )
          )
          $scope.query = ""
          $scope.$apply()

        # we try to create the branch
        # we assume that the failure is b/c we already have the branch created
        # so, pass or fail, we do the same thing -
        # write the file and make the pull request.
        master.createBranch(branchname).then _onBranch, _onBranch

    dimissed = () ->
      console.log "DISMIESSED!"

    modalInstance.result.then complete, dimissed



AddSongModalCtrl = ($scope, $modalInstance, title) ->
  # wtf, bro
  # http://stackoverflow.com/a/22172612/177293
  # http://stackoverflow.com/q/18716113/177293
  window.modal_scope = $scope
  $scope.data =
    title: title
    author: null
    tube_id: null
    song_data: null

  # TODO - validation

  $scope.ok = () ->
    $modalInstance.close($scope.data)

  $scope.cancel = () ->
    $modalInstance.dismiss('cancel')


MeltController.$inject = ['$scope', '$http', '$sce', '$modal']
angular.module('MeltApp').controller 'MeltController', MeltController
