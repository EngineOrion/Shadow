defmodule Shadow.Routing.Self do
  @moduledoc """
  Datastructure and functions about the local node.
  """

  defstruct key: 0,
            public: "",
            verification: ""

  @doc """
  Returns a new, fully populated struct with all required fields.
  """
  def get() do
    with {:ok, key} <- get_key(),
         {:ok, public} <- get_public(),
         {:ok, verification} <- get_verification() do
      {:ok,
       %__MODULE__{
         key: key,
         public: public,
         verification: verification
       }}
    else
      _ -> {:error, :self_error}
    end
  end

  defp get_key() do
    # TODO: Use config for file paths.
    with {:ok, body} <- File.read(".shadow/key.shadow") do
      key =
        body
        |> String.trim()
        |> :binary.decode_unsigned()

      {:ok, key}
    else
      _ -> {:error, :file_error}
    end
  end

  defp get_public() do
    File.read(".shadow/public.shadow")
  end

  defp get_verification() do
    File.read(".shadow/verification.shadow")
  end
end
