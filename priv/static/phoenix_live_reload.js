var buildFreshUrl = function(link){
  var date = Math.round(Date.now() / 1000).toString();
  var url = link.href.replace(/(\&|\\?)vsn=\d*/, '');
  var newLink = document.createElement('link');
  var onComplete = function() {
    if (link.parentNode !== null) {
      link.parentNode.removeChild(link);
    }
  };

  newLink.onerror = onComplete;
  newLink.onload  = onComplete;
  link.setAttribute('data-pending-removal', '');
  newLink.setAttribute('rel', 'stylesheet');
  newLink.setAttribute('type', 'text/css');
  newLink.setAttribute('href', url + (url.indexOf('?') >= 0 ? '&' : '?') +'vsn=' + date);
  link.parentNode.insertBefore(newLink, link.nextSibling);

  return newLink;
};

var repaint = function(){
  var browser = navigator.userAgent.toLowerCase();
  if(browser.indexOf('chrome') > -1){
    setTimeout(function(){ document.body.offsetHeight; }, 25);
  }
};

var cssStrategy = function(){
  var reloadableLinkElements = window.parent.document.querySelectorAll(
    'link[rel=stylesheet]:not([data-no-reload]):not([data-pending-removal])'
  );

  [].slice
    .call(reloadableLinkElements)
    .filter(function(link) { return link.href })
    .forEach(function(link) { buildFreshUrl(link) });

  repaint();
};

var pageStrategy = function(chan){
  chan.off('assets_change');
  window[targetWindow].location.reload();
};

var reloadStrategies = {
  css: reloadPageOnCssChanges ? pageStrategy : cssStrategy,
  page: pageStrategy
};

socket.connect();
var chan = socket.channel('phoenix:live_reload', {})
chan.on('assets_change', function(msg) {
  var reloadStrategy = reloadStrategies[msg.asset_type] || reloadStrategies.page;
  setTimeout(function(){ reloadStrategy(chan); }, interval);
});
chan.join();
