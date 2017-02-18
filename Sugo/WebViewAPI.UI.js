sugo.track = function(event_name, props) {
    if (!props) {
        props = {};
    }
    props.path_name = sugo.relative_path;
    if (!props.page_name && sugo.init.page_name) {
        props.page_name = sugo.init.page_name;
    }
    SugoWebViewJSExport.trackOfIdNameProperties('', event_name, JSON.stringify(props));
};

sugo.timeEvent = function(event_name) {
    SugoWebViewJSExport.timeOfEvent(event_name);
};

var sugoio = {
    track: sugo.track,
    time_event: sugo.timeEvent
};
