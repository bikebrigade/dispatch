defmodule BikeBrigade.Notifications.BannerScrubber do
  @moduledoc """
  HTML allowlist for banner messages, which riders see on their home page.

  Keeps simple text formatting and links (http, https, mailto, tel); strips
  every other tag, all other attributes (event handlers, styles, ...), and
  any other URL scheme such as `javascript:`.
  """

  use HtmlSanitizeEx

  allow_tag_with_uri_attributes("a", ["href"], ["http", "https", "mailto", "tel"])
  allow_tag_with_these_attributes("a", ["title", "class"])
  # Only _blank: browsers give it implicit noopener, while a named target
  # would let the opened page reach back into the banner page via window.opener.
  allow_tag_with_this_attribute_values("a", "target", ["_blank"])

  allow_tags_and_scrub_their_attributes([
    "b",
    "blockquote",
    "br",
    "code",
    "del",
    "em",
    "i",
    "li",
    "ol",
    "p",
    "s",
    "strong",
    "u",
    "ul"
  ])
end
