defmodule ExLogger do

  require :gen_event

  def init(__MODULE__) do
    {:ok, configure([])}
  end

  defp configure(opts) do
    state = %{level: nil, producer_node: nil, sink_node: nil}
    configure(opts, state)
  end

  defp configure(opts, state) do

    env = Application.get_env(:logger, __MODULE__, [])
    opts = Keyword.merge(env, opts)
    Application.put_env(:logger, __MODULE__, opts)
    level = Keyword.get(opts, :level)
    producer_node = Node.self()
    sink_node = Keyword.get(opts, :sink_node)

    %{state | level: level, producer_node: producer_node, sink_node: sink_node}
  end

  def event_call({:configure, opts}, state) do
    {:ok, {:ok, configure(opts, state), configure(opts, state)}}
  end

  def handle_event({_level, gl, {Logger, _, _, _}}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({level, _gl, {Logger, msg, timestamps, metadata}}, %{level: log_level} = state) do
    if meet_level?(level, log_level) do

      log_to_sink(level, msg, timestamps, state, metadata)

    end
    {:ok, state}
  end

  def handle_event(:flush, state) do
    {:ok, state}
  end

  defp meet_level?(_lvl, nil), do: true

  defp meet_level?(lvl, min) do
    Logger.compare_levels(lvl, min) != :lt
  end

  defp log_to_sink(level, message, _timestamp, %{producer_node: producer_node, sink_node: sink_node} = _state, metadata) do

    message = flatten_message(message) |> Enum.join("\n")
    timestamp = DateTime.utc_now()
    formatted_string = DateTime.to_string(timestamp)

    log_format = "#{producer_node} #{formatted_string} [#{level}] #{message} #{inspect(metadata)}"
    log_via_rpc(sink_node, LogGenServer,:log , [log_format])

  end

  defp log_via_rpc(node, module, function, args) do
    :erpc.cast(node, module, function, args)
  end

  defp flatten_message(msg) do
    case msg do
      [n | body] -> ["#{n}: #{body}"]
      _ -> [msg]
    end
  end
end
