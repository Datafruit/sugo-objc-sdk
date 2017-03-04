sugo.rawTrack = function(event_id, event_name, props) {
    if (!props) {
        props = {};
    }
    props.path_name = sugo.relative_path;
    if (!props.page_name && sugo.init.page_name) {
        props.page_name = sugo.init.page_name;
    }
    SugoWebViewJSExport.trackOfIdNameProperties(event_id, event_name, JSON.stringify(props));
}

sugo.track = function(event_name, props) {
    sugo.rawTrack('', event_name, props);
};

sugo.timeEvent = function(event_name) {
    SugoWebViewJSExport.timeOfEvent(event_name);
};

sugo.trackStayEvent = function() {
    sugo.enter_time = new Date().getTime();
    window.onunload = function() {
        var duration = (new Date().getTime() - sugo.enter_time) / 1000;
        sugo.track('停留', {
            duration: duration
        });
    }
}

var sugoio = {
    track: sugo.track,
    time_event: sugo.timeEvent
};
