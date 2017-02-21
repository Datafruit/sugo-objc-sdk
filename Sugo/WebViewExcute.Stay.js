if (sugo && sugo.track) {
    var duration = (new Date().getTime() - sugo.enter_time) / 1000;
    sugo.track('HTML停留', {
               duration: duration
               });
}
