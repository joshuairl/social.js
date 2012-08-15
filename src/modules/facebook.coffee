class Facebook extends Module
    constructor: (@params, @callback) ->
        return
    instance = this
    apiUrl = "http://connect.facebook.net/en_US/all.js"
    
    #params = jQuery.extend({}, params);
    wrap = ->
        window[params.wrapperName]

    getUserFql = (fields, uids) ->
        "SELECT " + fields + " FROM user WHERE uid IN (" + uids + ")"

    moduleExport =
        # raw api object - returned from remote social network
        raw: null
        unifyFields:
            id: "uid"
            first_name: "first_name"
            last_name: "last_name"
            photo: "pic_square"
            gender: ->
                value = (if arguments_.length then arguments_[0] else false)
                return "sex"  unless value
                (if value is "male" then "male" else "female")

        
        # information methods
        getProfiles: (uids, callback, errback) ->
            uids = (uids + "").split(",")  unless uids instanceof Array
            FB.Data.query(getUserFql(wrap().getApiFields(params.fields), uids.join(","))).wait (data) ->
                
                # @todo проверка ошибки, errback
                callback wrap().unifyProfileFields(data)


        getFriends: (callback, errback) ->
            FB.Data.query(getUserFql(wrap().getApiFields(params.fields), "SELECT uid2 FROM friend WHERE uid1 = me()")).wait (data) ->
                
                # @todo проверка ошибки, errback
                callback wrap().unifyProfileFields(data)


        getCurrentUser: (callback, errback) ->
            moduleExport.getProfiles FB.getSession().uid, ((data) ->
                callback data[0]
            ), errback

        getAppFriends: (callback, errback) ->
            FB.api
                method: "friends.getAppUsers"
            , (data) ->
                
                # @todo добавить получение профилей
                callback data


        
        # utilities
        inviteFriends: ->
            local_params = arguments_[0] or null
            local_callback = arguments_[1] or null
            local_callback = local_params  if typeof local_params is "function"
            FB.ui
                method: "apprequests"
                message: local_params.install_message
                data: {}
            , (data) ->
                (if local_callback then local_callback(data) else null)


        resizeCanvas: (params, callback) ->
            FB.Canvas.setAutoResize false
            FB.Canvas.setSize params.height
            (if callback then callback() else null)

        
        # service methods
        postWall: (params, callback, errback) ->
            params = jQuery.extend(
                id: FB.getSession().uid
            , params)
            params.to = params.id
            FB.ui jQuery.extend(
                method: "feed"
            , params), (response) ->
                
                # @todo проверка ошибки, errback
                callback response


        makePayment: (params, callback, errback, closeDialogback) ->
            FB.ui
                method: "pay"
                order_info: params.order_info
                purchase_type: "item"
            , (data) ->
                if data["order_id"]
                    callback data
                else
                    callback {}


    
    # @todo проверка ошибки, errback, closeDialogback
    
    # constructor
    jQuery("body").prepend jQuery("<div id='fb-root'></div>")  unless jQuery("#fb-root").length
    jQuery.getScript apiUrl, ->
        FB.init
            appId: params.fb_id
            status: true
            cookie: true
            xfbml: false

        moduleExport.raw = FB
        
        # export methods
        instance.moduleExport = moduleExport
        (if callback then callback() else null)
