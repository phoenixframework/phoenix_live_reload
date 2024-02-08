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

var SESSION_STORAGE_SCROLL_Y_KEY = '__phoenix_live_reload_scroll_y';

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

  if (restoreScrollOnReload && reloadStrategy === pageStrategy) {
    sessionStorage.setItem(SESSION_STORAGE_SCROLL_Y_KEY, window[targetWindow].scrollY);
  }

  setTimeout(function(){ reloadStrategy(chan); }, interval);
});

var optionallyRestoreScroll = function() {
  if (restoreScrollOnReload) {
    const scrollYSerialized = sessionStorage.getItem(SESSION_STORAGE_SCROLL_Y_KEY)

    if (scrollYSerialized) {
      const scrollY = parseInt(scrollYSerialized, 10)

      window[targetWindow].scrollTo(0, scrollY);
      sessionStorage.removeItem(SESSION_STORAGE_SCROLL_Y_KEY);
    }
  }
}

chan
  .join()
  .receive('ok', optionallyRestoreScroll);
