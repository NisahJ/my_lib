defmodule Mylib.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MylibWeb.Telemetry,
      Mylib.Repo,
      {DNSCluster, query: Application.get_env(:mylib, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Mylib.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Mylib.Finch},
      # Start a worker by calling: Mylib.Worker.start_link(arg)
      # {Mylib.Worker, arg},
      # Start to serve requests, typically the last entry
      MylibWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Mylib.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MylibWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
