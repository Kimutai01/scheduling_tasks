defmodule SchedulingTasks.Repo.Migrations.CreateOrganizationsAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:organizations) do
      add :email, :citext, null: false
      add :name, :string, null: false
      add :phone_number, :string, null: false
      add :address, :string, null: false
      add :website, :string, null: false
      add :role, :string, null: false, default: "unverified"
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      timestamps()
    end

    create unique_index(:organizations, [:email])

    create table(:organizations_tokens) do
      add :organization_id, references(:organizations, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:organizations_tokens, [:organization_id])
    create unique_index(:organizations_tokens, [:context, :token])
  end
end
