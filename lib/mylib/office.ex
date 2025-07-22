defmodule Mylib.Office do
  @moduledoc """
  The Office context.
  """

  import Ecto.Query, warn: false
<<<<<<< HEAD
<<<<<<< HEAD

  alias Mylib.Office.{Admin, AdminToken, AdminNotifier}
  alias Mylib.Repo
  alias Mylib.Office.AdminProfile
=======
<<<<<<< HEAD
  alias Mylib.Repo

  alias Mylib.Office.{Admin, AdminToken, AdminNotifier}
=======
=======
>>>>>>> 1b032a1 (update)

  alias Mylib.Office.{Admin, AdminToken, AdminNotifier}
  alias Mylib.Repo
  alias Mylib.Office.AdminProfile
<<<<<<< HEAD
>>>>>>> af1d9cc (new update)
>>>>>>> 376403e (new update)
=======
>>>>>>> 1b032a1 (update)
  ## Database getters

  @doc """
  Gets a admin by email.

  ## Examples

      iex> get_admin_by_email("foo@example.com")
      %Admin{}

      iex> get_admin_by_email("unknown@example.com")
      nil

  """
  def get_admin_by_email(email) when is_binary(email) do
    Repo.get_by(Admin, email: email)
  end

  @doc """
  Gets a admin by email and password.

  ## Examples

      iex> get_admin_by_email_and_password("foo@example.com", "correct_password")
      %Admin{}

      iex> get_admin_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_admin_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    admin = Repo.get_by(Admin, email: email)
    if admin && Admin.valid_password?(admin, password), do: admin
  end

  @doc """
  Gets a single admin.

  Raises `Ecto.NoResultsError` if the Admin does not exist.

  ## Examples

      iex> get_admin!(123)
      %Admin{}

      iex> get_admin!(456)
      ** (Ecto.NoResultsError)

  """
  def get_admin!(id), do: Repo.get!(Admin, id)
<<<<<<< HEAD

<<<<<<< HEAD
  def get_admin_profile!(id), do: Repo.get!(AdminProfile, id)

=======
<<<<<<< HEAD
=======
  def get_admin_profile!(id), do: Repo.get!(AdminProfile, id)

>>>>>>> af1d9cc (new update)
>>>>>>> 376403e (new update)
=======
  def get_admin_profile!(id), do: Repo.get!(AdminProfile, id)
>>>>>>> 1b032a1 (update)
  ## Admin registration

  @doc """
  Registers a admin.

  ## Examples

      iex> register_admin(%{field: value})
      {:ok, %Admin{}}

      iex> register_admin(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_admin(attrs) do
    %Admin{}
    |> Admin.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking admin changes.

  ## Examples

      iex> change_admin_registration(admin)
      %Ecto.Changeset{data: %Admin{}}

  """
  def change_admin_registration(%Admin{} = admin, attrs \\ %{}) do
    Admin.registration_changeset(admin, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the admin email.

  ## Examples

      iex> change_admin_email(admin)
      %Ecto.Changeset{data: %Admin{}}

  """
  def change_admin_email(admin, attrs \\ %{}) do
    Admin.email_changeset(admin, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_admin_email(admin, "valid password", %{email: ...})
      {:ok, %Admin{}}

      iex> apply_admin_email(admin, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_admin_email(admin, password, attrs) do
    admin
    |> Admin.email_changeset(attrs)
    |> Admin.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the admin email using the given token.

  If the token matches, the admin email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_admin_email(admin, token) do
    context = "change:#{admin.email}"

    with {:ok, query} <- AdminToken.verify_change_email_token_query(token, context),
         %AdminToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(admin_email_multi(admin, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp admin_email_multi(admin, email, context) do
    changeset =
      admin
      |> Admin.email_changeset(%{email: email})
      |> Admin.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:admin, changeset)
    |> Ecto.Multi.delete_all(:tokens, AdminToken.by_admin_and_contexts_query(admin, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given admin.

  ## Examples

      iex> deliver_admin_update_email_instructions(admin, current_email, &url(~p"/admins/settings/confirm_email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_admin_update_email_instructions(%Admin{} = admin, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, admin_token} = AdminToken.build_email_token(admin, "change:#{current_email}")

    Repo.insert!(admin_token)
    AdminNotifier.deliver_update_email_instructions(admin, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the admin password.

  ## Examples

      iex> change_admin_password(admin)
      %Ecto.Changeset{data: %Admin{}}

  """
  def change_admin_password(admin, attrs \\ %{}) do
    Admin.password_changeset(admin, attrs, hash_password: false)
  end

  @doc """
  Updates the admin password.

  ## Examples

      iex> update_admin_password(admin, "valid password", %{password: ...})
      {:ok, %Admin{}}

      iex> update_admin_password(admin, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_admin_password(admin, password, attrs) do
    changeset =
      admin
      |> Admin.password_changeset(attrs)
      |> Admin.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:admin, changeset)
    |> Ecto.Multi.delete_all(:tokens, AdminToken.by_admin_and_contexts_query(admin, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{admin: admin}} -> {:ok, admin}
      {:error, :admin, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_admin_session_token(admin) do
    {token, admin_token} = AdminToken.build_session_token(admin)
    Repo.insert!(admin_token)
    token
  end

  @doc """
  Gets the admin with the given signed token.
  """
  def get_admin_by_session_token(token) do
    {:ok, query} = AdminToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_admin_session_token(token) do
    Repo.delete_all(AdminToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given admin.

  ## Examples

      iex> deliver_admin_confirmation_instructions(admin, &url(~p"/admins/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_admin_confirmation_instructions(confirmed_admin, &url(~p"/admins/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_admin_confirmation_instructions(%Admin{} = admin, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if admin.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, admin_token} = AdminToken.build_email_token(admin, "confirm")
      Repo.insert!(admin_token)
      AdminNotifier.deliver_confirmation_instructions(admin, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a admin by the given token.

  If the token matches, the admin account is marked as confirmed
  and the token is deleted.
  """
  def confirm_admin(token) do
    with {:ok, query} <- AdminToken.verify_email_token_query(token, "confirm"),
         %Admin{} = admin <- Repo.one(query),
         {:ok, %{admin: admin}} <- Repo.transaction(confirm_admin_multi(admin)) do
      {:ok, admin}
    else
      _ -> :error
    end
  end

  defp confirm_admin_multi(admin) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:admin, Admin.confirm_changeset(admin))
    |> Ecto.Multi.delete_all(:tokens, AdminToken.by_admin_and_contexts_query(admin, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given admin.

  ## Examples

      iex> deliver_admin_reset_password_instructions(admin, &url(~p"/admins/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_admin_reset_password_instructions(%Admin{} = admin, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, admin_token} = AdminToken.build_email_token(admin, "reset_password")
    Repo.insert!(admin_token)
    AdminNotifier.deliver_reset_password_instructions(admin, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the admin by reset password token.

  ## Examples

      iex> get_admin_by_reset_password_token("validtoken")
      %Admin{}

      iex> get_admin_by_reset_password_token("invalidtoken")
      nil

  """
  def get_admin_by_reset_password_token(token) do
    with {:ok, query} <- AdminToken.verify_email_token_query(token, "reset_password"),
         %Admin{} = admin <- Repo.one(query) do
      admin
    else
      _ -> nil
    end
  end

  @doc """
  Resets the admin password.

  ## Examples

      iex> reset_admin_password(admin, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %Admin{}}

      iex> reset_admin_password(admin, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_admin_password(admin, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:admin, Admin.password_changeset(admin, attrs))
    |> Ecto.Multi.delete_all(:tokens, AdminToken.by_admin_and_contexts_query(admin, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{admin: admin}} -> {:ok, admin}
      {:error, :admin, changeset, _} -> {:error, changeset}
    end
  end

  alias Mylib.Office.AdminProfile

  @doc """
  Returns the list of admin_profiles.

  ## Examples

      iex> list_admin_profiles()
      [%AdminProfile{}, ...]

  """
  alias Mylib.Office.Admin


  # Get profile by admin
  def get_admin_profile(admin) do
    Repo.get_by(AdminProfile, admin_id: admin.id)
  end

  # Preload profile into admin
  def get_admin_with_profile(id) do
    Admin
    |> Repo.get!(id)
    |> Repo.preload(:admin_profile)
  end

  # Create profile for admin
  def create_admin_profile(admin, attrs) do
    %AdminProfile{}
    |> AdminProfile.changeset(Map.put(attrs, "admin_id", admin.id))
    |> Repo.insert()
  end

  # Update profile
  def update_admin_profile(profile, attrs) do
    profile
    |> AdminProfile.changeset(attrs)
    |> Repo.update()
  end

  # Change profile (form usage)
  def change_admin_profile(profile \\ %AdminProfile{}, attrs \\ %{}) do
    AdminProfile.changeset(profile, attrs)
  end

  def list_admin_profiles do
    Repo.all(AdminProfile)
  end

  def delete_admin_profile(%AdminProfile{} = profile) do
    Repo.delete(profile)
  end

  def upsert_admin_profile(admin, params) do
    case get_admin_profile(admin) do
      nil ->
        create_admin_profile(admin, params)

      profile ->
        update_admin_profile(profile, params)
    end
  end


end
