for (var i = 0; i < sugo.h5_event_bindings.length; i++) {
    var b_event = sugo.h5_event_bindings[i];
    if (b_event.target_activity === sugo.current_page) {
        var key = JSON.stringify(b_event.path);
        sugo.current_event_bindings[key] = b_event;
    }
};

sugo.delegate = function(eventType) {
    function handle(e) {
        var evt = window.event ? window.event : e;
        var target = evt.target || evt.srcElement;
        var currentTarget = e ? e.currentTarget : this;
        var paths = Object.keys(sugo.current_event_bindings);
        for (var idx = 0; idx < paths.length; idx++) {
            var path_str = paths[idx];
            var event = sugo.current_event_bindings[path_str];
            if (event.event_type != eventType) {
                continue;
            }
            var path = event.path.path;
            if (event.similar === true) {
                path = path.replace(/:nth-child\([0-9]*\)/g, '');
            }
            var eles = document.querySelectorAll(path);
            if (eles) {
                for (var eles_idx = 0; eles_idx < eles.length; eles_idx++) {
                    var ele = eles[eles_idx];
                    var parentNode = target;
                    while (parentNode) {
                        if (parentNode === ele) {
                            var custom_props = {};
                            if (event.code && event.code.replace(/(^\s*)|(\s*$)/g, '') != '') {
                                try {
                                    var sugo_props = new Function('e', 'element', 'conf', 'instance', event.code);
                                    custom_props = sugo_props(e, ele, event, sugo);
                                } catch (e) {
                                    console.log(event.code);
                                }
                            }
                            custom_props.from_binding = true;
                            custom_props.event_type = eventType;
                            custom_props.event_label = ele.innerText;
                            sugo.rawTrack(event.event_id, event.event_name, custom_props);
                            break;
                        }
                        parentNode = parentNode.parentNode;
                    }
                }
            }
        }
    }
    document.addEventListener(eventType, handle, true);
};

sugo.bindEvent = function() {
    sugo.delegate('click');
    sugo.delegate('focus');
    sugo.delegate('change');
};
