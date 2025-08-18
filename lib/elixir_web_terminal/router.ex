defmodule ElixirWebTerminal.Router do
  use Plug.Router

  plug Plug.Logger
  plug :match
  plug :dispatch

  # Serve static files
  get "/" do
    send_file(conn, 200, "priv/static/index.html")
  end

  get "/terminal.css" do
    conn
    |> put_resp_content_type("text/css")
    |> send_file(200, "priv/static/terminal.css")
  end

  get "/terminal.js" do
    conn
    |> put_resp_content_type("application/javascript")
    |> send_file(200, "priv/static/terminal.js")
  end

  # WebSocket upgrade endpoint
  get "/ws" do
    conn
    |> Plug.Conn.upgrade_adapter(:websocket, {ElixirWebTerminal.TerminalSocket, [], %{}})
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
