var buildFreshUrl = function(link) {
  var date = Math.round(Date.now() / 1000).toString();
  var url = link.href.replace(/(\&|\\?)vsn=\d*/, '');

  l = document.createElement('link');
  l.setAttribute('rel', 'stylesheet');
  l.setAttribute('type', 'text/css');
  l.setAttribute('href', url + (url.indexOf('?') >= 0 ? '&' : '?') +'vsn=' + date);
  top.document.head.appendChild(l);

  l.onload = function(){
    link.remove();
  };

  return l;
};

var repaint = function() {
  var browser = navigator.userAgent.toLowerCase();
  if(browser.indexOf('chrome') > -1) setTimeout( function() { document.body.offsetHeight; }, 25);
};

var cssStrategy = function() {
  [].slice
    .call(window.top.document.querySelectorAll('link[rel=stylesheet]:not([data-no-reload])'))
    .filter(function(link) { return link.href })
    .forEach(function(link) { buildFreshUrl(link) });

  repaint();
};

var defaultStrategy = function(chan) {
  chan.off('assets_change');
  window.top.location.reload();
};

var reloadStrategies = {
  css: cssStrategy,
  default: defaultStrategy
};

socket.connect();
var chan = socket.chan('phoenix:live_reload', {})
chan.on('assets_change', function(msg) {
  var reloadStrategy = reloadStrategies[msg.asset_type] || reloadStrategies.default;
  reloadStrategy(chan);
});
chan.join();
