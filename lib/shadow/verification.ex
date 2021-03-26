defmodule Shadow.Verification do
  @moduledoc """
  Module responsible for verifying the local & remote setups to ensure cluster integrity.
  """

  defstruct local: false

  @doc """
  Uses openssl and the local files to run a verification on the setup.
  """
  def is_local_valid?() do
    command =
      "openssl dgst -md5 -verify resources/public.pem -signature resources/verification.txt resources/base.txt| awk '{print $2}'"
      |> String.to_charlist()

    out = :os.cmd(command) |> to_string() |> String.trim()

    if out == "OK" do
      true
    else
      false
    end
  end
end
