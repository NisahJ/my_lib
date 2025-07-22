defmodule MylibWeb.OfficeAuthTest do
  use MylibWeb.ConnCase, async: true

  alias Mylib.Office

  setup %{conn: conn} do
    {:ok, admin} = Office.create_admin(%{email: "admin@example.com", password: "secret123"})
    %{conn: conn, admin: admin}
  end

  test "logs in admin and redirects", %{conn: conn, admin: admin} do
    conn =
      post(conn, ~p"/admin/log_in", %{
        "admin" => %{
          "email" => admin.email,
          "password" => "secret123"
        }
      })

    assert redirected_to(conn) =~ "/admin/settings"
    assert get_session(conn, :admin_token)
  end

  test "does not log in with invalid password", %{conn: conn, admin: admin} do
    conn =
      post(conn, ~p"/admin/log_in", %{
        "admin" => %{
          "email" => admin.email,
          "password" => "wrongpass"
        }
      })

    assert html_response(conn, 200) =~ "Invalid email or password"
  end
end
