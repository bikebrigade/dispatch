export default {
  mounted() {
    this.el.addEventListener("scroll", e => {
      gap = this.el.scrollHeight - this.el.scrollTop - this.el.clientHeight;
      if (gap < 10) {
        this.pushEventTo(`[id="${this.el.id}"]`, "load_more", {}, (_reply, _ref) => {
          // do something on event return?
        });
      }
    });
  }
}
