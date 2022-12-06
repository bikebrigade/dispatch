defmodule BikeBrigadeWeb.Components.Icons do
  use Phoenix.Component

  def maki_bicycle_15(assigns) do
    assigns = assign(assigns, :attrs, assigns_to_attributes(assigns))

    ~H"""
    <svg {@attrs} stroke="none" fill="currentColor" viewBox="0 0 15 15">
      <path d="&#xA;&#x9;M7.5,2c-0.6761-0.01-0.6761,1.0096,0,1H9v1.2656l-2.8027,2.334L5.2226,4H5.5c0.6761,0.01,0.6761-1.0096,0-1h-2&#xA;&#x9;c-0.6761-0.01-0.6761,1.0096,0,1h0.6523L5.043,6.375C4.5752,6.1424,4.0559,6,3.5,6C1.5729,6,0,7.5729,0,9.5S1.5729,13,3.5,13&#xA;&#x9;S7,11.4271,7,9.5c0-0.6699-0.2003-1.2911-0.5293-1.8242L9.291,5.3262l0.4629,1.1602C8.7114,7.0937,8,8.2112,8,9.5&#xA;&#x9;c0,1.9271,1.5729,3.5,3.5,3.5S15,11.4271,15,9.5S13.4271,6,11.5,6c-0.2831,0-0.5544,0.0434-0.8184,0.1074L10,4.4023V2.5&#xA;&#x9;c0-0.2761-0.2239-0.5-0.5-0.5H7.5z M3.5,7c0.5923,0,1.1276,0.2119,1.5547,0.5527l-1.875,1.5625&#xA;&#x9;c-0.5109,0.4273,0.1278,1.1945,0.6406,0.7695l1.875-1.5625C5.8835,8.674,6,9.0711,6,9.5C6,10.8866,4.8866,12,3.5,12S1,10.8866,1,9.5&#xA;&#x9;S2.1133,7,3.5,7L3.5,7z M11.5,7C12.8866,7,14,8.1134,14,9.5S12.8866,12,11.5,12S9,10.8866,9,9.5c0-0.877,0.4468-1.6421,1.125-2.0879&#xA;&#x9;l0.9102,2.2734c0.246,0.6231,1.1804,0.2501,0.9297-0.3711l-0.9082-2.2695C11.2009,7.0193,11.3481,7,11.5,7L11.5,7z" />
    </svg>
    """
  end

  def maki_bicycle_share(assigns) do
    assigns = assign(assigns, :attrs, assigns_to_attributes(assigns))

    ~H"""
    <svg {@attrs} stroke="none" fill="currentColor" viewBox="0 0 15 15">
      <path d="&#xA;&#x9;M10,1C9.4477,1,9,1.4477,9,2c0,0.5523,0.4477,1,1,1s1-0.4477,1-1C11,1.4477,10.5523,1,10,1z M8.1445,2.9941&#xA;&#x9;c-0.13,0.0005-0.2547,0.0517-0.3477,0.1426l-2.6406,2.5c-0.2256,0.2128-0.2051,0.5775,0.043,0.7637L7,7.75v2.75&#xA;&#x9;c-0.01,0.6762,1.0096,0.6762,1,0v-3c0.0003-0.1574-0.0735-0.3057-0.1992-0.4004L7.0332,6.5234l1.818-1.7212l0.7484,0.9985&#xA;&#x9;C9.6943,5.9265,9.8426,6.0003,10,6h1.5c0.6761,0.01,0.6761-1.0096,0-1h-1.25L9.5,4L8.9004,3.1992&#xA;&#x9;C8.8103,3.0756,8.6685,3,8.5156,2.9941H8.1445z M3,7c-1.6569,0-3,1.3432-3,3s1.3431,3,3,3s3-1.3432,3-3S4.6569,7,3,7z M12,7&#xA;&#x9;c-1.6569,0-3,1.3432-3,3s1.3431,3,3,3s3-1.3432,3-3S13.6569,7,12,7z M3,8c1.1046,0,2,0.8954,2,2s-0.8954,2-2,2s-2-0.8954-2-2&#xA;&#x9;S1.8954,8,3,8z M12,8c1.1046,0,2,0.8954,2,2s-0.8954,2-2,2s-2-0.8954-2-2S10.8954,8,12,8z" />
    </svg>
    """
  end

  def tailwindui_upload_photo(assigns) do
    assigns = assign(assigns, :attrs, assigns_to_attributes(assigns))

    ~H"""
    <svg {@attrs} stroke="currentColor" fill="none" viewBox="0 0 48 48">
      <path
        d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02"
        stroke-width="2"
        stroke-linecap="round"
        stroke-linejoin="round"
      />
    </svg>
    """
  end

  def circle(assigns) do
    assigns = assign(assigns, :attrs, assigns_to_attributes(assigns))

    ~H"""
    <svg {@attrs} class="w-2 h-2" fill="currentColor" viewBox="0 0 8 8">
      <circle cx="4" cy="4" r="3" />
    </svg>
    """
  end

  def sort(%{order: :desc} = assigns) do
    assigns = assign(assigns, :attrs, assigns_to_attributes(assigns, [:order]))

    ~H"""
    <svg
      {@attrs}
      fill="none"
      stroke="currentColor"
      viewBox="0 0 24 24"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M3 4h13M3 8h9m-9 4h9m5-4v12m0 0l-4-4m4 4l4-4"
      >
      </path>
    </svg>
    """
  end

  def sort(%{order: :asc} = assigns) do
    assigns = assign(assigns, :attrs, assigns_to_attributes(assigns, [:order]))

    ~H"""
    <svg
      {@attrs}
      fill="none"
      stroke="currentColor"
      viewBox="0 0 24 24"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M3 4h13M3 8h9m-9 4h6m4 0l4-4m0 0l4 4m-4-4v12"
      >
      </path>
    </svg>
    """
  end
end
