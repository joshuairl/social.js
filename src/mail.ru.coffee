###
http://api.mail.ru/docs/guides/social-apps/

@param params
@param callback
###
MmSocialApi = (params, callback) ->
  instance = this
  
  # private
  apiUrl = "http://cdn.connect.mail.ru/js/loader.js"
  wrap_api = (fn) ->
    mailru.loader.require "api", fn

  wrap = ->
    window[params.wrapperName]

  moduleExport =
    
    # raw api object - returned from remote social network
    raw: null
    unifyFields:
      id: "uid"
      first_name: "first_name"
      last_name: "last_name"
      birthdate: "birthday"
      nickname: "nick"
      photo: "pic"
      
      #			pic_small
      #			pic_big
      gender: ->
        value = (if arguments_.length then arguments_[0] else false)
        return "sex"  if value is false
        (if value is 0 then "male" else "female")

    
    # information methods
    getProfiles: (uids, callback, errback) ->
      uids = (uids + "").split(",")  unless uids instanceof Array
      wrap_api ->
        mailru.common.users.getInfo ((data) ->
          return (if errback then errback(data.error) else callback({}))  if data.error
          callback wrap().unifyProfileFields(data)
        ), uids.join(",")


    getFriends: (callback, errback) ->
      wrap_api ->
        mailru.common.friends.getExtended (data) ->
          return (if errback then errback(data.error) else callback([]))  if data.error
          data.response = []  if data.response is null
          callback wrap().unifyProfileFields(data)



    getCurrentUser: (callback, errback) ->
      moduleExport.getProfiles mailru.session.vid, ((data) ->
        callback data[0]
      ), errback

    getAppFriends: (callback, errback) ->
      wrap_api ->
        mailru.common.friends.getAppUsers ((data) ->
          return (if errback then errback(data.error) else callback([]))  if data.error
          data = []  if data is null
          callback wrap().unifyProfileFields(data)
        ),
          ext: true



    
    # utilities
    inviteFriends: ->
      local_params = arguments_[0] or null
      local_callback = arguments_[1] or null
      local_callback = local_params  if typeof local_params is "function"
      wrap_api ->
        eventINVId = mailru.events.listen(mailru.app.events.friendsInvitation, (event) ->
          if event.status isnt "opened"
            mailru.events.remove eventINVId
            (if local_callback then local_callback(event.data) else null)
        )
        mailru.app.friends.invite()


    resizeCanvas: (params, callback) ->
      mailru.app.utils.setHeight params.height
      (if callback then callback() else null)

    
    # service methods
    postWall: (params, callback, errback) ->
      params = jQuery.extend(
        id: mailru.session.vid
      , params)
      wrap_api ->
        
        # в guestbook если не себе
        event = mailru.common.events.guestbookPublish
        method = mailru.common.guestbook
        post_params =
          text: params.message
          uid: params.id

        
        # в stream если себе
        if params.id is mailru.session.vid
          event = mailru.common.events.streamPublish
          method = mailru.common.stream
          post_params = text: params.message
        eventId = mailru.events.listen(event, (event) ->
          return callback()  if event.status is "publishSuccess"
          if event.status is "closed"
            mailru.events.remove eventId
            (if errback then errback(event) else callback(event))
        )
        method.post post_params, (data) ->
          (if errback then errback(data) else callback(data))  if data.error



    makePayment: (params, callback, errback, closeDialogback) ->
      wrap_api ->
        eventDialogId = mailru.events.listen(mailru.app.events.paymentDialogStatus, (event) ->
          if event.status is "closed"
            mailru.events.remove eventDialogId
            (if closeDialogback then closeDialogback(event) else callback(event))
        )
        eventPaymentId = mailru.events.listen(mailru.app.events.incomingPayment, (event) ->
          mailru.events.remove eventPaymentId
          return (if errback then errback() else callback(event))  if event.status is "failed"
          callback event
        )
        mailru.app.payments.showDialog params


  
  # constructor
  jQuery.getScript apiUrl, ->
    wrap_api ->
      mailru.app.init params.mm_key
      moduleExport.raw = mailru
      
      # export methods
      instance.moduleExport = moduleExport
      (if callback then callback() else null)

