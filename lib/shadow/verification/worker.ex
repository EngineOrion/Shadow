defmodule Shadow.Verification.Worker do
  @moduledoc """
  Active process responsible for continuously checking the local and remote status.
  """

  use GenServer
  alias Shadow.Verification

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: name())
  end

  def verify_local() do
    GenServer.cast(name(), :verify)
  end

  def repeating_exec() do
    GenServer.cast(name(), :repeating)
  end

  # - - - - - - - - - - - - - - - - - - -

  def init(_state) do
    state = %Verification{
      local: Verification.is_local_valid?()
    }

    {:ok, state}
  end

  def handle_cast(:verify, _state) do
    {:noreply, %Verification{local: Verification.is_local_valid?()}}
  end

  def handle_cast(:repeating, _state) do
    repeating()
    {:noreply, %Verification{local: Verification.is_local_valid?()}}
  end

  def handle_info(:check, _state) do
    state = Verification.is_local_valid?()

    if state do
      {:noreply, %Verification{local: Verification.is_local_valid?()}}
    end

    Application.stop(:shadow)
    {:noreply, :error}
  end

  defp repeating() do
    Process.send_after(GenServer.whereis(name()), :check, 60_000)
  end

  defp name() do
    :verification
  end
end
