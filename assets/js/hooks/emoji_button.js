import { EmojiButton as emojiButton } from '@joeattardi/emoji-button';

const EmojiButton = {
  mounted() {
    const picker = new emojiButton();
    const inputEl = document.querySelector(`#${this.el.dataset.inputId}`);
    if (inputEl === undefined) {
      console.warn("Input element for EmojiButton ", this.el.id, " not found. Emoji button disabled.")
      return;
    }

    picker.on("emoji", selection => {
      inputEl.value += selection.emoji;
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
