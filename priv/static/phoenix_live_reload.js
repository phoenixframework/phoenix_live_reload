var buildFreshUrl = function(url) {
  var date = Math.round(Date.now() / 1000).toString();
  url = url.replace(/(\&|\\?)vsn=\d*/, '');
  return url + (url.indexOf('?') >= 0 ? '&' : '?') +'vsn=' + date;
};

var repaint = function() {
  var browser = navigator.userAgent.toLowerCase();

  if(browser.indexOf('chrome') > -1) setTimeout( function() { document.body.offsetHeight; }, 25);
};

var cssStrategy = function() {
  [].slice
    .call(window.top.document.querySelectorAll('link[rel=stylesheet]'))
    .filter(function(link) { return link.href })
    .forEach(function(link) { link.href = buildFreshUrl(link.href) });

  repaint();
};

var defaultStrategy = function(chan) {
  chan.off("assets_change");
  window.top.location.reload();
};

var reloadStrategies = {
  css: cssStrategy,
  default: defaultStrategy
};

socket.connect();
socket.join("phoenix:live_reload", {}).receive("ok", function(chan) {
  chan.on("assets_change", function(msg) {
    var reloadStrategy = reloadStrategies[msg.asset_type] || reloadStrategies.default;
    reloadStrategy(chan);
  });
});
