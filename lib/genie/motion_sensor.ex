defmodule Genie.MotionSensor do
  use GenServer
  require Logger

  defguard is_powering_up(current, past) when is_nil(past) or ((current - past)/1.0e9) < 5

  defstruct pin: nil, last_timestamp: nil, options: nil

  def start_link(options) do
    state = %__MODULE__{options: options}
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(state) do
    send self(), :init
    {:ok, state}
  end

  @impl true
  def handle_info(:init, state) do
    # Maybe set pin from config or allow passing option?
    {:ok, motion_pin} = Circuits.GPIO.open(6, :input)
    Circuits.GPIO.set_interrupts(motion_pin, :both)
    {:noreply, %{state | pin: motion_pin}}
  end

  # @impl true
  # def handle_info({:circuits_gpio, _pin, current, _val}, %{last_timestamp: past} = state) when is_powering_up(current, past) do
  #   # According to the data sheet, this PIR sensor can take up to a minute to power up
  #   # During that time, the timer can send messages frequently between HIGH and LOW
  #   # So, lets capture them here and not do anything if the messages look to be during the startup
  #   # See:
  #   #   https://www.mysensors.org/dl/57c41fdd4d04abe84cd93e12/design/31227sc.pdf
  #   Logger.info("starting up!")
  #   {:noreply, %{state | last_timestamp: current}}
  # end

  @impl true
  def handle_info({:circuits_gpio, _pin, time, 0}, state) do
    # no motion
    Genie.StorageRelay.toggle_lights(:off)
    {:noreply, %{state | last_timestamp: time}}
  end

  @impl true
  def handle_info({:circuits_gpio, _pin, time, 1}, state) do
    # There is motion!
    Genie.StorageRelay.toggle_lights(:on)
    {:noreply, %{state | last_timestamp: time}}
  end
end
