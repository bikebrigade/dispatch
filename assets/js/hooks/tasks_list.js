const TasksList = {
  mounted() {
    this.handleEvent("select_task", ({
      id
    }) => {
      this.el.querySelector(`[id="tasks-list:${id}"]`).scrollIntoView({
        behavior: 'auto',
        block: 'nearest',
        inline: 'start'
      })
    })
  }
};

export default TasksList;
