defmodule MylibWeb.AdminProfileLiveTest do
  use MylibWeb.ConnCase

  import Phoenix.LiveViewTest
  import Mylib.OfficeFixtures

  @create_attrs %{status: "some status", address: "some address", full_name: "some full_name", ic: "some ic", phone: "some phone", date_of_birth: "2025-07-20"}
  @update_attrs %{status: "some updated status", address: "some updated address", full_name: "some updated full_name", ic: "some updated ic", phone: "some updated phone", date_of_birth: "2025-07-21"}
  @invalid_attrs %{status: nil, address: nil, full_name: nil, ic: nil, phone: nil, date_of_birth: nil}

  defp create_admin_profile(_) do
    admin_profile = admin_profile_fixture()
    %{admin_profile: admin_profile}
  end

  describe "Index" do
    setup [:create_admin_profile]

    test "lists all admin_profiles", %{conn: conn, admin_profile: admin_profile} do
      {:ok, _index_live, html} = live(conn, ~p"/admin_profiles")

      assert html =~ "Listing Admin profiles"
      assert html =~ admin_profile.status
    end

    test "saves new admin_profile", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/admin_profiles")

      assert index_live |> element("a", "New Admin profile") |> render_click() =~
               "New Admin profile"

      assert_patch(index_live, ~p"/admin_profiles/new")

      assert index_live
             |> form("#admin_profile-form", admin_profile: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#admin_profile-form", admin_profile: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin_profiles")

      html = render(index_live)
      assert html =~ "Admin profile created successfully"
      assert html =~ "some status"
    end

    test "updates admin_profile in listing", %{conn: conn, admin_profile: admin_profile} do
      {:ok, index_live, _html} = live(conn, ~p"/admin_profiles")

      assert index_live |> element("#admin_profiles-#{admin_profile.id} a", "Edit") |> render_click() =~
               "Edit Admin profile"

      assert_patch(index_live, ~p"/admin_profiles/#{admin_profile}/edit")

      assert index_live
             |> form("#admin_profile-form", admin_profile: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#admin_profile-form", admin_profile: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin_profiles")

      html = render(index_live)
      assert html =~ "Admin profile updated successfully"
      assert html =~ "some updated status"
    end

    test "deletes admin_profile in listing", %{conn: conn, admin_profile: admin_profile} do
      {:ok, index_live, _html} = live(conn, ~p"/admin_profiles")

      assert index_live |> element("#admin_profiles-#{admin_profile.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#admin_profiles-#{admin_profile.id}")
    end
  end

  describe "Show" do
    setup [:create_admin_profile]

    test "displays admin_profile", %{conn: conn, admin_profile: admin_profile} do
      {:ok, _show_live, html} = live(conn, ~p"/admin_profiles/#{admin_profile}")

      assert html =~ "Show Admin profile"
      assert html =~ admin_profile.status
    end

    test "updates admin_profile within modal", %{conn: conn, admin_profile: admin_profile} do
      {:ok, show_live, _html} = live(conn, ~p"/admin_profiles/#{admin_profile}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Admin profile"

      assert_patch(show_live, ~p"/admin_profiles/#{admin_profile}/show/edit")

      assert show_live
             |> form("#admin_profile-form", admin_profile: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#admin_profile-form", admin_profile: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin_profiles/#{admin_profile}")

      html = render(show_live)
      assert html =~ "Admin profile updated successfully"
      assert html =~ "some updated status"
    end
  end
end
