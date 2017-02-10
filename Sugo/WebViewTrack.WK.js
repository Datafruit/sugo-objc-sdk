sugo.track = function(event_name, props) {
    if (!props) {
        props = {};
    }
    props.path_name = sugo.relative_path;
    if (!props.page_name) {
        props.page_name = sugo.page_name;
    }
    var track = {
        'eventID'       : '',
        'eventName'     : event_name,
        'properties'    : JSON.stringify(props)
    };
    window.webkit.messageHandlers.WKWebViewBindingsTrack.postMessage(track);
};

sugo.timeEvent = function(event_name) {
    var time = {
        'eventName'     : event_name
    };
    window.webkit.messageHandlers.WKWebViewBindingsTime.postMessage(time);
};
var init_code = new Function(sugo.init_code);
init_code();

sugo.track('h5_enter_page_event');
sugo.enter_time = new Date().getTime();

window.addEventListener('beforeunload', function(e) {
                        var duration = (new Date().getTime() - sugo.enter_time) / 1000;
                        sugo.track('h5_stay_event', {
                                   duration: duration
                                   });
                        });
