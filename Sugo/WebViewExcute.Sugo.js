if (sugo.init.code) {
    try {
        var init_code = new Function(sugo.init.code);
        init_code();
    } catch (e) {
        console.log(sugo.init.code);
    }
}

sugo.track('浏览', sugo.view_props);

sugo.trackStayEvent();

sugo.bindEvent();
