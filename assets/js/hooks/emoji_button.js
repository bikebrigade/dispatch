import { EmojiButton as emojiButton } from '@joeattardi/emoji-button';

const EmojiButton = {
  mounted() {
    const picker = new emojiButton({zIndex: 100, rootElement: this.el.closest('[phx-click-away]') || document.body});
    const inputEl = document.querySelector(`#${this.el.dataset.inputId}`);
    if (!inputEl) {
      console.warn("Input element for EmojiButton ", this.el.id, " not found. Emoji button disabled.")
      return;
    }

    picker.on("emoji", selection => {
      inputEl.value += selection.emoji;
      inputEl.dispatchEvent(new Event("input", {bubbles: true}));
    });

    picker.on("hidden", () => {
      const end = inputEl.value.length;
      inputEl.setSelectionRange(end, end);
      inputEl.focus();
    });
    this.el.addEventListener("click", () => picker.togglePicker(this.el));
  }

};

export default EmojiButton;
