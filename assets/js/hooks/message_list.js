export default {
  mounted() {
    // scroll to bottom
    this.el.scrollTop = this.el.scrollHeight;

    this.doneLoading = false;
    this.el.addEventListener("scroll", e => {
      if (!this.doneLoading && this.el.scrollTop == 0) {
        let curScrollheight = this.el.scrollHeight;
        this.pushEventTo(`[id="${this.el.id}"]`, "load_more", {}, ({
          done: done
        }, _ref) => {
          this.doneLoading = done;
          this.el.scrollTop = this.el.scrollHeight - curScrollheight;
        });
      }
    });
    this.handleEvent("new_message", () => {
      // scroll to bottom
      this.el.scrollTop = this.el.scrollHeight;
    });
  }
}
