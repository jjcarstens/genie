defmodule Genie.StorageRelay do
  use GenServer

  defguard valid_value(val) when val in [:on, :off, 0, 1]

  defstruct lock: nil, lights: nil, options: nil

  def start_link(options) do
    state = %__MODULE__{options: options}
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(state) do
    send self(), :init
    {:ok, state}
  end

  def toggle_lock(val) when valid_value(val) do
    GenServer.call(__MODULE__, {:toggle_lock, val})
  end
  def toggle_lock(_val), do: :bad_toggle_value

  def toggle_lights(val) when valid_value(val) do
    GenServer.call(__MODULE__, {:toggle_lights, val})
  end
  def toggle_lights(_val), do: :bad_toggle_value

  @impl true
  def handle_call({:toggle_lights, val}, _from, %{lights: lights} = state) do
    Circuits.GPIO.write(lights, transpose_val(val))
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:toggle_lock, val}, _from, %{lock: lock} = state) do
    Circuits.GPIO.write(lock, transpose_val(val))
    {:reply, :ok, state}
  end

  @impl true
  def handle_info(:init, state) do
    {:ok, lock_pin} = Circuits.GPIO.open(12, :output)
    {:ok, lights_pin} = Circuits.GPIO.open(16, :output)
    {:noreply, %{state | lock: lock_pin, lights: lights_pin}}
  end

  defp transpose_val(:off), do: 0
  defp transpose_val(:on), do: 1
  defp transpose_val(val) when val in [1,0], do: val
end
