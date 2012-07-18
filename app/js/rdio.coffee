class @Rdio

  constructor: (opts) ->
    @user = opts.user

  call: (method, params, opts ) ->
    callback = opts.success
    error_callback = opts.error || console.log
    $.ajax
      method: 'POST'
      url: "/rdio/#{method}"
      data: params
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

