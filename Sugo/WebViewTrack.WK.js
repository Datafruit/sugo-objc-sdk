sugo.view_props = {};
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
    window.webkit.messageHandlers.SugoWKWebViewBindingsTrack.postMessage(track);
};

sugo.timeEvent = function(event_name) {
    var time = {
        'eventName'     : event_name
    };
    window.webkit.messageHandlers.SugoWKWebViewBindingsTime.postMessage(time);
};

var init_code = new Function(sugo.init_code);
init_code();

sugo.track('浏览', sugo.view_props);
sugo.enter_time = new Date().getTime();

window.addEventListener('beforeunload', function(e) {
    var duration = (new Date().getTime() - sugo.enter_time) / 1000;
    sugo.track('停留', {
        duration: duration
    });
    sugo.track('页面退出');
});
