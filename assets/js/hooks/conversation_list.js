const ConversationList = {
  mounted() {
    this.handleEvent("conversation_list:select_rider", ({
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

    this.handleEvent("conversation_list:new_message", ({
      riderId
    }) => {
      let msg = document.getElementById(`conversation-list-item:${riderId}`);
      if (msg != undefined) {
        this.el.prepend(msg)
      }
    });

    this.handleEvent("conversation_list:only_show", ({
      ids
    }) => {
      Array.from(this.el.children).forEach((item) => {
        if (ids.includes(parseInt(item.dataset.riderId))) {
          item.classList.remove("hidden");
        } else {
          item.classList.add("hidden");
        }
      });
    });

    this.handleEvent("conversation_list:clear_search", ({}) => {
      document.getElementById("rider-search").value = ""
      Array.from(this.el.children).forEach((item) => {
        item.classList.remove("hidden");
      });
    });
  }
};

export default ConversationList;