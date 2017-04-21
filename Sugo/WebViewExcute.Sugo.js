    sugo.init_path();
    if (sugo.can_track_web_page) {
        sugo.track('浏览', sugo.view_props);
        sugo.trackStayEvent();
    }
    sugo.bindEvent();
    if (!window.sugo) {
        window.addEventListener('hashchange', function() {
            sugo.view_props = {};
            sugo.init_path();
            if (sugo.can_track_web_page) {
                sugo.track('浏览', sugo.view_props);
                sugo.trackStayEvent();
            }
        })
    }
    