// Clamps content to a max height and shows a "Show More" toggle when it overflows.
// Used by the `collapsible` component in CoreComponents.
const Collapsible = {
  mounted() {
    this.collapsed = true;
    this.el.querySelector("[data-collapsible-toggle]").addEventListener("click", () => {
      this.collapsed = !this.collapsed;
      this.render();
    });
    this.render();
  },
  updated() {
    // LiveView patches reset our classes to the server-rendered (collapsed) state
    this.render();
  },
  render() {
    const content = this.el.querySelector("[data-collapsible-content]");
    const controls = this.el.querySelector("[data-collapsible-controls]");
    const toggle = this.el.querySelector("[data-collapsible-toggle]");
    const collapsedClass = this.el.dataset.collapsedClass;

    // Measure overflow in the collapsed state so the toggle stays visible when expanded
    content.classList.add(collapsedClass);
    const overflows = content.scrollHeight > content.clientHeight;
    content.classList.toggle(collapsedClass, this.collapsed);

    controls.classList.toggle("hidden", !overflows);
    for (const cls of ["absolute", "inset-x-0", "bottom-0"]) {
      controls.classList.toggle(cls, this.collapsed);
    }
    toggle.textContent = this.collapsed ? "Show More..." : "Show Less";
  },
};

export default Collapsible;
