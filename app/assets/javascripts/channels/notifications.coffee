App.notifications = App.cable.subscriptions.create "NotificationsChannel",
  connected: ->
    # Called when the subscription is ready for use on the server
    console.log('Connected')

  disconnected: ->
    # Called when the subscription has been terminated by the server
    console.log('Disconnected')

  received: (data) ->
    # Called when there's incoming data on the websocket for this channel
    if data['processing_completed'] == false
      $("#video_progress").replaceWith($(data['html']))
    else
      # TODO: Use ajax for this purpose is would look more smoothly
      location.reload()
