defmodule MylibWeb.AdminProfileLive.Index do
  use MylibWeb, :live_view

  alias Mylib.Office
  alias Mylib.Office.AdminProfile

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :admin_profiles, Office.list_admin_profiles())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Admin profile")
    |> assign(:admin_profile, %AdminProfile{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Admin profiles")
    |> assign(:admin_profile, nil)
  end

  @impl true
  def handle_info({MylibWeb.AdminProfileLive.FormComponent, {:saved, admin_profile}}, socket) do
    {:noreply, stream_insert(socket, :admin_profiles, admin_profile)}
  end
end
