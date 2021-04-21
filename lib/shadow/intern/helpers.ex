defmodule Shadow.Intern.Helpers do
  def unix_now() do
    DateTime.to_unix(DateTime.utc_now())
  end

  def ip_addr() do
    with {:ok, data} <- :inet.getif() do
      data |> Enum.at(0) |> elem(0) |> Tuple.to_list |> Enum.join(".")
    else
      _ -> :error
    end
  end

  def port() do
    Application.fetch_env!(:shadow, :port)
  end
  
  def id() do
    time = unix_now() |> Integer.to_string(16)
    :crypto.hash(:md5, time) |> Base.url_encode64(padding: false)
  end
end
