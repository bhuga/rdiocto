Array.prototype.diff = (a) ->
  this.filter (i) ->
    !(a.indexOf(i) > -1)


class @Playlist extends Backbone.Model

  initialize: ->
    if @get('rdio_id')?
      @loadFromRdio()

  loadFromRdio: ->
    rdio.call 'get', {
      keys: @get('rdio_id')
      extras: 'trackKeys' },
      success: (data) =>
        @set('trackList', data[@get('rdio_id')].trackKeys)
        rdio.call 'get', {
          keys: data[@get('rdio_id')].trackKeys.join(',')
        },{
          success: (data) =>
            @set('tracks', data)
            @saveOldState()
            @trigger 'loaded'
            console.log data
        }

  toYaml: ->
    yaml = ""
    _.each @get('trackList'), (trackId, index) =>
      track = @get('tracks')[trackId]
      yaml += "- #{trackId} # #{track.artist} - #{track.name} (#{track.album})\n"
    yaml

  saveOldState: ->
    @set('oldTrackList', _.clone @get('trackList'))

  addTracks: (tracks, callback) ->
    if tracks.length > 0
      rdio.call 'addToPlaylist', {
        playlist: @get 'rdio_id'
        tracks: tracks.join ','
      }, {
        success: =>
          callback()
      }
    else
      callback()

  removeTracks: (tracks, callback) ->
    if tracks.length > 0
      rdio.call 'removeFromPlaylist', {
        playlist: @get 'rdio_id'
        tracks: tracks.join ','
      }, {
        success: =>
          callback()
      }
    else
      callback()

  syncToRdio: ->
    tracks = @get('trackList')
    old = @get('oldTrackList')
    add = tracks.diff old
    remove = old.diff tracks
    @addTracks add, =>
      @removeTracks remove, =>
        @trigger 'rdio:sync'
        @saveOldState()
        console.log "removed tracks."
    console.log "remove:"
    console.log remove
    console.log "Add:"
    console.log add
    # sync to rdio
    # save old state

