export default {
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
}
