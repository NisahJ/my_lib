defmodule MylibWeb.AdminProfileLive.FormComponent do

  use MylibWeb, :live_component

  alias Mylib.Office

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage admin_profile records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="admin_profile-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:full_name]} type="text" label="Full name" />
        <.input field={@form[:ic]} type="text" label="Ic" placeholder="123456789012" required/>
        <.input field={@form[:status]} type="select" label="Status" options={[{"Active", "active"}, {"Inactive", "inactive"}, {"Pending", "pending"}]} required/>
        <.input field={@form[:phone]} type="text" label="Phone" placeholder="+60123456789"/>
        <.input field={@form[:address]} type="textarea" label="Address" rows="3"/>
        <.input field={@form[:date_of_birth]} type="date" label="Date of birth" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Admin profile</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{admin_profile: admin_profile} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Office.change_admin_profile(admin_profile))
     end)}
  end

  @impl true
  def handle_event("validate", %{"admin_profile" => admin_profile_params}, socket) do
    changeset = Office.change_admin_profile(socket.assigns.admin_profile, admin_profile_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"admin_profile" => admin_profile_params}, socket) do
    save_admin_profile(socket, socket.assigns.action, admin_profile_params)
  end

  defp save_admin_profile(socket, :edit, admin_profile_params) do
    case Office.update_admin_profile(socket.assigns.admin_profile, admin_profile_params) do
      {:ok, admin_profile} ->
        notify_parent({:saved, admin_profile})

        {:noreply,
         socket
         |> put_flash(:info, "Admin profile updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
