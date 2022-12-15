import Tribute from "tributejs";

export default {
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
}
