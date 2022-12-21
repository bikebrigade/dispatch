import Tribute from "tributejs";

const Autocomplete = {
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

export default Autocomplete;
