defmodule BikeBrigadeWeb.Plugs.GigalixirCanonicalHost do
  defdelegate init(opts), to: PlugCanonicalHost

  def call(conn, opts) do
    # There's a bug in gigagilir where requests to foo.gigaglixirapp.com
    # get `x-forwarded-proto: https` but `x-forwarded-port: 80` which messes up canonical host
    conn =
      if Plug.Conn.get_req_header(conn, "x-forwarded-proto") == ["https"] &&
           Plug.Conn.get_req_header(conn, "x-forwarded-port") == ["80"] do
        conn
        |> Plug.Conn.put_req_header("x-forwarded-port", "443")
      else
        conn
      end

    PlugCanonicalHost.call(conn, opts)
  end
end
