/**
 * http://api.mail.ru/docs/guides/social-apps/
 *
 * @param params
 * @param callback
 */
var MmSocialApi = function(params, callback) {
	var instance = this;

	// private
	var apiUrl = 'http://cdn.connect.mail.ru/js/loader.js';
	var wrap_api = function(fn) {
		mailru.loader.require('api', fn);
	};
	
	var wrap = function() {
		return window[params.wrapperName];
	};

	var moduleExport = {
		// raw api object - returned from remote social network
		raw: null,

		unifyFields: {
			id: 'uid',
			first_name: 'first_name',
			last_name: 'last_name',
			birthdate: 'birthday',
			nickname: 'nick',

			photo: 'pic',
//			pic_small
//			pic_big

			gender: function() {
				var value = arguments.length ? arguments[0] : false;
				if (value === false) { return 'sex'; }
				return value == 0 ? 'male' : 'female';
			}
		},

		// information methods
		getProfiles : function(uids, callback, errback) {
			if (! (uids instanceof Array)) {
				uids = (uids+'').split(',');
			}
			wrap_api(function() {
				mailru.common.users.getInfo(function(data) {
					if (data.error) {
						return errback ? errback(data.error) : callback({});
					}
					return callback(wrap().unifyProfileFields(data));
				}, uids.join(','));
			});
		},
		getFriends : function(callback, errback) {
			wrap_api(function() {
				mailru.common.friends.getExtended(function(data) {
					if (data.error) {
						return errback ? errback(data.error) : callback([]);
					}
					if (data.response === null) {
						data.response = [];
					}
					return callback(wrap().unifyProfileFields(data));
				});
			});
		},
		getCurrentUser : function(callback, errback) {
			moduleExport.getProfiles(mailru.session.vid, function(data) { callback(data[0]); }, errback);
		},
		getAppFriends : function(callback, errback) {
			wrap_api(function() {
				mailru.common.friends.getAppUsers(function(data) {
					if (data.error) {
						return errback ? errback(data.error) : callback([]);
					}
					if (data === null) {
						data = [];
					}
					return callback(wrap().unifyProfileFields(data));
				}, { ext: true });
			});
		},
		// utilities
		inviteFriends : function() {
			var local_params = arguments[0] || null;
			var local_callback = arguments[1] || null;
			if (typeof local_params == 'function') {
				local_callback = local_params;
			}
			wrap_api(function() {
				var eventINVId = mailru.events.listen(mailru.app.events.friendsInvitation, function(event) {
					if (event.status !== 'opened') {
						mailru.events.remove(eventINVId);
						return local_callback ? local_callback(event.data) : null;
					}
				});
				mailru.app.friends.invite();
			});
		},
		resizeCanvas : function(params, callback) {
			mailru.app.utils.setHeight(params.height);
			return callback ? callback() : null;
		},
		// service methods
		postWall : function(params, callback, errback) {
			params = jQuery.extend({'id': mailru.session.vid}, params);
			wrap_api(function() {
				// в guestbook если не себе
				var event = mailru.common.events.guestbookPublish;
				var method = mailru.common.guestbook;
				var post_params = {text: params.message, uid: params.id};
				// в stream если себе
				if (params.id == mailru.session.vid) {
					event = mailru.common.events.streamPublish;
					method = mailru.common.stream;
					post_params = {text: params.message};
				}
				var eventId = mailru.events.listen(event, function(event) {
					if (event.status == 'publishSuccess') {
						return callback();
					}
					if (event.status == 'closed') {
						mailru.events.remove(eventId);
						return errback ? errback(event) : callback(event);
					}
				});
				method.post(post_params, function(data) {
					if (data.error) {
						return errback ? errback(data) : callback(data);
					}
				});
			});
		},
		makePayment : function(params, callback, errback, closeDialogback) {
			wrap_api(function() {
				var eventDialogId = mailru.events.listen(mailru.app.events.paymentDialogStatus, function(event) {
					if (event.status == 'closed') {
						mailru.events.remove(eventDialogId);
						return closeDialogback ? closeDialogback(event) : callback(event);
					}
				});
				var eventPaymentId = mailru.events.listen(mailru.app.events.incomingPayment, function(event) {
					mailru.events.remove(eventPaymentId);
					if (event.status == 'failed') {
						return errback ? errback() : callback(event);
					}

					return callback(event);
				});
				mailru.app.payments.showDialog(params);
			});
		}
	};
	// constructor
	jQuery.getScript(apiUrl, function() {
		wrap_api(function() {
			mailru.app.init(params.mm_key);

			moduleExport.raw = mailru;

			// export methods
			instance.moduleExport = moduleExport;

			callback ? callback() : null;
		});
	});
};
