defmodule Genie.SelectionHandler do
  def init(_type, req, _opts) do
    {:ok, req, :nostate}
  end

  def handle(request, state) do
    IO.inspect(request)
    { :ok, reply } = :cowboy_req.reply(
      200, [{"content-type", "text/html"}], "<h1>Hello World!</h1>", request
    )
    {:ok, reply, state}
  end

  def terminate(_reason, _request, _state), do: :ok
end
