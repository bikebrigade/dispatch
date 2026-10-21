// Sizes the inbox workspace to fill the window below the tabs.
const MessagingInbox = {
  mounted() {
    this.resize = () => {
      const pane = this.el.querySelector("#inbox-workspace");
      if (pane) {
        const height = Math.max(320, window.innerHeight - pane.getBoundingClientRect().top - 24);
        this.el.style.setProperty("--inbox-workspace-height", `${height}px`);
      }
    };
    window.addEventListener("resize", this.resize);
    this.resize();
  },
  updated() {
    this.resize();
  },
  destroyed() {
    window.removeEventListener("resize", this.resize);
  }
};

export default MessagingInbox;
