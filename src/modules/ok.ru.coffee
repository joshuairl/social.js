###
http://dev.odnoklassniki.ru/wiki/display/ok/Odnoklassniki+JavaScript+API

@param params
@param callback
###
class Ok extends Module
    constructor: (@params, @callback) ->
        return
        
    instance = this
    
    # params
    params = jQuery.extend(
        ok_sanbox: false
        width: 760
    , params)
    wrap = ->
        window[params.wrapperName]

    apiUrl = "http://api.odnoklassniki.ru/js/fapi.js"
    apiUrl = "http://api-sandbox.odnoklassniki.ru:8088/js/fapi.js"  if params.ok_sanbox
    
    # private
    callRaw = (method, params, callback) ->
        params = jQuery.extend(
            method: method
        , params)
        FAPI.Client.call params, callback

    moduleExport =
        
        # raw api object - returned from remote social network
        raw: null
        unifyFields:
            id: "uid"
            first_name: "first_name"
            last_name: "last_name"
            birthdate: "birthday"
            nickname: "name"
            photo: "pic_1"
            
            #pic_2
            #pic_3
            #pic_4
            gender: ->
                value = (if arguments_.length then arguments_[0] else false)
                return "gender"  if value is false
                (if value is "male" then "male" else "female")

        
        # information methods
        getProfiles: (uids, callback, errback) ->
            uids = (uids + "").split(",")  unless uids instanceof Array
            callRaw "users.getInfo",
                fields: wrap().getApiFields(params.fields)
                uids: uids.join(",")
            , (status, data, error) ->
                if status is "ok"
                    callback wrap().unifyProfileFields(data)
                else
                    (if errback then errback(error) else callback(error))


        getFriends: (callback, errback) ->
            callRaw "friends.get", {}, (status, data, error) ->
                if status is "ok"
                    moduleExport.getProfiles data.join(","), callback, errback
                else
                    (if errback then errback(error) else callback(error))


        getCurrentUser: (callback, errback) ->
            moduleExport.getProfiles Object(FAPI.Util.getRequestParameters()).logged_user_id, ((data) ->
                callback data[0]
            ), errback

        getAppFriends: (callback, errback) ->
            callRaw "friends.getAppUsers", {}, (status, data, error) ->
                if status is "ok"
                    moduleExport.getProfiles data.uids.join(","), callback, errback
                else
                    (if errback then errback(error) else callback(error))


        
        # utilities
        inviteFriends: ->
            local_params = arguments_[0] or null
            local_callback = arguments_[1] or null
            local_callback = local_params  if typeof local_params is "function"
            FAPI.UI.showInvite local_params.install_message
            (if local_callback then local_callback() else null)

        resizeCanvas: (params, callback) ->
            FAPI.UI.setWindowSize params.width, params.height
            (if callback then callback() else null)

        
        # service methods
        postWall: (params, callback, errback) ->
            params = jQuery.extend(
                id: FAPI.Client.uid
            , params)
            window.API_callback = (method, status, attributes) ->
                delete window.API_callback

                
                # в апи не реализован вызов callback на отмене приглашения запостить на стену
                return (if errback then errback(attributes) else callback(attributes))  unless status is "ok"
                if method is "showConfirmation" and status is "ok"
                    publishMessage.resig = attributes
                    callRaw "stream.publish", publishMessage, (data) ->
                        
                        # @todo доделать errback(data);
                        callback data


            
            # @todo добавить обработку с uid
            publishMessage =
                message: params.message
                method: "stream.publish"
                application_key: FAPI.Client.applicationKey
                session_key: FAPI.Client.sessionKey
                format: FAPI.Client.format

            publishMessage.sig = FAPI.Util.calcSignature(publishMessage, FAPI.Client.sessionSecretKey)
            FAPI.UI.showConfirmation "stream.publish", params.message, publishMessage.sig

        makePayment: (params, callback, errback, closeDialogback) ->
            window.API_callback = (method, result, data) ->
                delete window.API_callback

                
                # @todo проверка ошибки, errback, closeDialogback
                
                # @todo какие тут приходят данные?
                data = jQuery.parseJSON(data)
                data.result = result
                callback data

            FAPI.UI.showPayment params.name, params.description, null, null, JSON.stringify(params.items), [], "ok", true

    
    # constructor
    jQuery.getScript apiUrl, ->
        FAPI_Params = Object(FAPI.Util.getRequestParameters())
        FAPI.init FAPI_Params.api_server, FAPI_Params.apiconnection, ->
            moduleExport.raw = FAPI
            
            # export methods
            instance.moduleExport = moduleExport
            (if callback then callback() else null)



#
#var publishMessage = null;
#function API_callback(method, status, attributes){// Odnokl madness
#    if(method == 'showConfirmation') {
#       if(status == 'ok'){
#           publishMessage.resig = attributes;
#           publishMessage.method = "stream.publish";
#           core_log("api_postNews - streamPublish ok, posting",publishMessage);
#           FAPI.Client.call( publishMessage, function(status, data, error) { });
#       }else{
#           core_log("api_postNews - streamPublish failed!",publishMessage);
#       }
#    }
#}
#
#api_postNews = function(parameters) {
#   core_log("api_postNews",parameters);
#   var uid_to = parameters.target_refnick;
#   var image_url = parameters.image_url;
#   var news_title = parameters.news_title;
#   var news_text = parameters.news_text;
#   var action_title = parameters.action_title;
#   var action_hash = parameters.action_hash;
#   {// wall publish
#       var request = {};
#       request.message = news_text;//=FAPI.Util.encodeUtf8("Ураааа!")-NotOK;//="Поздравляем"-OK;
#       if(image_url != null && image_url != ""){
#           var attachment = { };
#           request.message = news_title;
#           attachment.caption = news_text;
#           attachment.media = [];
#           attachment.media.push( { type:"image", src:image_url } );
#           request.attachment = $.toJSON( attachment );
#       }
#       if(action_title != null && action_title != ""){
#           // href is hash, not an URL!!!
#           // OD documentation totally fucked up
#           //if(action_hash.indexOf("http://")<0){
#           //  action_hash = wla.struct_app_config.game_url+"#"+action_hash;
#           //}
#           if(action_hash.length<2){
#               action_hash = "none";
#           }
#           var action_links = [];
#           action_links.push( { text: action_title, href: action_hash } );
#           request.action_links = $.toJSON( action_links );
#       }
#       publishMessage = request;
#       publishMessage["method"] = "stream.publish";
#       publishMessage["application_key"] = FAPI.Client.applicationKey;
#       publishMessage["session_key"] = FAPI.Client.sessionKey;
#       publishMessage["format"] = FAPI.Client.format;
#       publishMessage['sig'] = FAPI.Util.calcSignature(publishMessage, FAPI.Client.sessionSecretKey);
#       core_log("api_postNews - showConfirmation",request);
#       FAPI.UI.showConfirmation("stream.publish", news_title+"\n"+news_text, publishMessage['sig']);
#   }
#}
#