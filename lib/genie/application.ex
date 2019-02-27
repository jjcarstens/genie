defmodule Genie.Application do
  @moduledoc false

  @target Mix.target()

  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: Genie.Supervisor]
    Supervisor.start_link(children(@target), opts)
  end

  # List all child processes to be supervised
  def children(:host), do: []

  def children(_target) do
    [
      {Genie.MotionSensor, []},
      {Genie.StorageRelay, []}
    ]
  end
end
