'use strict'

window.MeltApp = angular.module 'MeltApp', [
  'ui.utils', 'ui.bootstrap', 'LocalStorageModule', 'contenteditable',
  'angulartics', 'angulartics.google.analytics'
]


_setColumnWidth = (column_width) ->
  els = document.querySelectorAll(".song")
  w = column_width + "em"
  for el in els
    el.style["-webkit-column-width"] = w
    el.style["-moz-column-width"] = w
    el.style["column-width"] = w


song_template = (scp) ->
  """
===
title: #{scp.title}
version: #{scp.version}
author: #{scp.author}
performed_by: #{scp.performed_by}
tube_id: #{scp.tube_id}
===
#{scp.song_data}
  """


# so changing YT doesn't affect back button,
# we just destroy and replace
youtube_iframe_template = (src) ->
  """
<iframe id="ytplayer" type="text/html" width="213" height="130"
    allowfullscreen="true"
    src="#{src}?vq=small&hd=0"
    frameborder="0"></iframe>
  """

# search
started = false
transition_search_input = (duration=100) ->
  if started
    return
  s = d3.select(".start")
  # more duration once this gets worked out.
  # http://stackoverflow.com/q/25714744/177293
  s.transition().duration(duration)
      .style("margin-top", "1%")
  started = true


MeltController = ($scope, $http, $modal, $location, localStorageService, $analytics) ->
  window.lss = localStorageService
  window.l = $location
  window.analytics = $analytics
  if $location.path()
    transition_search_input 0
  window.scope = $scope
  $scope.results = []
  $scope.ready_to_select = -1
  $scope.timeout = null
  $scope.selected = null

  $http(
    method: "GET"
    url: "songs.json"
  ).success((songs_json) ->
    $scope.songs_json = songs_json
    localStorageService.set 'songs_json', songs_json
    $scope.onLoad()
  ).error(() ->
    # maybe we are offline or sth.
    # try to fallback to localStorage
    songs_json = localStorageService.get 'songs_json'
    if songs_json?
      $scope.songs_json = songs_json
      localStorageService.bind $scope, 'songs_json', songs_json
    $scope.onLoad()
  )

  $scope.onLoad = () ->
    # called when songs.json == data comes back
    document.getElementById("search").focus()
    # angular way to get path without / ?
    path = $location.path().split('/')[1]
    if path isnt undefined
      [title, version] = path.split('::')
      $scope.select_version version, title
    access_token = localStorageService.get 'github_access_token'
    if access_token?
      $scope.establish_github access_token

  $scope.update_results = ->
    if not started
      transition_search_input()

    document.getElementById('search-list').scrollTop = 0
    $scope.ready_to_select = -1

    words = $scope.query.split(' ')
    #console.log "start", words
    authstr = "author:"
    filtered_words = (w for w in words when (not (w.substring(0, authstr.length) is authstr)))
    authorstrs = (w for w in words when (w.substring(0, authstr.length) is authstr))
    a_search = (a.split(":")[1] for a in authorstrs)
    #console.log "filtered", filtered_words
    #console.log "authors", a_search
    window.filterf = (datum) ->
      for word in filtered_words
        if datum.title.toLowerCase().indexOf(word.toLowerCase()) < 0
          return false
      if datum.author?
        for author_word in a_search
          if datum.author.toLowerCase().indexOf(author_word.toLowerCase()) < 0
            return false
      true
    res = _.filter($scope.songs_json, filterf)
    $scope.results = res
    return

  $scope.query_key = ($event) ->
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
      # ESC
      $scope.ready_to_select = -1
      # keep the query though?
      #$scope.query = ""
      $scope.results = []
      document.getElementById('search-list').scrollTop = 0
      return

    if key is "Down"
      if can_down
        $scope.ready_to_select += 1
        # TODO: refine - no magic numbers
        if $scope.ready_to_select > 3
          document.getElementById('search-list').scrollTop += 25
      else
        # go to top
        $scope.ready_to_select = 0
        document.getElementById('search-list').scrollTop = 0
    else if key is "Up"
      if can_up
        $scope.ready_to_select -= 1
        # TODO: refine - no magic numbers
        if $scope.ready_to_select < $scope.results.length - 3
          document.getElementById('search-list').scrollTop -= 25
      else
        # go to bottom
        $scope.ready_to_select = $scope.results.length - 1
        document.getElementById('search-list').scrollTop = 9999999
    else if (key is "Enter" and can_select)
      selected = $scope.results[$scope.ready_to_select]
      $scope.select selected, true
      $scope.ready_to_select = -1
    else if (key is "Enter" and not can_select)
      $scope.select_random_song()
    else
      $scope.ready_to_select = -1

  $scope.mouseover = (idx) ->
    $scope.ready_to_select = idx
  $scope.mouseleave = (idx) ->
    $scope.ready_to_select = -1

  hydrate = (song_text) ->
    #console.log song_text
    # Takes the entire file as a string.
    # we assume that the song is in the correct format
    $scope.song_meta = song_text.split('===')[1].trim()
    $scope.song_data = song_text.split('===')[2].trim()
    metal = jsyaml.load($scope.song_meta)
    $scope.tube_id = metal.tube_id
    if $scope.tube_id
      # we have to replace the iframe so it doesn't mess up
      # our back button hotness.
      ytel = document.getElementById("tube-container")
      ytel.innerHTML = youtube_iframe_template(
        "http://www.youtube.com/embed/#{$scope.tube_id}"
      )
    if metal.title.toLowerCase() isnt $location.path().toLowerCase()
      $location.path "#{metal.title}::#{metal.version}"

    # point
    $analytics.pageTrack $location.path()
    _setColumnWidth Math.round(
      _.max(
        $scope.song_data.split("\n"),
        (i) -> i.length
      ).length * 0.618 * (window.devicePixelRatio || 1)
    )
    document.getElementById('song-meta').innerHTML = $scope.song_meta
    $scope.song_edited = false

  $scope.select = (datum, reset_results=true) ->
    if $scope.selected isnt null
      if $scope.selected.version == datum.version
        return

    transition_search_input()
    if reset_results
      $scope.query = ""
      $scope.results = []
    $scope.selected = datum

    # gets set in the PR
    override_key = "override::#{datum.file}"
    local_override = localStorageService.get override_key
    if local_override?
      override_text = localStorageService.get datum.file
      hydrate override_text

    $http(
      method: "GET",
      url: datum.file
    ).success((song_text) ->
      # keep the override, but remove the override
      # if the changes have been merged.
      if local_override?
        if song_text is override_text
          localStorageService.remove override_key
        return
      hydrate song_text
      localStorageService.set datum.version, song_text
    ).error(()->
      song_text = localStorageService.get datum.file
      if song_text?
        hydrate song_text
    )

  $scope.select_random_song = () ->
    if not started
      transition_search_input()
    # pick randomly out of search results, if we have some
    # Do this more elegantly in idiomatic coffee
    if $scope.results.length > 0
      list = $scope.results
    else
      list = $scope.songs_json
    item = list[Math.floor(Math.random() * list.length)]
    # don't reset the search
    $scope.select item, false
    document.getElementById("search").focus()

  get_data_from_version = (version) ->
    if version? and $scope.songs_json?
      for d in $scope.songs_json
        if d.version == version
          return d

  $scope.select_version = (version, title, reset_results=true) ->
    d = get_data_from_version version
    existing = localStorageService.get version
    if existing? and d?
      hydrate existing
      $scope.selected = d
      return
    if d?
      $scope.select d, reset_results
      return
    # fallback to title
    $scope.select_title title, reset_results

  $scope.select_title = (title, reset_results=true) ->
    if title isnt undefined and $scope.songs_json isnt undefined
      for d in $scope.songs_json
        if d.title.toLowerCase() == title.toLowerCase()
          $scope.select d, reset_results
          # just select the first match
          # TODO - versions?
          return

  $scope.$on '$locationChangeSuccess', (scope, next, current) ->
    path = $location.path().split('/')[1]
    if path isnt undefined
      [title, version] = path.split('::')
      $scope.select_version version, title, false






  $scope.song_edited = false
  $scope.edit_song = () ->

    $scope.song_edited = false
    el = document.getElementById('pre-song')
    # subtle update bugs .. make sure that we don't have any stray <br>
    $scope.song_data = $scope.song_data.replace(/<\/?[^>]+(>|$)/g, "")

    prev_song_data = localStorageService.get($scope.selected.version).split("===")[2].trim()
    window.diff = JsDiff.diffChars prev_song_data, el.innerHTML
    display = document.getElementById "display"
    display.innerHTML = ""
    diff.forEach (part) ->
      # green for additions, red for deletions
      span = document.createElement('span')
      color = 'inherit'
      if part.added
        color = '#dfd'  # github diff green
        $scope.song_edited = true
        span.style['font-weight'] = "bold"
      if part.removed
        color = '#fdd'
        $scope.song_edited = true
      span.style["background-color"] = color
      span.appendChild document.createTextNode part.value
      display.appendChild span
  $scope.keypress_song = (ev) ->
    # only on enter
    # http://stackoverflow.com/q/23974533/177293
    selection = window.getSelection()
    range = selection.getRangeAt(0)
    newline = document.createTextNode('\n')
    range.deleteContents()
    range.insertNode(newline)
    range.setStartAfter(newline)
    range.setEndAfter(newline)
    range.collapse(false)
    selection.removeAllRanges()
    selection.addRange(range)
    $scope.edit_song()
    ev.preventDefault()
    ev.returnValue = false



  # Github

  $scope.establish_github = (access_token) ->
    $scope.github_access_token = access_token
    window.gh = $scope.github = new Github {
      token: $scope.github_access_token,
      auth: "oauth"
    }
    $scope.user = $scope.github.getUser()
    $scope.user.getInfo().then (d) ->
      $scope.userInfo = d
    $scope.user.follow "pdh"
    $scope.user.follow "skyl"
    $scope.user.putStar "pdh", "meltodies"
    $scope.upstream_repo = $scope.github.getRepo "pdh", "meltodies"
    $scope.upstream_repo.fork()

    # TODO - need to make sure that our master
    # is merged with upstream so that we can minimize conflicts
    # and, when we edit
    # http://stackoverflow.com/q/25859077/177293
    # For now, the solution is suck
    # delete your fork.
    # logout of github manually -
    # js console
    # > lss.set("github_access_token")
    # the repos need to be synced b/c, when we edit, we delete
    # the older version (rename the file)


  OAuth.initialize 'suDFbLhBbbZAzBRH-CFx5WBoQLU'
  $scope.login = () ->
    OAuth.popup 'github', $scope.loginCallback
  $scope.loginCallback = (err, github_data) ->
    #console.log err, github_data
    localStorageService.set 'github_access_token', github_data.access_token
    $scope.establish_github github_data.access_token
    $scope.$apply()

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
      version = CryptoJS.MD5(data.song_data.trim()).toString()
      data["version"] = version
      filename = "#{branchname}_#{version}.melt"
      file = song_template(data)
      user_repo = $scope.github.getRepo $scope.userInfo.login, "meltodies"
      master = user_repo.getBranch('master')
      path = "melts/#{filename}"

      changes = {}
      changes[path] = file
      # just one file? ok.
      _onBranch = () ->
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

  $scope.edit_song_pr = () ->
    # TODO - should probably confirm modal ...
    # TODO - edit metadata
    # TODO - DRY some of this up?
    branchname = $scope.selected.title.toLowerCase().replace /\ /g, '_'
    new_version = CryptoJS.MD5($scope.song_data.trim()).toString()
    # heuristic ...
    old_filepath = "melts/#{branchname}_#{$scope.selected.version}.melt"
    filename = "#{branchname}_#{new_version}.melt"
    context = {
      title: $scope.selected.title
      author: $scope.selected.author
      version: new_version
      performed_by: $scope.selected.performed_by
      tube_id: $scope.selected.tube_id
      song_data: $scope.song_data
    }
    file_text = song_template context
    changes = {}
    path = "melts/#{filename}"

    changes[path] = file_text

    user_repo = $scope.github.getRepo $scope.userInfo.login, "meltodies"
    master = user_repo.getBranch('master')

    _onBranch = () ->
      #console.log "_onBranch"
      branch = user_repo.getBranch(branchname)
      # Doesn't seem to be a way to do this with one commit!
      # TODO - try other JS Github APIs .. octokat instead of octokit?
      _remove_and_pr = () ->
        #console.log "remove", old_filepath
        _pr = () ->
          #console.log "PR!"
          $scope.upstream_repo.createPullRequest
            "title": "Edit #{context.title}"
            "head": "#{$scope.userInfo.login}:#{branchname}"
            "base": "master"
          hydrate file_text
          localStorageService.set "override::#{path}", "please"
          #console.log "WE WROTE!", path
          localStorageService.set path, file_text
          $scope.song_edited = false
          $scope.$apply()
        # error or not, just do it.
        branch.remove(old_filepath, "Remove #{old_filepath}").then _pr, _pr
      # whether we can write or not, we remove and PR .. hrm ..
      branch.writeMany(changes, "Edit #{context.title}").then _remove_and_pr, _remove_and_pr
    master.createBranch(branchname).then _onBranch, _onBranch


AddSongModalCtrl = ($scope, $modalInstance, title) ->
  # wtf, bro
  # http://stackoverflow.com/a/22172612/177293
  # http://stackoverflow.com/q/18716113/177293
  window.modal_scope = $scope
  $scope.data =
    title: title
    author: null
    performed_by: null
    tube_id: null
    song_data: null

  # TODO - validation

  $scope.ok = () ->
    $modalInstance.close($scope.data)

  $scope.cancel = () ->
    $modalInstance.dismiss('cancel')


MeltController.$inject = ['$scope', '$http', '$modal', '$location', 'localStorageService', '$analytics']
angular.module('MeltApp').controller 'MeltController', MeltController
