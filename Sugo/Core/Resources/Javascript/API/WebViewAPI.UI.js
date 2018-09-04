
    sugo.scheme = 'sugo.npi'
    sugo.data = {};
    sugo.generateUUID = function() {
        var d = new Date().getTime();
        var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
            var r = (d + Math.random() * 16) % 16 | 0;
            d = Math.floor(d / 16)
            return (c == 'x' ? r : (r & 0x7 | 0x8)).toString(16)
        })
        return uuid
    };

    sugo.callNative = function(npi, id) {
        var native;
        if (document.getElementsByName(sugo.scheme).length > 0) {
            native = document.getElementsByName(sugo.scheme)[0];
        } else {
            native = document.createElement('iframe');
            native.name = sugo.scheme;
            native.style.display = 'none';
            document
                .documentElement
                .appendChild(native);
        }
        native.src = sugo.scheme + '://' + npi + '?eventUUID=' + id;
        console.log('npi: ' + npi, 'id: ' + id, 'data: ' + sugo.data[id]);
    }

    sugo.dataOf = function() {
        var data_tmp= sugo.data;
        sugo.data= {};
        return JSON.stringify(data_tmp);
    };

    sugo.rawTrack = function(event_id, event_name, props) {
        if (!props) {
            props = {};
        }
        if(sugo.single_code) {
            props.path_name = sugo.relative_path + "##" + sugo.single_code;
        } else {
            props.path_name = sugo.relative_path;
        }
        if (!props.page_name && sugo.init.page_name) {
            props.page_name = sugo.init.page_name;
            if (sugo.init.page_category !== undefined) {
                props.page_category = sugo.init.page_category;
            }
        }

        var eventUUID = sugo.generateUUID();
        var event = {
            'eventID': event_id,
            'eventName': event_name,
            'properties': JSON.stringify(props)
        };
        sugo.data[eventUUID] = JSON.stringify(event);
        sugo.callNative('track', eventUUID);
    };

    sugo.track = function(event_name, props) {
        sugo.rawTrack('', event_name, props);
    };

    sugo.timeEvent = function(event_name) {

        var eventUUID = sugo.generateUUID();
        var event = {
            'eventName': event_name
        };
        sugo.data[eventUUID] = JSON.stringify(event);
        sugo.callNative('time', eventUUID);
    };

    sugo.trackBrowseEvent = function() {
        if (sugo.can_track_web_page) {
            sugo.track('浏览', sugo.view_props);
            sugo.enter_time = new Date().getTime();
        }
    };

    sugo.trackStayEvent = function() {
        var event = {};
        if (sugo.enter_time) {
            var duration = (new Date().getTime() - sugo.enter_time) / 1000;
            var tmp_props = JSON.parse(JSON.stringify(sugo.view_props));
            tmp_props.duration = duration;
            event = {
                'eventID': '',
                'eventName': '停留',
                'properties': JSON.stringify(tmp_props)
            };
            sugo.enter_time = null;
        }
        return JSON.stringify(event);
    };

    sugo.trackStayEventWeb = function() {
        var duration = (new Date().getTime() - sugo.enter_time) / 1000;
        var tmp_props = sugo.view_props;
        tmp_props.duration = duration;
        sugo.track('停留', tmp_props);
    }

    var sugoio = {
        track: sugo.track,
        time_event: sugo.timeEvent
    };
