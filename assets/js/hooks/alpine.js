
const Alpine = {
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

export default Alpine;
