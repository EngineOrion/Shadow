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
  
end
