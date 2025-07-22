defmodule Mylib.OfficeTest do
  use Mylib.DataCase

  alias Mylib.Office

  import Mylib.OfficeFixtures
  alias Mylib.Office.{Admin, AdminToken}

  describe "get_admin_by_email/1" do
    test "does not return the admin if the email does not exist" do
      refute Office.get_admin_by_email("unknown@example.com")
    end

    test "returns the admin if the email exists" do
      %{id: id} = admin = admin_fixture()
      assert %Admin{id: ^id} = Office.get_admin_by_email(admin.email)
    end
  end

  describe "get_admin_by_email_and_password/2" do
    test "does not return the admin if the email does not exist" do
      refute Office.get_admin_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the admin if the password is not valid" do
      admin = admin_fixture()
      refute Office.get_admin_by_email_and_password(admin.email, "invalid")
    end

    test "returns the admin if the email and password are valid" do
      %{id: id} = admin = admin_fixture()

      assert %Admin{id: ^id} =
               Office.get_admin_by_email_and_password(admin.email, valid_admin_password())
    end
  end

  describe "get_admin!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Office.get_admin!(-1)
      end
    end

    test "returns the admin with the given id" do
      %{id: id} = admin = admin_fixture()
      assert %Admin{id: ^id} = Office.get_admin!(admin.id)
    end
  end

  describe "register_admin/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Office.register_admin(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Office.register_admin(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Office.register_admin(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = admin_fixture()
      {:error, changeset} = Office.register_admin(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Office.register_admin(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers admins with a hashed password" do
      email = unique_admin_email()
      {:ok, admin} = Office.register_admin(valid_admin_attributes(email: email))
      assert admin.email == email
      assert is_binary(admin.hashed_password)
      assert is_nil(admin.confirmed_at)
      assert is_nil(admin.password)
    end
  end

  describe "change_admin_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Office.change_admin_registration(%Admin{})
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = unique_admin_email()
      password = valid_admin_password()

      changeset =
        Office.change_admin_registration(
          %Admin{},
          valid_admin_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_admin_email/2" do
    test "returns a admin changeset" do
      assert %Ecto.Changeset{} = changeset = Office.change_admin_email(%Admin{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_admin_email/3" do
    setup do
      %{admin: admin_fixture()}
    end

    test "requires email to change", %{admin: admin} do
      {:error, changeset} = Office.apply_admin_email(admin, valid_admin_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{admin: admin} do
      {:error, changeset} =
        Office.apply_admin_email(admin, valid_admin_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{admin: admin} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Office.apply_admin_email(admin, valid_admin_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{admin: admin} do
      %{email: email} = admin_fixture()
      password = valid_admin_password()

      {:error, changeset} = Office.apply_admin_email(admin, password, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{admin: admin} do
      {:error, changeset} =
        Office.apply_admin_email(admin, "invalid", %{email: unique_admin_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{admin: admin} do
      email = unique_admin_email()
      {:ok, admin} = Office.apply_admin_email(admin, valid_admin_password(), %{email: email})
      assert admin.email == email
      assert Office.get_admin!(admin.id).email != email
    end
  end

  describe "deliver_admin_update_email_instructions/3" do
    setup do
      %{admin: admin_fixture()}
    end

    test "sends token through notification", %{admin: admin} do
      token =
        extract_admin_token(fn url ->
          Office.deliver_admin_update_email_instructions(admin, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert admin_token = Repo.get_by(AdminToken, token: :crypto.hash(:sha256, token))
      assert admin_token.admin_id == admin.id
      assert admin_token.sent_to == admin.email
      assert admin_token.context == "change:current@example.com"
    end
  end

  describe "update_admin_email/2" do
    setup do
      admin = admin_fixture()
      email = unique_admin_email()

      token =
        extract_admin_token(fn url ->
          Office.deliver_admin_update_email_instructions(%{admin | email: email}, admin.email, url)
        end)

      %{admin: admin, token: token, email: email}
    end

    test "updates the email with a valid token", %{admin: admin, token: token, email: email} do
      assert Office.update_admin_email(admin, token) == :ok
      changed_admin = Repo.get!(Admin, admin.id)
      assert changed_admin.email != admin.email
      assert changed_admin.email == email
      assert changed_admin.confirmed_at
      assert changed_admin.confirmed_at != admin.confirmed_at
      refute Repo.get_by(AdminToken, admin_id: admin.id)
    end

    test "does not update email with invalid token", %{admin: admin} do
      assert Office.update_admin_email(admin, "oops") == :error
      assert Repo.get!(Admin, admin.id).email == admin.email
      assert Repo.get_by(AdminToken, admin_id: admin.id)
    end

    test "does not update email if admin email changed", %{admin: admin, token: token} do
      assert Office.update_admin_email(%{admin | email: "current@example.com"}, token) == :error
      assert Repo.get!(Admin, admin.id).email == admin.email
      assert Repo.get_by(AdminToken, admin_id: admin.id)
    end

    test "does not update email if token expired", %{admin: admin, token: token} do
      {1, nil} = Repo.update_all(AdminToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Office.update_admin_email(admin, token) == :error
      assert Repo.get!(Admin, admin.id).email == admin.email
      assert Repo.get_by(AdminToken, admin_id: admin.id)
    end
  end

  describe "change_admin_password/2" do
    test "returns a admin changeset" do
      assert %Ecto.Changeset{} = changeset = Office.change_admin_password(%Admin{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Office.change_admin_password(%Admin{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_admin_password/3" do
    setup do
      %{admin: admin_fixture()}
    end

    test "validates password", %{admin: admin} do
      {:error, changeset} =
        Office.update_admin_password(admin, valid_admin_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{admin: admin} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Office.update_admin_password(admin, valid_admin_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{admin: admin} do
      {:error, changeset} =
        Office.update_admin_password(admin, "invalid", %{password: valid_admin_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{admin: admin} do
      {:ok, admin} =
        Office.update_admin_password(admin, valid_admin_password(), %{
          password: "new valid password"
        })

      assert is_nil(admin.password)
      assert Office.get_admin_by_email_and_password(admin.email, "new valid password")
    end

    test "deletes all tokens for the given admin", %{admin: admin} do
      _ = Office.generate_admin_session_token(admin)

      {:ok, _} =
        Office.update_admin_password(admin, valid_admin_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(AdminToken, admin_id: admin.id)
    end
  end

  describe "generate_admin_session_token/1" do
    setup do
      %{admin: admin_fixture()}
    end

    test "generates a token", %{admin: admin} do
      token = Office.generate_admin_session_token(admin)
      assert admin_token = Repo.get_by(AdminToken, token: token)
      assert admin_token.context == "session"

      # Creating the same token for another admin should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%AdminToken{
          token: admin_token.token,
          admin_id: admin_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_admin_by_session_token/1" do
    setup do
      admin = admin_fixture()
      token = Office.generate_admin_session_token(admin)
      %{admin: admin, token: token}
    end

    test "returns admin by token", %{admin: admin, token: token} do
      assert session_admin = Office.get_admin_by_session_token(token)
      assert session_admin.id == admin.id
    end

    test "does not return admin for invalid token" do
      refute Office.get_admin_by_session_token("oops")
    end

    test "does not return admin for expired token", %{token: token} do
      {1, nil} = Repo.update_all(AdminToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Office.get_admin_by_session_token(token)
    end
  end

  describe "delete_admin_session_token/1" do
    test "deletes the token" do
      admin = admin_fixture()
      token = Office.generate_admin_session_token(admin)
      assert Office.delete_admin_session_token(token) == :ok
      refute Office.get_admin_by_session_token(token)
    end
  end

  describe "deliver_admin_confirmation_instructions/2" do
    setup do
      %{admin: admin_fixture()}
    end

    test "sends token through notification", %{admin: admin} do
      token =
        extract_admin_token(fn url ->
          Office.deliver_admin_confirmation_instructions(admin, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert admin_token = Repo.get_by(AdminToken, token: :crypto.hash(:sha256, token))
      assert admin_token.admin_id == admin.id
      assert admin_token.sent_to == admin.email
      assert admin_token.context == "confirm"
    end
  end

  describe "confirm_admin/1" do
    setup do
      admin = admin_fixture()

      token =
        extract_admin_token(fn url ->
          Office.deliver_admin_confirmation_instructions(admin, url)
        end)

      %{admin: admin, token: token}
    end

    test "confirms the email with a valid token", %{admin: admin, token: token} do
      assert {:ok, confirmed_admin} = Office.confirm_admin(token)
      assert confirmed_admin.confirmed_at
      assert confirmed_admin.confirmed_at != admin.confirmed_at
      assert Repo.get!(Admin, admin.id).confirmed_at
      refute Repo.get_by(AdminToken, admin_id: admin.id)
    end

    test "does not confirm with invalid token", %{admin: admin} do
      assert Office.confirm_admin("oops") == :error
      refute Repo.get!(Admin, admin.id).confirmed_at
      assert Repo.get_by(AdminToken, admin_id: admin.id)
    end

    test "does not confirm email if token expired", %{admin: admin, token: token} do
      {1, nil} = Repo.update_all(AdminToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Office.confirm_admin(token) == :error
      refute Repo.get!(Admin, admin.id).confirmed_at
      assert Repo.get_by(AdminToken, admin_id: admin.id)
    end
  end

  describe "deliver_admin_reset_password_instructions/2" do
    setup do
      %{admin: admin_fixture()}
    end

    test "sends token through notification", %{admin: admin} do
      token =
        extract_admin_token(fn url ->
          Office.deliver_admin_reset_password_instructions(admin, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert admin_token = Repo.get_by(AdminToken, token: :crypto.hash(:sha256, token))
      assert admin_token.admin_id == admin.id
      assert admin_token.sent_to == admin.email
      assert admin_token.context == "reset_password"
    end
  end

  describe "get_admin_by_reset_password_token/1" do
    setup do
      admin = admin_fixture()

      token =
        extract_admin_token(fn url ->
          Office.deliver_admin_reset_password_instructions(admin, url)
        end)

      %{admin: admin, token: token}
    end

    test "returns the admin with valid token", %{admin: %{id: id}, token: token} do
      assert %Admin{id: ^id} = Office.get_admin_by_reset_password_token(token)
      assert Repo.get_by(AdminToken, admin_id: id)
    end

    test "does not return the admin with invalid token", %{admin: admin} do
      refute Office.get_admin_by_reset_password_token("oops")
      assert Repo.get_by(AdminToken, admin_id: admin.id)
    end

    test "does not return the admin if token expired", %{admin: admin, token: token} do
      {1, nil} = Repo.update_all(AdminToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Office.get_admin_by_reset_password_token(token)
      assert Repo.get_by(AdminToken, admin_id: admin.id)
    end
  end

  describe "reset_admin_password/2" do
    setup do
      %{admin: admin_fixture()}
    end

    test "validates password", %{admin: admin} do
      {:error, changeset} =
        Office.reset_admin_password(admin, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{admin: admin} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Office.reset_admin_password(admin, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{admin: admin} do
      {:ok, updated_admin} = Office.reset_admin_password(admin, %{password: "new valid password"})
      assert is_nil(updated_admin.password)
      assert Office.get_admin_by_email_and_password(admin.email, "new valid password")
    end

    test "deletes all tokens for the given admin", %{admin: admin} do
      _ = Office.generate_admin_session_token(admin)
      {:ok, _} = Office.reset_admin_password(admin, %{password: "new valid password"})
      refute Repo.get_by(AdminToken, admin_id: admin.id)
    end
  end

  describe "inspect/2 for the Admin module" do
    test "does not include password" do
      refute inspect(%Admin{password: "123456"}) =~ "password: \"123456\""
    end
  end

  describe "admin_profiles" do
    alias Mylib.Office.AdminProfile

    import Mylib.OfficeFixtures

    @invalid_attrs %{status: nil, address: nil, full_name: nil, ic: nil, phone: nil, date_of_birth: nil}

    test "list_admin_profiles/0 returns all admin_profiles" do
      admin_profile = admin_profile_fixture()
      assert Office.list_admin_profiles() == [admin_profile]
    end

    test "get_admin_profile!/1 returns the admin_profile with given id" do
      admin_profile = admin_profile_fixture()
      assert Office.get_admin_profile!(admin_profile.id) == admin_profile
    end

    test "create_admin_profile/1 with valid data creates a admin_profile" do
      valid_attrs = %{status: "some status", address: "some address", full_name: "some full_name", ic: "some ic", phone: "some phone", date_of_birth: ~D[2025-07-20]}

      assert {:ok, %AdminProfile{} = admin_profile} = Office.create_admin_profile(valid_attrs)
      assert admin_profile.status == "some status"
      assert admin_profile.address == "some address"
      assert admin_profile.full_name == "some full_name"
      assert admin_profile.ic == "some ic"
      assert admin_profile.phone == "some phone"
      assert admin_profile.date_of_birth == ~D[2025-07-20]
    end

    test "create_admin_profile/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Office.create_admin_profile(@invalid_attrs)
    end

    test "update_admin_profile/2 with valid data updates the admin_profile" do
      admin_profile = admin_profile_fixture()
      update_attrs = %{status: "some updated status", address: "some updated address", full_name: "some updated full_name", ic: "some updated ic", phone: "some updated phone", date_of_birth: ~D[2025-07-21]}

      assert {:ok, %AdminProfile{} = admin_profile} = Office.update_admin_profile(admin_profile, update_attrs)
      assert admin_profile.status == "some updated status"
      assert admin_profile.address == "some updated address"
      assert admin_profile.full_name == "some updated full_name"
      assert admin_profile.ic == "some updated ic"
      assert admin_profile.phone == "some updated phone"
      assert admin_profile.date_of_birth == ~D[2025-07-21]
    end

    test "update_admin_profile/2 with invalid data returns error changeset" do
      admin_profile = admin_profile_fixture()
      assert {:error, %Ecto.Changeset{}} = Office.update_admin_profile(admin_profile, @invalid_attrs)
      assert admin_profile == Office.get_admin_profile!(admin_profile.id)
    end

    test "delete_admin_profile/1 deletes the admin_profile" do
      admin_profile = admin_profile_fixture()
      assert {:ok, %AdminProfile{}} = Office.delete_admin_profile(admin_profile)
      assert_raise Ecto.NoResultsError, fn -> Office.get_admin_profile!(admin_profile.id) end
    end

    test "change_admin_profile/1 returns a admin_profile changeset" do
      admin_profile = admin_profile_fixture()
      assert %Ecto.Changeset{} = Office.change_admin_profile(admin_profile)
    end
  end

  describe "admin_profiles" do
    alias MyLib.Office.AdminProfile
    alias MyLib.Office

    @valid_attrs %{
      full_name: "Azatul",
      ic: "010203040506",
      status: "active",
      phone: "0123456789",
      address: "Kota Kinabalu",
      date_of_birth: ~D[1995-01-01]
    }

    @invalid_attrs %{
      full_name: nil,
      ic: nil
    }

    setup do
      {:ok, admin} = Office.create_admin(%{email: "admin@example.com", password: "secret123"})
      %{admin: admin}
    end

    test "creates admin profile with valid data", %{admin: admin} do
      assert {:ok, %AdminProfile{} = profile} = Office.create_admin_profile(admin, @valid_attrs)
      assert profile.full_name == "Azatul"
    end

    test "fails to create admin profile with invalid data", %{admin: admin} do
      assert {:error, changeset} = Office.create_admin_profile(admin, @invalid_attrs)
      refute changeset.valid?
      assert %{full_name: ["can't be blank"], ic: ["can't be blank"]} = errors_on(changeset)
    end
  end

end
