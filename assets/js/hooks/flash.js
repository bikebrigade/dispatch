const Flash = {
  mounted() {
    this.scheduleDismissal();
  },

  updated() {
    // Unrelated LiveView patches must not postpone dismissal.
    if (this.message !== this.el.textContent || this.delay !== this.el.dataset.dismissAfter) {
      this.liveSocket.execJS(this.el, this.el.dataset.show);
      this.scheduleDismissal();
    }
  },

  destroyed() {
    clearTimeout(this.dismissTimer);
  },

  scheduleDismissal() {
    clearTimeout(this.dismissTimer);
    this.message = this.el.textContent;
    this.delay = this.el.dataset.dismissAfter;

    if (Number(this.delay) > 0) {
      this.dismissTimer = setTimeout(() => {
        // Use the manual dismissal action to clear server flash state as well as hide it.
        this.liveSocket.execJS(this.el, this.el.getAttribute("phx-click"));
      }, Number(this.delay));
    }
  },
};

export default Flash;
