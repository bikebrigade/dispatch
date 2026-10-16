export default {
  mounted() {
    this.resize = () => {
      const pane = this.el.querySelector('#inbox-workspace');
      if (pane) this.el.style.setProperty('--inbox-workspace-height', `${Math.max(320, window.innerHeight - pane.getBoundingClientRect().top - 24)}px`);
    };
    window.addEventListener('resize', this.resize);
    this.handleEvent('inbox:sent', () => {
      const input = this.el.querySelector('#group-message-body');
      if (input) input.value = '';
      const drawer = this.el.querySelector('#everyone-drawer');
      if (drawer) drawer.style.display = 'none';
    });
    this.resize();
  },
  updated() { this.resize(); },
  destroyed() { window.removeEventListener('resize', this.resize); }
};
