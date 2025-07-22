defmodule Mylib.Admin.AdminProfileTest do
  use Mylib.DataCase

  alias Mylib.Admin.AdminProfile

  describe "changeset/2" do
    test "validates required fields" do
      changeset = AdminProfile.changeset(%AdminProfile{}, %{})

      assert %{
        full_name: ["can't be blank"],
        ic: ["can't be blank"],
        status: ["can't be blank"]
      } = errors_on(changeset)
    end

    test "validates IC format" do
      attrs = %{full_name: "Jane Doe", ic: "invalid", status: "active"}
      changeset = AdminProfile.changeset(%AdminProfile{}, attrs)

      assert %{ic: ["must be 12 digits"]} = errors_on(changeset)
    end

    test "validates status inclusion" do
      attrs = %{full_name: "Jane Doe", ic: "123456789012", status: "invalid"}
      changeset = AdminProfile.changeset(%AdminProfile{}, attrs)

      assert %{status: ["is invalid"]} = errors_on(changeset)
    end
  end
end
