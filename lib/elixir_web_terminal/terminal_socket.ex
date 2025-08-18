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

    # Use script command to create a proper PTY session
    # script -qefc creates a PTY and runs the command
    script_cmd = case System.find_executable("script") do
      nil -> 
        # Fallback: use bash directly with some PTY-like options
        "#{bash_path} -i"
      script_path ->
        # Use script to create a proper PTY
        "#{script_path} -qefc '#{bash_path} -i' /dev/null"
    end

    # Spawn the shell with PTY support
    port = Port.open({:spawn, script_cmd}, [
      :binary,
      :exit_status,
      :stderr_to_stdout
    ])

    # Set up a heartbeat timer to keep connection alive (every 30 seconds)
    :timer.send_interval(30_000, self(), :heartbeat)

    # Store the port in the state
    {:ok, %{port: port}}
  end

  def websocket_handle({:text, msg}, state) do
    # Debug: log control characters
    if String.contains?(msg, <<3>>) do
      IO.puts("Received Ctrl+C (ETX) signal")
    end
    
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

  def websocket_handle({:pong, _data}, state) do
    # Handle pong response from client (optional logging)
    {:ok, state}
  end

  def websocket_handle(_data, state) do
    {:ok, state}
  end

  def websocket_info({port, {:data, data}}, %{port: port} = state) do
    # Convert \n to \r\n for proper terminal display
    normalized_data = String.replace(data, "\n", "\r\n")
    # Forward shell output back to WebSocket client
    {:reply, {:text, normalized_data}, state}
  end

  def websocket_info({port, {:exit_status, _status}}, %{port: port} = state) do
    # Shell exited, close the WebSocket
    {:reply, {:close, 1000, "Shell exited"}, state}
  end

  def websocket_info(:heartbeat, state) do
    # Send a ping frame to keep the connection alive
    {:reply, {:ping, ""}, state}
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
