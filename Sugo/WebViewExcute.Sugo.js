    sugo.init_path();
    if (sugo.can_track_web_page) {
        sugo.track('浏览', sugo.view_props);
        sugo.trackStayEvent();
    }
    sugo.bindEvent();
    window.addEventListener('hashchange', function() {
        sugo.view_props = {};
        sugo.init_path();
        if (sugo.can_track_web_page) {
            sugo.track('浏览', sugo.view_props);
            sugo.trackStayEvent();
        }
    })
    
