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
import Tribute from "tributejs";
import Chart from 'chart.js/auto';
import {
  EmojiButton
} from '@joeattardi/emoji-button';


let Hooks = {}

class LeafletMap extends HTMLElement {}

customElements.define('leaflet-map', LeafletMap);

class LeafletMarker extends HTMLElement {}
customElements.define('leaflet-marker', LeafletMarker);

class LeafletCircle extends HTMLElement {}
customElements.define('leaflet-circle', LeafletCircle);

Hooks.TasksList = {
  mounted() {
    this.handleEvent("select-task", ({
      id
    }) => {
      this.el.querySelector(`[id="tasks-list:${id}"]`).scrollIntoView({
        behavior: 'auto',
        block: 'nearest',
        inline: 'start'
      })
    })
  }
};
Hooks.RidersList = {
  mounted() {
    this.handleEvent("select-rider", ({
      id
    }) => {
      this.el.querySelector(`[id="riders-list:${id}"]`).scrollIntoView({
        behavior: 'auto',
        block: 'nearest',
        inline: 'start'
      })
    })
  }
};

Hooks.LeafletMapNext = {
  mounted() {
    const template = document.createElement('template');
    template.innerHTML = `
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.6.0/dist/leaflet.css"
    integrity="sha512-xwE/Az9zrjBIphAcBb3F6JVqxf46+CDLwfLMHloNu6KEQCAWi6HcDUbeOfBIptF7tcCzusKFjFw2yuvEpDL9wQ=="
    crossorigin=""/>
    <div style="height: 100%; z-index:0;">
        <slot />
    </div>
`
    L.MakiMarkers.accessToken = this.el.dataset.mapbox_access_token
    this.el.attachShadow({
      mode: 'open'
    });
    this.el.shadowRoot.appendChild(template.content.cloneNode(true));
    this.mapElement = this.el.shadowRoot.querySelector('div')
    let lat = this.el.dataset.lat || "43.6532"
    let lng = this.el.dataset.lng || "-79.3832"

    this.map = L.map(this.mapElement).setView([lat, lng], this.el.dataset.zoom || 13);
    L.tileLayer('https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}', {
      attribution: 'Map data &copy; <a href="https://www.openstreetmap.org/">OpenStreetMap</a> contributors, <a href="https://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery © <a href="https://www.mapbox.com/">Mapbox</a>',
      maxZoom: 18,
      id: 'mapbox/light-v10',
      tileSize: 512,
      zoomOffset: -1,
      accessToken: this.el.dataset.mapbox_access_token,
    }).addTo(this.map)


    let zIndex = 0;
    if (this.el.dataset.zindex != null) {
      zIndex = parseInt(this.el.dataset.zindex);
    }

    this.markers = {};

    this.handleEvent("update-markers", ({
      added,
      removed
    }) => {
      added.forEach(({
        id,
        lat,
        lng,
        icon,
        color,
        clickEvent,
        clickValue,
        clickTarget,
        tooltip
      }) => {
        const marker = L.marker([lat, lng], {
          icon: L.MakiMarkers.icon({
            color: color,
            icon: icon
          }),
          zIndexOffset: zIndex
        });

        if (clickEvent) {
          marker.on('click', e => {
            let payload = clickValue;
            if (clickTarget) {
              this.pushEventTo(clickTarget, clickEvent, payload);
            } else {
              this.pushEvent(clickEvent, payload);
            }
          });
        }

        if (tooltip) {
          marker.bindTooltip(tooltip);
        }

        marker.addTo(this.map);
        this.markers[id] = marker;
      });
      removed.forEach(({
        id
      }) => {
        this.map.removeLayer(this.markers[id]);
        delete this.map[id];
      });
    });

    this.handleEvent("update-marker", ({
      id,
      icon,
      color
    }) => {
      this.markers[id].setIcon(L.MakiMarkers.icon({
        color: color,
        icon: icon
      }))
    });
  },
};


Hooks.LeafletMap = {
  mounted() {
    const template = document.createElement('template');
    template.innerHTML = `
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.6.0/dist/leaflet.css"
    integrity="sha512-xwE/Az9zrjBIphAcBb3F6JVqxf46+CDLwfLMHloNu6KEQCAWi6HcDUbeOfBIptF7tcCzusKFjFw2yuvEpDL9wQ=="
    crossorigin=""/>
    <div style="height: 100%; z-index:0;">
        <slot />
    </div>
`
    L.MakiMarkers.accessToken = this.el.dataset.mapbox_access_token
    this.el.attachShadow({
      mode: 'open'
    });
    this.el.shadowRoot.appendChild(template.content.cloneNode(true));
    this.mapElement = this.el.shadowRoot.querySelector('div')
    let lat = this.el.dataset.lat || "43.6532"
    let lng = this.el.dataset.lng || "-79.3832"

    this.map = L.map(this.mapElement).setView([lat, lng], this.el.dataset.zoom || 13);
    L.tileLayer('https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}', {
      attribution: 'Map data &copy; <a href="https://www.openstreetmap.org/">OpenStreetMap</a> contributors, <a href="https://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery © <a href="https://www.mapbox.com/">Mapbox</a>',
      maxZoom: 18,
      id: 'mapbox/light-v10',
      tileSize: 512,
      zoomOffset: -1,
      accessToken: this.el.dataset.mapbox_access_token,
    }).addTo(this.map)

    this.layers = {}

    this.el.addEventListener('layer:created', e => {
      this.layers[e.detail.id] = e.detail.layer
      e.detail.layer.addTo(this.map)
    })

    this.el.addEventListener('layer:updated', e => {
      if (this.layers[e.detail.id]) {
        this.layers[e.detail.id].removeFrom(this.map)
      }
      this.layers[e.detail.id] = e.detail.layer
      e.detail.layer.addTo(this.map)
    })

    this.el.addEventListener('layer:destroyed', e => {
      if (this.layers[e.detail.id]) {
        this.layers[e.detail.id].removeFrom(this.map)
        delete this.layers[e.detail.id]
      }
    })
  },
};

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

Hooks.LeafletMarker = {
  ...LeafletLayer,
  ...{
    layer() {
      let zIndex = 0;
      if (this.el.dataset.zindex != null) {
        zIndex = parseInt(this.el.dataset.zindex);
      }

      let marker = L.marker([this.el.dataset.lat, this.el.dataset.lng], {
        icon: L.MakiMarkers.icon({
          color: this.el.dataset.color,
          icon: this.el.dataset.icon
        }),
        zIndexOffset: zIndex
      })

      if (this.el.dataset.clickEvent) {
        marker = marker.on('click', e => {
          // TODO: generalize to non-id paramtets
          let payload = null
          if (this.el.dataset.clickValueId) {
            payload = {
              id: this.el.dataset.clickValueId
            }
          }
          // We can have targetted events or ones that go to the view itself
          if (this.el.dataset.clickTarget) {
            this.pushEventTo(this.el.dataset.clickTarget, this.el.dataset.clickEvent, payload)
          } else {
            console.log(this.el.dataset)
            this.pushEvent(this.el.dataset.clickEvent, payload)
          }
        })
      }

      if (tooltip = this.el.dataset.tooltip) {
        marker = marker.bindTooltip(tooltip);
      }
      return marker
    }
  }
};

Hooks.LeafletPolyline = {
  ...LeafletLayer,
  ...{
    layer() {
      return L.polyline([
        [this.el.dataset.from_lat, this.el.dataset.from_lng],
        [this.el.dataset.to_lat, this.el.dataset.to_lng]
      ], {
        color: this.el.dataset.color || "#3388ff"
      });
    }
  }
};

Hooks.LeafletCircle = {
  ...LeafletLayer,
  ...{
    layer() {
      return L.circle([this.el.dataset.lat, this.el.dataset.lng], {
        radius: this.el.dataset.radius,
        color: this.el.dataset.color || "#3388ff"
      })
    }
  }
};

Hooks.ConversationList = {
  mounted() {
    this.handleEvent("select_rider", ({
      id
    }) => {
      if (this.selectedRiderId != undefined) {
        let el = document.getElementById(`conversation-list-item:${this.selectedRiderId}`);
        if (el != undefined) {
          el.classList.remove("bg-gray-100");
        }
      }
      let el = document.getElementById(`conversation-list-item:${id}`);
      if (el != undefined) {
        el.classList.add("bg-gray-100");
      }
      this.selectedRiderId = id;
    });

    this.handleEvent("new_message", ({
      riderId
    }) => {
      let msg = document.getElementById(`conversation-list-item:${riderId}`);
      if (msg != undefined) {
        this.el.prepend(msg)
      }
    });
  }
};

Hooks.MessageList = {
  mounted() {
    // scroll to bottom
    this.el.scrollTop = this.el.scrollHeight;

    this.doneLoading = false;
    this.el.addEventListener("scroll", e => {
      if (!this.doneLoading && this.el.scrollTop == 0) {
        let curScrollheight = this.el.scrollHeight;
        this.pushEventTo(`[id="${this.el.id}"]`, "load-more", {}, ({
          done: done
        }, _ref) => {
          this.doneLoading = done;
          this.el.scrollTop = this.el.scrollHeight - curScrollheight;
        });
      }
    });
    this.handleEvent("new-message", () => {
      // scroll to bottom
      this.el.scrollTop = this.el.scrollHeight;
    });
  }
};

Hooks.Alpine = {
  mounted() {
    this.el.dispatchEvent(new CustomEvent('mounted', {
      bubbles: true
    }));
  },
  updated() {
    this.el.dispatchEvent(new CustomEvent('updated', {
      bubbles: true
    }));
  },
};

Hooks.Autocomplete = {
  mounted() {
    let autocompletes = JSON.parse(this.el.dataset.autocomplete)
    let tribute = new Tribute({
      trigger: '{',
      values: autocompletes.map(s => {
        return {
          key: s,
          value: `{{${s}}}}`
        }
      })
    });

    tribute.attach(this.el)
  }
};

Hooks.Chart = {
  mounted() {
    this.chart = new Chart(this.el, {
      type: 'line',
      options: {
        scales: {
          y: {
            beginAtZero: true
          }
        }
      }
    });

    this.handleEvent("update-chart", (data) => {
      this.chart.data = data;
      this.chart.update();
    })
  }
};

Hooks.FrameHook = {
  mounted() {
    const resizeObserver = new ResizeObserver(_entries => {
      window.parent.postMessage({
        height: this.el.scrollHeight
      }, "*");
    });

    resizeObserver.observe(this.el);
    window.parent.postMessage({
      height: this.el.scrollHeight
    }, "*");
  }
}


Hooks.TagsComponentHook = {
  mounted() {
    this.el.addEventListener('keydown', e => {
      if (e.key == 'Enter') {
        e.preventDefault();
        this.pushEventTo(this.el, 'select', {
          name: this.el.value
        })
        this.el.value = ""
      }
    });
  }
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

Hooks.EmojiButtonHook = {
  mounted() {
    const picker = new EmojiButton();
    const inputEl = document.querySelector(`#${this.el.dataset.inputId}`);
    if (inputEl === undefined) {
      console.warn("Input element for EmojiButton ", this.el.id, " not found. Emoji button disabled.")
      return;
    }

    picker.on("emoji", selection => {
      inputEl.value += selection.emoji;
    });

    picker.on("hidden", () => {
      const end = inputEl.value.length;
      inputEl.setSelectionRange(end, end);
      inputEl.focus();
    });
    this.el.addEventListener("click", () => picker.togglePicker(this.el));
  }
}

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
  progressTimeout = setTimeout(topbar.show, 100)
})
window.addEventListener("phx:page-loading-stop", () => {
  clearTimeout(progressTimeout);
  topbar.hide()
})

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