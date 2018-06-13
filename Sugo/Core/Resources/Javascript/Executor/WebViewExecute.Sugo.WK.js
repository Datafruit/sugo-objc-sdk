    sugo.init_path();
    sugo.trackBrowseEvent();
    sugo.bindEvent();
    sugo.showHeatMap();
    if (!window.sugo) {
        window.addEventListener('hashchange', function() {
            sugo.view_props = {};
            sugo.init_path();
            sugo.showHeatMap();
            sugo.trackBrowseEvent();
        })
    }
