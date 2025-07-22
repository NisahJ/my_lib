defmodule Mylib.Office.AdminProfile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "admin_profiles" do
    field :status, :string
    field :address, :string
    field :full_name, :string
    field :ic, :string
    field :phone, :string
    field :date_of_birth, :date

    belongs_to :admin, Mylib.Office.Admin

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(admin_profile, attrs) do
    admin_profile
    |> cast(attrs, [:admin_id, :full_name, :ic, :status, :phone, :address, :date_of_birth])
    |> validate_required([:full_name, :ic, :status])
    |> validate_length(:ic, min: 12, max: 12)  # Assuming Malaysian IC format
    |> validate_format(:ic, ~r/^\d{12}$/, message: "must be 12 digits")
    |> unique_constraint(:ic, message: "IC number already exists")
    |> assoc_constraint(:admin)
    |> validate_inclusion(:status, ["active", "inactive", "pending"])
  end
end
