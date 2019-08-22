defmodule Ecto.Integration.UpsertTest do
  use ExUnit.Case, async: true

  import Ecto.Migrator, only: [up: 4]
  alias Ecto.Integration.PoolRepo

  defmodule UpsertMigration do
    use Ecto.Migration

    @table table(:upserts)

    def change do
      create @table do
        add :note, :text
        timestamps()
      end

      create unique_index(:upserts, [:note])
    end
  end

  defmodule Upsert do
    use Ecto.Integration.Schema

    schema "upserts" do
      field :note
      timestamps()
    end

    def changeset(struct, attrs) do
      struct
      |> Ecto.Changeset.cast(attrs, [:note])
    end
  end

  @base_migration 2_000_000

  setup_all do
    ExUnit.CaptureLog.capture_log(fn ->
      num = @base_migration + System.unique_integer([:positive])
      up(PoolRepo, num, UpsertMigration, log: false)
    end)

    :ok
  end

  test "should perform upsert without touching inserted_at timestamp and return correct value" do
    {:ok, u1} = PoolRepo.insert(Upsert.changeset(%Upsert{}, %{note: "Hey there"}))
    :timer.sleep(2000)
    {:ok, u2} = PoolRepo.insert(Upsert.changeset(%Upsert{}, %{note: "Hey there"}),
                                on_conflict: {:replace, [:note]},
                                conflict_target: :note)

    assert u1.id == u2.id
    assert u1.inserted_at == PoolRepo.get!(Upsert, u1.id).inserted_at
    assert u1.inserted_at == u2.inserted_at
  end
end
