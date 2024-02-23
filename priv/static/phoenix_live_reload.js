let buildFreshUrl = (link) => {
  let date = Math.round(Date.now() / 1000).toString()
  let url = link.href.replace(/(\&|\\?)vsn=\d*/, "")
  let newLink = document.createElement('link')
  let onComplete = () => {
    if(link.parentNode !== null){
      link.parentNode.removeChild(link)
    }
  }

  newLink.onerror = onComplete
  newLink.onload  = onComplete
  link.setAttribute("data-pending-removal", "")
  newLink.setAttribute("rel", "stylesheet");
  newLink.setAttribute("type", "text/css");
  newLink.setAttribute("href", url + (url.indexOf("?") >= 0 ? "&" : "?") + "vsn=" + date)
  link.parentNode.insertBefore(newLink, link.nextSibling)
  return newLink
}

let repaint = () => {
  let browser = navigator.userAgent.toLowerCase()
  if(browser.indexOf("chrome") > -1){
    setTimeout(() => document.body.offsetHeight, 25)
  }
}

let cssStrategy = () => {
  let reloadableLinkElements = window.parent.document.querySelectorAll(
    "link[rel=stylesheet]:not([data-no-reload]):not([data-pending-removal])"
  )

  ([].slice).call(reloadableLinkElements)
    .filter(link => link.href)
    .forEach(link => buildFreshUrl(link))

  repaint()
};

let pageStrategy = channel => {
  channel.off("assets_change")
  window[targetWindow].location.reload()
}

let reloadStrategies = {
  css: reloadPageOnCssChanges ? pageStrategy : cssStrategy,
  page: pageStrategy
};

class LiveReloader {
  constructor(socket){
    this.socket = socket
    this.logsEnabled = false
    this.enabledOnce = false
    this.editorURL = null
    this.relativePath = null
  }
  enable(){
    this.socket.onOpen(() => {
      if(this.enabledOnce){ return }
      this.enabledOnce = true
      if(["complete", "loaded", "interactive"].indexOf(parent.document.readyState) >= 0){
        this.dispatchConnected()
      } else {
        parent.addEventListener("load", () => this.dispatchConnected())
      }
    })

    this.channel = socket.channel("phoenix:live_reload", {})
    this.channel.on("assets_change", msg => {
      let reloadStrategy = reloadStrategies[msg.asset_type] || reloadStrategies.page
      setTimeout(() => reloadStrategy(this.channel), interval)
    })
    this.channel.on("log", ({msg, level}) => this.logsEnabled && this.log(level, msg))
    this.channel.join().receive("ok", ({editor_url, relative_path}) => {
      this.editorURL = editor_url
      this.relativePath = relative_path
    })
    this.socket.connect()
  }

  disable(){
    this.channel.leave()
    socket.disconnect()
  }

  enableServerLogs(){ this.logsEnabled = true }
  disableServerLogs(){ this.logsEnabled = false }

  openEditor(targetNode){
    let fileLine = this.editorURL && this.closestDebugFileLine(targetNode)
    if(fileLine){
      let [file, line] = fileLine.split(":")
      let fullPath = [this.relativePath, file].join("/")
      let url = this.editorURL.replace("__FILE__", fullPath).replace("__LINE__", line)
      window.open(url, "_self")
    }
  }

  // private

  dispatchConnected(){
    parent.dispatchEvent(new CustomEvent("phx:live_reload:connected", {detail: this}))
  }

  log(level, str){
    let levelColor = {debug: "cyan", info: "inherit", error: "inherit"}[level]
    let consoleFunc = level === "debug" ? "info" : level
    console[consoleFunc](`%c📡 [${level}] ${str}`, `color: ${levelColor};`)
  }

  closestDebugFileLine(node){
    while(node.previousSibling){
      node = node.previousSibling
      if(node.nodeType === Node.COMMENT_NODE){
        let match = node.nodeValue.match(/.*>\s([\w\/]+.*ex:\d+)/i)
        if(match){ return match[1] }
      }
    }
    if(node.parentNode){ return this.closestDebugFileLine(node.parentNode) }
  }
}

reloader = new LiveReloader(socket)
reloader.enable()
