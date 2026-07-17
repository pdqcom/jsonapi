defmodule JSONAPI.ContentTypeNegotiation do
  @moduledoc """
  Provides content type negotiation by validating the `content-type` header.

  The proper jsonapi.org content type is
  `application/vnd.api+json`. As per [the spec](http://jsonapi.org/format/#content-negotiation-servers)

  This plug does three things:

  1. Returns 415 unless the content-type header is correct.
  2. Registers a before send hook to set the content-type if not already set.
  """

  import JSONAPI.ErrorView

  import Plug.Conn

  def init(opts), do: opts

  def call(%{method: method} = conn, _opts) when method in ["DELETE", "GET", "HEAD"], do: conn

  def call(conn, _opts) do
    conn
    |> content_type
    |> respond
  end

  defp content_type(conn) do
    content_type =
      conn
      |> get_req_header("content-type")
      |> List.first()

    {conn, content_type}
  end

  defp respond({conn, content_type}) do
    if validate_header(content_type) do
      add_header_to_resp(conn)
    else
      send_error(conn, incorrect_content_type())
    end
  end

  defp validate_header(string) when is_binary(string) do
    string
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.member?(JSONAPI.mime_type())
  end

  defp validate_header(nil), do: true

  defp add_header_to_resp(conn) do
    register_before_send(conn, fn conn ->
      update_resp_header(
        conn,
        "content-type",
        JSONAPI.mime_type(),
        & &1
      )
    end)

    conn
  end
end
