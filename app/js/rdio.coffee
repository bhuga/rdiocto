class @Rdio

  call: (method, args ) ->
    callback = args.complete
    error_callback = args.error || console.log
    method = args.method
    args.method = args.error = args.callback = undefined
    $.ajax
      method: 'POST'
      url: "/rdio/#{method}"
      params: args
      complete: (xhr) ->
        data = undefined
        try
          data = JSON.parse(xhr.responseText)
        catch error
          data = { status: 'error', message: xhr.responseText }
        if data['status'] == 'error'
          error_callback data['message']
        else
          callback data['result']

