defmodule SchedulingTasksWeb.UsersLive.Index do
  alias SchedulingTasks.Accounts

  use SchedulingTasksWeb, :dashboard_live_view
  @impl true
  def mount(_params, session, socket) do
    current_user = Accounts.get_user_by_session_token(session["user_token"])

    users = Accounts.list_users()

    {:ok,
     socket
     |> assign(:url, "/users")
     |> assign(:users, users)
     |> assign(:current_user, current_user)}
  end

  def handle_event("verify", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)

    {:ok, user} = Accounts.update_user(user, %{role: "verified"})
    IO.inspect(user)

    users = Accounts.list_users()

    {:noreply,
     socket
     |> assign(:users, users)
     |> put_flash(:info, "User verified")}
  end

   def handle_event("verify", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)

    {:ok, user} = Accounts.update_user(user, %{role: "verified"})
    IO.inspect(user)

    users = Accounts.list_users()

    {:noreply,
     socket
     |> assign(:users, users)
     |> put_flash(:info, "User verified")}
  end

  def handle_event("unverify", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)

    {:ok, user} = Accounts.update_user(user, %{role: "unverified"})
    IO.inspect(user)

    users = Accounts.list_users()

    {:noreply,
     socket
     |> assign(:users, users)
     |> put_flash(:info, "User unverified")}
  end
end
