export default {
  updated() {
    const numChecked = parseInt(this.el.dataset.numChecked);
    const numRows = parseInt(this.el.dataset.numRows);

    if (numChecked === 0) {
      this.el.checked = false;
      this.el.indeterminate = false;
    } else if (numChecked === numRows) {
      this.el.checked = true;
      this.el.indeterminate = false;
    } else {
      this.el.checked = false;
      this.el.indeterminate = true;
    }
  }
}
