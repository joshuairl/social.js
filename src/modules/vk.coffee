###
http://vk.com/developers.php

@param params
@param callback
###
class Vk extends Module
    constructor: (@params, @callback) ->
        return
    instance = this
    apiUrl = "http://vk.com/js/api/xd_connection.js?2"
    params = jQuery.extend(
        width: 827
    , params)
    wrap = ->
        window[params.wrapperName]

    moduleExport =
        
        # raw api object - returned from remote social network
        raw: null
        unifyFields:
            id: "uid"
            first_name: "first_name"
            last_name: "last_name"
            birthdate: "bdate"
            nickname: "nickname"
            photo: "photo" # 50px
            #           photo_medium: 'photo_medium', // 100px
            #           photo_big: 'photo_big', // 200px
            #           photo_medium_rec: 'photo_medium_rec', // 100px sq
            #           photo_rec: 'photo_rec', // 50px sq
            gender: ->
                value = (if arguments_.length then arguments_[0] else false)
                return "sex"  unless value
                (if value is 2 then "male" else "female")

        
        # information methods
        getProfiles: (uids, name_case, callback, errback) ->
            uids = (uids + "").split(",")  unless uids instanceof Array
            if typeof name_case is "function"
                callback = arguments_[1]
                errback = arguments_[2]
            VK.api "getProfiles",
                uids: uids.join(",")
                fields: wrap().getApiFields(params.fields)
                name_case: name_case
            , (data) ->
                return (if errback then errback(data.error) else callback({}))  if data.error
                callback wrap().unifyProfileFields(data.response)


        getFriends: (callback, errback) ->
            VK.api "friends.get",
                uid: VK.params.viewer_id
                fields: wrap().getApiFields(params.fields)
            , (data) ->
                return (if errback then errback(data.error) else callback([]))  if data.error
                data.response = []  if data.response is null
                callback wrap().unifyProfileFields(data.response)


        getCurrentUser: (callback, errback) ->
            VK.loadParams document.location.href
            moduleExport.getProfiles VK.params.viewer_id, ((data) ->
                callback data[0]
            ), errback

        getAppFriends: (callback, errback) ->
            VK.api "execute",
                code: "API.getAppFriends();"
            , (data) ->
                (if errback then errback(data.error) else callback({}))  if data.error
                data.response = []  if data.response is null
                
                # @todo добавить получение профилей
                callback data.response


        
        # utilities
        inviteFriends: ->
            params = arguments_[0] or null
            callback = arguments_[1] or null
            callback = params  if typeof params is "function"
            VK.addCallback "onWindowFocus", ->
                VK.removeCallback "onWindowFocus"
                (if callback then callback() else null)

            VK.callMethod "showInviteBox"

        resizeCanvas: (params, callback) ->
            VK.callMethod "resizeWindow", params.width, params.height
            (if callback then callback() else null)

        
        # service methods
        postWall: (params, callback, errback) ->
            params = jQuery.extend(
                id: VK.params.viewer_id
            , params)
            VK.api "wall.post",
                owner_id: params.id
                message: params.message
            , (data) ->
                return (if errback then errback(data.error) else callback(data.error))  if data.error
                callback data.response


        
        # как это сделать правильно?
        makePayment: (params, callback, errback, closeDialogback) ->
            
            # @todo что тут делать с errback?
            balanceChanged = false
            VK.addCallback "onWindowFocus", ->
                VK.removeCallback "onWindowFocus"
                (if closeDialogback then closeDialogback() else callback())  unless balanceChanged

            VK.addCallback "onBalanceChanged", ->
                VK.removeCallback "onBalanceChanged"
                balanceChanged = true
                callback()

            VK.callMethod "showPaymentBox", params.votes

    
    # constructor
    jQuery.getScript apiUrl, ->
        VK.init ->
            VK.loadParams document.location.href
            moduleExport.raw = VK
            
            # export methods
            instance.moduleExport = moduleExport
            (if callback then callback() else null)

