
    sugo.scheme = 'sugo.npi'
    sugo.data = {};
    sugo.generateUUID = function () {
        let d = new Date().getTime();
        let uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
            var r = (d + Math.random() * 16) % 16 | 0;
            d = Math.floor(d / 16)
            return (c == 'x'
                ? r
                : (r & 0x7 | 0x8)).toString(16)
        })
        return uuid
    };

    sugo.callNative = function (npi, id) {
        location = sugo.scheme + '://' + npi + '?eventUUID=' + id;
    };

    sugo.dataOf = function (id) {
        let data = sugo.data[id];
        delete sugo.data[id];
        return data;
    };

    sugo.rawTrack = function (event_id, event_name, props) {
        if (!props) {
            props = {};
        }
        props.path_name = sugo.relative_path;
        if (!props.page_name && sugo.init.page_name) {
            props.page_name = sugo.init.page_name;
        }

        let eventUUID = sugo.generateUUID();
        let event = {
            'eventID': event_id,
            'eventName': event_name,
            'properties': JSON.stringify(props)
        };
        sugo.data[eventUUID] = JSON.stringify(event);
        sugo.callNative('track', eventUUID);
    };

    sugo.track = function (event_name, props) {
        sugo.rawTrack('', event_name, props);
    };

    sugo.timeEvent = function (event_name) {

        let eventUUID = sugo.generateUUID();
        let event = {
            'eventName': event_name
        };
        sugo.data[eventUUID] = JSON.stringify(event);
        sugo.callNative('time', eventUUID);
    };

    sugo.trackStayEvent = function () {
        sugo.enter_time = new Date().getTime();
        if (!window.sugo) {
            window
                .addEventListener('unload', function () {
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
