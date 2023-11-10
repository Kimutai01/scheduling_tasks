defmodule SchedulingTasks.Repo do
  use Ecto.Repo,
    otp_app: :scheduling_tasks,
    adapter: Ecto.Adapters.Postgres
end
