export default {
  mounted() {
    this.handleEvent("select_rider", ({
      id
    }) => {
      this.el.querySelector(`[id="riders-list:${id}"]`).scrollIntoView({
        behavior: 'auto',
        block: 'nearest',
        inline: 'start'
      })
    })
  }
}
