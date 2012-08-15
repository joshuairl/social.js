##Social.js
###A framework independent JavaScript library to aid integration with popular social platforms.

####Plans
* Multiple social login interfaces such as Facebook, Twitter, LinkedIn, and Foursquare.
* Status updates for all platforms
* Retrieve contacts for all platforms

####Currently supported networks
* Facebook
* 

API
* SocialWrapper.getFriends
* SocialWrapper.getCurrentUser
* SocialWrapper.getAppFriends
* SocialWrapper.getProfiles
* SocialWrapper.inviteFriends
* SocialWrapper.resizeCanvas
* SocialWrapper.postWall
* SocialWrapper.makePayment

Methods:
* SocialWrapper.initResizeCanvas
* SocialWrapper.initContext
* SocialWrapper.getApiName

Requires jQuery.
jQuery (document). ready (function () {
	var driverName = 'vk'; / / or mm, or facebook: sm resolveApiName in the social-api.js
	var params = {mm_key: 'xxx', fb_id: 'xxx'}; / / cm example.html
	new SocialApiWrapper (driverName, params, callback);
});

After that, you will be able to the global window.socialWrapper.
Implemented names profile fields to a common format. The names are given as follows:
* Id
* First_name
* Last_name
* Nickname
* Birthdate
* Gender
* Photo

In example.html - an example of use. This example works in four sots.setyah iframe-like application for these addresses:

* Http://url.com/example.html?api=vk
* Http://url.com/example.html?api=mm
* Http://url.com/example.html?api=fb
* Http://url.com/example.html?api=ok

In Friendster Library tested only in the sandbox.

Here there is no check permishenov installed application, it can be done in the application settings (VK, MM), or on the server (FB).

Development started until it is used, api may change, and will certainly change. It is better to participate.

The plans - adding profile fields, authorization from the sites, error handling, wrap in a deferred, many more methods
client download media files, callbacks for payment, and much more.