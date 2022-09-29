defmodule BikeBrigadeWeb.EmbedTestView do
  use BikeBrigadeWeb, :view

  attr :src, :string, required: true

  def iframe(assigns) do
    ~H"""
    <iframe
      id="calendar-iframe"
      name="calendar-iframe"
      sandbox="allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox"
      allowtransparency="true"
      scrolling="no"
      frameBorder="0"
      style="width:100%;border:none;"
      src={@src}
    >
    </iframe>
    """
  end

  attr :origin, :string, required: true

  def script(assigns) do
    ~H"""
    <script>
      window.addEventListener("message", (event) => {
      if (event.origin === '<%= @origin %>') {
        document.getElementById("calendar-iframe").style.height = event.data.height + 'px';
      }
      }, false);
    </script>
    """
  end
end
