defmodule MylibWeb.AdminProfileLive.Show do
  use MylibWeb, :live_view

  alias Mylib.Office

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:admin_profile, Office.get_admin_profile!(id))}
  end

  defp page_title(:show), do: "Show Admin profile"
  defp page_title(:edit), do: "Edit Admin profile"
end
