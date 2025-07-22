defmodule Mylib.Repo do
  use Ecto.Repo,
    otp_app: :mylib,
    adapter: Ecto.Adapters.Postgres
end
