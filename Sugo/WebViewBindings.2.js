sugo_bindings.current_event_bindings = {};
for (var i = 0; i < sugo_bindings.h5_event_bindings.length; i++) {
    var b_event = sugo_bindings.h5_event_bindings[i];
    if (b_event.target_activity === sugo_bindings.current_page) {
        var key = JSON.stringify(b_event.path);
        sugo_bindings.current_event_bindings[key] = b_event;
    }
};
sugo_bindings.addEvent = function(children, event) {
    children.addEventListener(event.event_type, function(e) {
                              var custom_props = {};
                              if (event.code && event.code.replace(/(^\s*)|(\s*$)/g, "") != '') {
                              var sugo_props = new Function(event.code);
                              custom_props = sugo_props();
                              }
                              custom_props.from_binding = true;
                              sugo.track(event.event_id, event.event_name, JSON.stringify(custom_props));
                              });
};
sugo_bindings.bindEvent = function() {
    var paths = Object.keys(sugo_bindings.current_event_bindings);
    for (var idx = 0; idx < paths.length; idx++) {
        var path_str = paths[idx];
        var event = sugo_bindings.current_event_bindings[path_str];
        var path = JSON.parse(paths[idx]).path;
        if (event.similar === true) {
            path = path.replace(/:nth-child\([0-9]*\)/g, "");
        }
        var eles = document.querySelectorAll(path);
        if (eles) {
            for (var eles_idx = 0; eles_idx < eles.length; eles_idx++) {
                var ele = eles[eles_idx];
                sugo_bindings.addEvent(ele, event);
            }
        }
    }
};
