	sugo.init_path();
	if (sugo.can_track_web_page) {
		sugo.track('浏览', sugo.view_props);
		sugo.enter_time = new Date().getTime();
	}
	sugo.bindEvent();
	sugo.showHeatMap();
	if (!window.sugo) {
		window.addEventListener('hashchange', function() {
			sugo.view_props = {};
			sugo.init_path();
			sugo.showHeatMap();
			if (sugo.can_track_web_page) {
				sugo.track('浏览', sugo.view_props);
				sugo.enter_time = new Date().getTime();
			}
		})
	}
