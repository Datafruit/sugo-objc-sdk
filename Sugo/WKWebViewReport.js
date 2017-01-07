/* 
  WKWebViewReport.js
  Sugo

  Created by Zack on 6/1/17.
  Copyright © 2017年 sugo. All rights reserved.
 */
var sugo_report = {};
sugo_report.clientWidth = (window.innerWidth || document.documentElement.clientWidth);
sugo_report.clientHeight = (window.innerHeight || document.documentElement.clientHeight);
sugo_report.isElementInViewport = function(rect) {
    return (
            rect.top >= 0 &&
            rect.left >= 0 &&
            rect.bottom <= sugo_report.clientHeight &&
            rect.right <= sugo_report.clientWidth
            );
};
sugo_report.handleNodeChild = function(childrens, jsonArray, parent_path, type) {
    var index_map = {};
    for (var i = 0; i < childrens.length; i++) {
        var children = childrens[i];
        var path = sugo_utils.cssPath(children);
        var htmlNode = {};
        htmlNode.path = path;
        var rect = children.getBoundingClientRect();
        if (sugo_report.isElementInViewport(rect) == true) {
            var temp_rect = {
            top: rect.top,
            left: rect.left,
            width: rect.width,
            height: rect.height
            };
            htmlNode.rect = temp_rect;
            jsonArray.push(htmlNode);
        }
        
        if (children.children) {
            sugo_report.handleNodeChild(children.children, jsonArray, path, type);
        }
    }
};
sugo_report.reportNodes = function() {
    var jsonArray = [];
    var body = document.getElementsByTagName('body')[0];
    var childrens = body.children;
    var parent_path = '';
    sugo_report.handleNodeChild(childrens, jsonArray, parent_path, 'report');
    var message = {
        'path' : window.location.pathname,
        'clientWidth' : sugo_report.clientWidth,
        'clientHeight' : sugo_report.clientHeight,
        'nodes' : JSON.stringify(jsonArray)
    };
    window.webkit.messageHandlers.WKWebViewReporter.postMessage(message);
};
