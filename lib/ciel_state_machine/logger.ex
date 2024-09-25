defmodule CielStateMachine.Logger do
  require Logger

  def info(message, metadata \\ []) do
    log(:info, message, metadata)
  end

  def warn(message, metadata \\ []) do
    log(:warning, message, metadata)
  end

  def error(message, metadata \\ []) do
    log(:error, message, metadata)
  end

  def debug(message, metadata \\ []) do
    log(:debug, message, metadata)
  end

  defp log(level, message, metadata) do
    Logger.log(level, message, format_metadata(metadata))
  end

  defp format_metadata(metadata) when is_list(metadata), do: metadata
  defp format_metadata(metadata) when is_map(metadata) do
    Enum.into(metadata, [])
  end
  defp format_metadata(_), do: []
end
