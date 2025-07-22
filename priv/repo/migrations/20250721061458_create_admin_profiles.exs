defmodule Mylib.Repo.Migrations.CreateAdminProfiles do
  use Ecto.Migration

  def change do
    create table(:admin_profiles) do
      add :full_name, :string
      add :ic, :string
      add :status, :string
      add :phone, :string
      add :address, :string
      add :date_of_birth, :date

      add :admin_id, references(:admins, on_delete: :delete_all),
      null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:admin_profiles, [:ic])
    create unique_index(:admin_profiles, [:admin_id])
  end
end
