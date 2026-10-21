// Dont import css -were using esbuild
//import "../css/app.scss"

import "phoenix_html"
import { Socket } from "phoenix"
import topbar from "topbar"
import { LiveSocket } from "phoenix_live_view"
import Alpine from "alpinejs"
import Clipboard from "@ryangjchandler/alpine-clipboard"

import hooks from './hooks';
let Hooks = hooks
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: {
    _csrf_token: csrfToken
  },
  dom: {
    onBeforeElUpdated(from, to) {
      if (from._x_dataStack) {
        window.Alpine.clone(from, to)
      }
    }
  }
})


// Show progress bar on live navigation & form submits w/ delay of 100 ms
let progressTimeout
topbar.config({
  barColors: {
    0: "#29d"
  },
  shadowColor: "rgba(0, 0, 0, .3)"
})

window.addEventListener("phx:page-loading-start", () => {
  clearTimeout(progressTimeout);
  progressTimeout = setTimeout(topbar.show, 100);
})
window.addEventListener("phx:page-loading-stop", () => {
  clearTimeout(progressTimeout);
  topbar.hide()
})

const setAppHeight = () => document.documentElement.style.setProperty('--app-height', `${window.innerHeight}px`);
window.addEventListener("resize", setAppHeight);
setAppHeight();

Alpine.plugin(Clipboard)
window.Alpine = Alpine
Alpine.start()

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket

// expose a PII mode
window.hidePII = () => {
  if (!document.getElementById('pii-style')) {
    const style = document.createElement('style');
    style.id = 'pii-style';
    style.innerHTML = `
        .pii {
          filter: blur(6px);
        }
      `;
    document.head.appendChild(style);
  }
}

window.showPII = () => {
  const style = document.getElementById('pii-style');
  style && style.remove();
}
