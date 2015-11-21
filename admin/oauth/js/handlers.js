/**
 * Handles the javascript authentication of providers that don't use specialized SDKs or namespaces
 */

$.fn.preload = function() {
    this.each(function(){
        $('<img/>')[0].src = this;
    });
}

/**
 * Handling the Google signin
 */
