'use strict'

window.MeltApp = angular.module 'MeltApp', ['ui.utils']

MeltController = ($scope, $http) ->
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
        $scope.song_meta = data.split('---')[1]
        $scope.song_data = data.split('---')[2]
      else
        $scope.song_meta = null
        $scope.song_data = data
      document.getElementById('pre-song').innerHTML = $scope.song_data
      document.getElementById('song-meta').innerHTML = $scope.song_meta

MeltController.$inject = ['$scope', '$http']


angular.module('MeltApp').controller 'MeltController', MeltController

