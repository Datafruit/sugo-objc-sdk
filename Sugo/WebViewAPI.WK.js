    sugo.rawTrack = function(event_id, event_name, props) {
        if (!props) {
            props = {};
        }
        props.path_name = sugo.relative_path;
        if (!props.page_name && sugo.init.page_name) {
            props.page_name = sugo.init.page_name;
        }
        var track = {
            'eventID': '',
            'eventName': event_name,
            'properties': JSON.stringify(props)
        };
        window.webkit.messageHandlers.SugoWKWebViewBindingsTrack.postMessage(track);
    }

    sugo.track = function(event_name, props) {
        sugo.rawTrack('', event_name, props);
    };

    sugo.timeEvent = function(event_name) {
        var time = {
            'eventName': event_name
        };
        window.webkit.messageHandlers.SugoWKWebViewBindingsTime.postMessage(time);
    };

    sugo.trackStayEvent = function() {
        sugo.enter_time = new Date().getTime();
        if (!window.sugo) {
            window.addEventListener('unload', function() {
                var duration = (new Date().getTime() - sugo.enter_time) / 1000;
                var tmp_props = JSON.parse(JSON.stringify(sugo.view_props));
                tmp_props.duration = duration;
                sugo.track('停留', tmp_props);
            })
        }
    };

    var sugoio = {
        track: sugo.track,
        time_event: sugo.timeEvent
    };
    
