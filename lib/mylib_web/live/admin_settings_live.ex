defmodule MylibWeb.AdminSettingsLive do
  use MylibWeb, :live_view

  alias Mylib.Office
  alias Mylib.Office.AdminProfile
  alias Mylib.Office.Admin

  def mount(_params, _session, socket) do
    current_admin = Office.get_admin_with_profile(socket.assigns.current_admin.id)


    current_profile = current_admin.admin_profile || %AdminProfile{}

    profile_form =
      current_profile
      |> AdminProfile.changeset(%{})
      |> to_form(as: "admin_profile")

    email_form =
      Admin.email_changeset(current_admin, %{})
      |> to_form(as: "email")

    password_form =
      Admin.password_changeset(current_admin, %{})
      |> to_form(as: "password")

    socket =
      socket
      |> assign(:current_admin, current_admin) # make sure this holds the preloaded version
      |> assign(:current_profile, current_profile)
      |> assign(:profile_form, profile_form)
      |> assign(:email_form, email_form)
      |> assign(:password_form, password_form)

    {:ok, socket}
  end

  def handle_event("update_profile", %{"admin_profile" => params}, socket) do
    admin = socket.assigns.current_admin
    profile = socket.assigns.current_profile

    result =
      if profile.id do
        Mylib.Office.update_admin_profile(profile, Map.put(params, "admin_id", admin.id))
      else
        Mylib.Office.create_admin_profile(admin, params)
      end

    case result do
      {:ok, profile} ->
        form = Mylib.Office.change_admin_profile(profile) |> to_form(as: "admin_profile")
        {:noreply, socket |> put_flash(:info, "Profile saved.") |> assign(:current_profile, profile) |> assign(:profile_form, form)}

      {:error, changeset} ->
        {:noreply, assign(socket, :profile_form, to_form(changeset, as: "admin_profile"))}
    end
  end


  def handle_event("validate_profile", %{"admin_profile" => params}, socket) do
    changeset =
      socket.assigns.current_profile
      |> Mylib.Office.change_admin_profile(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :profile_form, to_form(changeset, as: "admin_profile"))}
  end


  def handle_event("validate_email", %{"email" => params}, socket) do
    changeset =
      socket.assigns.current_admin
      |> Admin.email_changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :email_form, to_form(changeset, as: "email"))}
  end

  def handle_event("update_email", %{"email" => params}, socket) do
    current_admin = socket.assigns.current_admin

    case Office.update_admin_email(current_admin, params) do
      {:ok, admin} ->
        changeset = Admin.email_changeset(admin, %{})
        form = to_form(changeset, as: "email")

        socket =
          socket
          |> put_flash(:info, "Email updated successfully")
          |> assign(:email_form, form)

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(changeset, as: "email"))}
    end
  end

  def handle_event("validate_password", %{"password" => params}, socket) do
    changeset =
      socket.assigns.current_admin
      |> Admin.password_changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :password_form, to_form(changeset, as: "password"))}
  end

  def handle_event("update_password", %{"password" => params}, socket) do
    current_admin = socket.assigns.current_admin

    case Office.update_admin_password(current_admin, params) do
      {:ok, admin} ->
        changeset = Admin.password_changeset(admin, %{})
        form = to_form(changeset, as: "password")

        socket =
          socket
          |> put_flash(:info, "Password updated successfully")
          |> assign(:password_form, form)

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :password_form, to_form(changeset, as: "password"))}
    end
  end

end
