export default {
  mounted() {
    this.handleEvent("select_rider", ({
      id
    }) => {
      if (this.selectedRiderId != undefined) {
        let el = document.getElementById(`conversation-list-item:${this.selectedRiderId}`);
        if (el != undefined) {
          el.classList.remove("bg-gray-100");
        }
      }
      let el = document.getElementById(`conversation-list-item:${id}`);
      if (el != undefined) {
        el.classList.add("bg-gray-100");
      }
      this.selectedRiderId = id;
    });

    this.handleEvent("new_message", ({
      riderId
    }) => {
      let msg = document.getElementById(`conversation-list-item:${riderId}`);
      if (msg != undefined) {
        this.el.prepend(msg)
      }
    });
  }
}
