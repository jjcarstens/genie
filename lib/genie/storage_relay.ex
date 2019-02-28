defmodule Genie.StorageRelay do
  use GenServer

  @high_values ["on", "locked", :on, :locked, 1]
  @low_values ["off", "unlocked", :off, :unlocked, 0]
  @valid_values @high_values ++ @low_values

  defguard valid_value(val) when val in @valid_values

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

  def read_lock, do: GenServer.call(__MODULE__, :read_lock)

  def read_lights, do: GenServer.call(__MODULE__, :read_lights)

  def toggle_lock(val) when valid_value(val) do
    GenServer.call(__MODULE__, {:toggle_lock, val})
  end
  def toggle_lock(_val), do: :bad_toggle_value

  def toggle_lights(val) when valid_value(val) do
    GenServer.call(__MODULE__, {:toggle_lights, val})
  end
  def toggle_lights(_val), do: :bad_toggle_value

  @impl true
  def handle_call(:read_lights, _from, %{lights: lights} = state) do
    val = Circuits.GPIO.read(lights) |> val_to_atom(:lights)
    {:reply, val, state}
  end

  @impl true
  def handle_call(:read_lock, _from, %{lock: lock} = state) do
    val = Circuits.GPIO.read(lock) |> val_to_atom(:lock)
    {:reply, val, state}
  end

  @impl true
  def handle_call({:toggle_lights, val}, _from, %{lights: lights} = state) do
    Circuits.GPIO.write(lights, gpio_val(val))
    Circuits.GPIO.read(lights) |> send_update(:lights)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:toggle_lock, val}, _from, %{lock: lock} = state) do
    Circuits.GPIO.write(lock, gpio_val(val))
    Circuits.GPIO.read(lock) |> send_update(:lock)
    {:reply, :ok, state}
  end

  @impl true
  def handle_info(:init, state) do
    {:ok, lock_pin} = Circuits.GPIO.open(12, :output)
    {:ok, lights_pin} = Circuits.GPIO.open(16, :output)
    {:noreply, %{state | lock: lock_pin, lights: lights_pin}}
  end

  defp gpio_val(val) when val in @low_values, do: 0
  defp gpio_val(val) when val in @high_values, do: 1

  defp val_to_atom(1, :lights), do: :on
  defp val_to_atom(0, :lights), do: :off
  defp val_to_atom(1, :lock), do: :locked
  defp val_to_atom(0, :lock), do: :unlocked

  defp send_update(val, update) when is_number(val) do
    val_to_atom(val, update) |> send_update(update)
  end
  defp send_update(val, update) do
    send Genie.Websocket, {update, val}
  end
end
