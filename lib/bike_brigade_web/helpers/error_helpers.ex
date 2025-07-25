defmodule BikeBrigadeWeb.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  import Phoenix.HTML.Form
  use PhoenixHTMLHelpers

  @doc """
  Generates tag for inlined form input errors.
  """
  def error_tag(form, field, opts \\ []) do
    show_field = Keyword.get(opts, :show_field, true)

    Enum.map(Keyword.get_values(form.errors, field), fn error ->
      error_string =
        if show_field do
          "'#{Atom.to_string(field) |> Recase.to_sentence()}': #{translate_error(error)}"
        else
          translate_error(error)
        end

      content_tag(
        :p,
        error_string,
        class: "mt-2 text-sm text-red-600",
        phx_feedback_for: input_id(form, field)
      )
    end)
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate "is invalid" in the "errors" domain
    #     dgettext("errors", "is invalid")
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    # This requires us to call the Gettext module passing our gettext
    # backend as first argument.
    #
    # Note we use the "errors" domain, which means translations
    # should be written to the errors.po file. The :count option is
    # set by Ecto and indicates we should also apply plural rules.
    if count = opts[:count] do
      Gettext.dngettext(BikeBrigadeWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(BikeBrigadeWeb.Gettext, "errors", msg, opts)
    end
  end
end
