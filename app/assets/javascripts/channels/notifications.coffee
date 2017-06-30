App.notifications = App.cable.subscriptions.create "NotificationsChannel",
  connected: ->
    # Called when the subscription is ready for use on the server
    console.log('Connected')

  disconnected: ->
    # Called when the subscription has been terminated by the server
    console.log('Disconnected')

  received: (data) ->
    # Called when there's incoming data on the websocket for this channel
    $("#video_progress").replaceWith($(data['html']))
    # console.log(data);
    # if $(data['file_processing']) == true

    # else
      # location.reload();
      # $("#video_info").replaceWith($(data))
