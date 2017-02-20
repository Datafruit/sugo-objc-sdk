sugo.rawTrack = function(event_id, event_name, props) {
    if (!props) {
        props = {};
    }
    props.path_name = sugo.relative_path;
    if (!props.page_name && sugo.init.page_name) {
        props.page_name = sugo.init.page_name;
    }
    var track = {
        'eventID'       : '',
        'eventName'     : event_name,
        'properties'    : JSON.stringify(props)
    };
    window.webkit.messageHandlers.SugoWKWebViewBindingsTrack.postMessage(track);
}

sugo.track = function(event_name, props) {
    sugo.rawTrack('', event_name, props);
};

sugo.timeEvent = function(event_name) {
    var time = {
        'eventName'     : event_name
    };
    window.webkit.messageHandlers.SugoWKWebViewBindingsTime.postMessage(time);
};

var sugoio = {
    track: sugo.track,
    time_event: sugo.timeEvent
};
