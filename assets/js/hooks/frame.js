const FrameHook = {
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
  };
  
  export default FrameHook;
}
