/* 
  UIWebViewTrack.js
  Sugo

  Created by Zack on 6/1/17.
  Copyright © 2017年 sugo. All rights reserved.
*/
sugo = {};
sugo.track = function(event_id, event_name, props) {
    WebViewJSExport.trackOfIdNameProperties(event_id, event_name, JSON.stringify(props));
};

sugo.timeEvent = function(event_name) {
    WebViewJSExport.timeOfEvent(event_name);
};

sugo.track('', 'h5_enter_page_event', {
           page: window.location.pathname
           });

sugo.enter_time = new Date().getTime();

window.addEventListener('beforeunload', function(e) {
                        var duration = (new Date().getTime() - sugo.enter_time) / 1000;
                        sugo.track('', 'h5_stay_event', {
                                   page: window.location.pathname,
                                   duration: duration
                                   });
                        });
