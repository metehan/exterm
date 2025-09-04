defmodule Exterm.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Cowboy HTTP server
      {Plug.Cowboy, scheme: :http, plug: Exterm.Router, options: [port: 4000]}
    ]

    opts = [strategy: :one_for_one, name: Exterm.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
