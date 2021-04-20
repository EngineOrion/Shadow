defmodule Shadow.Intern.Helpers do
  def unix_now() do
    DateTime.to_unix(DateTime.utc_now())
  end
end
