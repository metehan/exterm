defmodule ElixirWebTerminal.TerminalSocket do
  @behaviour :cowboy_websocket

  def init(request, _state) do
    {:cowboy_websocket, request, %{}}
  end

  def websocket_init(_state) do
    # Find bash path - try common locations
    bash_path = case System.find_executable("bash") do
      nil -> "/bin/sh"  # fallback to sh if bash not found
      path -> path
    end

    # Spawn a shell with interactive options
    port = Port.open({:spawn, "#{bash_path} -i"}, [
      :binary,
      :exit_status,
      :stderr_to_stdout
    ])

    # Store the port in the state
    {:ok, %{port: port}}
  end

  def websocket_handle({:text, msg}, state) do
    # Convert \r to \n for proper shell handling
    normalized_msg = String.replace(msg, "\r", "\n")
    
    # Forward incoming WebSocket message to the shell
    case Map.get(state, :port) do
      nil ->
        {:reply, {:text, "Error: Shell not available\r\n"}, state}
      port ->
        Port.command(port, normalized_msg)
        {:ok, state}
    end
  end

  def websocket_handle({:binary, msg}, state) do
    # Handle binary messages the same way as text
    case Map.get(state, :port) do
      nil ->
        {:reply, {:text, "Error: Shell not available\r\n"}, state}
      port ->
        Port.command(port, msg)
        {:ok, state}
    end
  end

  def websocket_handle(_data, state) do
    {:ok, state}
  end

  def websocket_info({port, {:data, data}}, %{port: port} = state) do
    # Forward shell output back to WebSocket client
    {:reply, {:text, data}, state}
  end

  def websocket_info({port, {:exit_status, _status}}, %{port: port} = state) do
    # Shell exited, close the WebSocket
    {:reply, {:close, 1000, "Shell exited"}, state}
  end

  def websocket_info(_info, state) do
    {:ok, state}
  end

  def terminate(_reason, _request, state) do
    # Clean up: close the port if it exists
    case state do
      %{port: port} when is_port(port) -> Port.close(port)
      _ -> :ok
    end
    :ok
  end
end
