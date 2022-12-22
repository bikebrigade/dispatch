import L from "leaflet"
import "leaflet-makimarkers"

const LeafletMap = {
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

    const addLayer = ({
      id,
      type,
      data
    }) => {
      if (this.layers[id] === undefined) {
        if (type == "marker") {
          let {
            lat,
            lng,
            icon,
            color,
            clickEvent,
            clickValue,
            clickTarget,
            tooltip
          } = data;
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
          this.layers[id] = marker;
        } else if (type == "polyline") {
          let {
            latlngs,
            color,
          } = data;
          const polyline = L.polyline(latlngs, {
            color: color,
            zIndexOffset: zIndex
          });

          polyline.addTo(this.map);
          this.layers[id] = polyline;
        }
      }
    };

    this.layers = {};

    let initialLayers = JSON.parse(this.el.dataset.initial_layers);
    initialLayers.forEach(addLayer);

    this.handleEvent("add_layers", ({
      layers
    }) => layers.forEach(addLayer));

    this.handleEvent("remove_layers", ({
      layers
    }) => {
      layers.forEach(({
        id
      }) => {
        if (this.layers[id]) {
          this.map.removeLayer(this.layers[id]);
          delete this.layers[id];
        }
      });
    });

    this.handleEvent("update_layer", ({
      id,
      type,
      data
    }) => {
      if (type == "marker") {
        let {
          icon,
          color,
          lat,
          lng
        } = data;

        if (icon === undefined) {
          icon = this.layers[id].getIcon().options.icon
        }

        this.layers[id].setIcon(L.MakiMarkers.icon({
          color: color,
          icon: icon
        }));

        if (lat && lng) {
          this.layers[id].setLatLng([lat, lng]);
        }
      }
    });

    this.handleEvent("redraw_map", ({
      recenter
    }) => {
      if (recenter) {
        let lat = this.el.dataset.lat || "43.6532"
        let lng = this.el.dataset.lng || "-79.3832"
        this.map.setView([lat, lng], this.el.dataset.zoom || 13);
      }

      this.map.invalidateSize()

    });
  },
};

export default LeafletMap;
