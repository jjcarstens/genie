defmodule ApiWeb.SelectionController do
  use ApiWeb, :controller

  @frame_locations %{
    "Kaden" => 1,
    "Gavin" => 2,
    "Charlotte" => 3,
    "Garrett" => 4,
    "Jon" => 5,
    "Stephanie" => 7
  }


  @kids ["Kaden", "Gavin", "Charlotte", "Garrett"]
  @all ["Jon", "Stephanie"] ++ @kids

  @allowed_types ["truck", "dishwasher", "meal", "misc", "family"]

  # This is for the ESP8266 to request which LED to light up and indicate
  # whose turn it is for the turn type. So we only need to return
  # the pin number to light up
  # TODO: Move this to live phoenix app and allow pin configuring
  def turn_picker(conn, %{"type" => type}) when type in @allowed_types do
    selection = make_selection_for_type(type)
    json(conn, %{frame_num: selection, color: [Enum.random(0..255),Enum.random(0..255),Enum.random(0..255)]})
  end

  def turn_picker(conn, params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "type must be one of #{inspect(@allowed_types)}"})
  end

  defp make_selection_for_type("truck"), do: @frame_locations[Enum.random(@kids)]
  defp make_selection_for_type("dishwasher"), do: @frame_locations[Enum.random(@kids)]
  defp make_selection_for_type("meal"), do: @frame_locations[Enum.random(@all)]
  defp make_selection_for_type("misc"), do: @frame_locations[Enum.random(@all)]
  defp make_selection_for_type("family"), do: @frame_locations[Enum.random(@all)]
end
