// Dont import css -were using esbuild
//import "../css/app.scss"

import "phoenix_html"
import {
  Socket
} from "phoenix"
import topbar from "topbar"
import {
  LiveSocket
} from "phoenix_live_view"


import L from "leaflet"
import "leaflet-makimarkers"
import "@ryangjchandler/alpine-clipboard"
import "alpinejs"

import hooks from './hooks';

let Hooks = hooks

//REVIEW: LeafletLayer is not being used anywhere? Can I remove?
// Base object for layer callbacks
const LeafletLayer = {
  mounted() {
    this.mapEl = this.el.closest("leaflet-map")
    this.mapEl.dispatchEvent(new CustomEvent('layer:created', {
      detail: {
        id: this.el.id,
        layer: this.layer()
      }
    }));
  },

  updated() {
    this.mapEl.dispatchEvent(new CustomEvent('layer:updated', {
      detail: {
        id: this.el.id,
        layer: this.layer()
      }
    }));
  },

  destroyed() {
    this.mapEl.dispatchEvent(new CustomEvent('layer:destroyed', {
      detail: {
        id: this.el.id,
        layer: this.layer()
      }
    }));
  },
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: {
    _csrf_token: csrfToken
  },
  dom: {
    onBeforeElUpdated(from, to) {
      if (from.__x) {
        window.Alpine.clone(from.__x, to)
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

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket

// REVIEW: I can't find hidePII or showPII used anywhere. Can we remove?
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
