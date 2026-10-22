// Copies the element's `data-content` to the clipboard on click.
const CopyToClipboard = {
  mounted() {
    this.el.addEventListener("click", () => {
      navigator.clipboard.writeText(this.el.dataset.content);
    });
  },
};

export default CopyToClipboard;
