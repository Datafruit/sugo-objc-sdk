sugo.init_path = function() {
    sugo.relative_path = window.location.pathname.replace(sugo.home_path, sugo.home_path_replacement);
    var keys = Object.keys(sugo.regular_expressions);
    for (var i = keys.length - 1; i >= 0; i--) {
        sugo.relative_path = sugo.relative_path.replace(/keys[i]/g, sugo.regular_expressions[keys[i]]);
    }
    sugo.hash = window.location.hash;
    sugo.hash = sugo.hash.indexOf('?') < 0 ? sugo.hash : sugo.hash.substring(0, sugo.hash.indexOf('?'));
    sugo.relative_path += sugo.hash;
    sugo.relative_path = sugo.relative_path.replace('#/', '#');
    for (var i = 0; i < sugo.page_infos.length; i++) {
        var page_info = sugo.page_infos[i]
        if (page_info.page === sugo.relative_path) {
            sugo.init = {
            code: page_info.code,
            page_name: page_info.page_name
            };
            break;
        }
    }
    sugo.current_page = sugo.view_controller + '::' + sugo.relative_path;
    
    for (var i = 0; i < sugo.h5_event_bindings.length; i++) {
        var b_event = sugo.h5_event_bindings[i];
        if (b_event.target_activity === sugo.current_page || b_event.cross_page === true) {
            var key = JSON.stringify(b_event.path);
            sugo.current_event_bindings[key] = b_event;
        }
    };
    
    if (sugo.init.code) {
        try {
            var init_code = new Function('sugo', sugo.init.code);
            init_code(sugo);
        } catch (e) {
            console.log(sugo.init.code);
        }
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
