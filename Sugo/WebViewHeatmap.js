sugo.showHeatMap = function() {
    
    if (!sugo.can_show_heat_map || !sugo.h5_heats.heat_map) {
        return;
    }
    
    let events = 0;
    let pathsOfCurrentEventBindings = Object.keys(sugo.current_event_bindings);
    
    let hasValidHeatMap = false;
    for (var i = 0; i < pathsOfCurrentEventBindings.length; i++) {
        let eventId = sugo.current_event_bindings[pathsOfCurrentEventBindings[i]].event_id;
        if (Object.keys(sugo.h5_heats.heat_map).includes(eventId)) {
            hasValidHeatMap = true;
        }
    }
    
    if (!hasValidHeatMap) {
        return;
    }
    
    for (var i = 0; i < pathsOfCurrentEventBindings.length; i++) {
        let eventId = sugo.current_event_bindings[pathsOfCurrentEventBindings[i]].event_id;
        if (sugo.h5_heats.heat_map[eventId]) {
            events = events + sugo.h5_heats.heat_map[eventId];
        }
    }
    for (var i = 0; i < pathsOfCurrentEventBindings.length; i++) {
        let eventId = sugo.current_event_bindings[pathsOfCurrentEventBindings[i]].event_id;
        if (sugo.h5_heats.heat_map[eventId]) {
            let rate = sugo.h5_heats.heat_map[eventId] / events;
            sugo.current_event_bindings[pathsOfCurrentEventBindings[i]].heat = rate;
        }
    }
    let coldColor = {
        'red': 211,
        'green': 177,
        'blue': 125
    };
    let hotColor = {
        'red': 255,
        'green': 45,
        'blue': 81
    };
    let differenceColor = {
        'red': hotColor.red - coldColor.red,
        'green': hotColor.green - coldColor.green,
        'blue': hotColor.blue - coldColor.blue
    };
    let idOfHeatMap = 'sugo_heat_map';
    let defaultZIndex = 1000;
    let hmDiv = document.getElementById(idOfHeatMap);
    if (hmDiv || hmDiv != null) {
        document.body.removeChild(document.getElementById(idOfHeatMap));
    }
    hmDiv = document.createElement('div');
    hmDiv.id = idOfHeatMap;
    hmDiv.style.position = 'absolute';
    hmDiv.style.pointerEvents = 'none';
    hmDiv.style.top = '0px';
    hmDiv.style.left = '0px';
    document.body.appendChild(hmDiv);
    for (var i = 0; i < pathsOfCurrentEventBindings.length; i++) {
        var path_str = pathsOfCurrentEventBindings[i];
        var event = sugo.current_event_bindings[path_str];
        var path = event.path.path;
        var eles = document.querySelectorAll(path);
        if (eles && event.heat) {
            let rate = sugo.current_event_bindings[pathsOfCurrentEventBindings[i]].heat;
            let color = {
                'red': differenceColor.red * rate + coldColor.red,
                'green': differenceColor.green * rate + coldColor.green,
                'blue': differenceColor.blue * rate + coldColor.blue
            };
            for (var index = 0; index < eles.length; index++) {
                let div = document.createElement('div');
                div.id = event.event_id;
                div.style.position = 'absolute';
                div.style.pointerEvents = 'none';
                div.style.opacity = 0.8;
                let z = eles[index].style.zIndex;
                div.style.zIndex = z ? parseInt(z) + 1 : defaultZIndex;
                let rect = eles[index].getBoundingClientRect()
                div.style.top = rect.top + 'px';
                div.style.left = rect.left + 'px';
                div.style.width = rect.width + 'px';
                div.style.height = rect.height + 'px';
                div.style.background = `radial-gradient(rgb(${color.red}, ${color.green}, ${color.blue}), white)`;
                hmDiv.appendChild(div);
            }
        }
    }
};
