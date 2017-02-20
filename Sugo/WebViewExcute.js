if (sugo.init.code) {
    try {
        var init_code = new Function(sugo.init.code);
        init_code();
    } catch (e) {
        console.log(sugo.init.code);
    }
}

sugo.track('浏览', sugo.view_props);
sugo.enter_time = new Date().getTime();

window.addEventListener('beforeunload', function(e) {
    var duration = (new Date().getTime() - sugo.enter_time) / 1000;
    sugo.track('停留', {
        duration: duration
    });
    sugo.track('页面退出');
});

sugo.bindEvent();
