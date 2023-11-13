defmodule SchedulingTasksWeb.OrganizationsLive.Index do
  alias SchedulingTasks.Organizations

  alias SchedulingTasks.Accounts

  use SchedulingTasksWeb, :dashboard_live_view
  @impl true
  def mount(_params, session, socket) do
    current_user = Accounts.get_user_by_session_token(session["user_token"])

    users = Organizations.list_organizations()

    {:ok,
     socket
     |> assign(:url, "/users")
     |> assign(:users, users)
     |> assign(:current_user, current_user)}
  end

  def handle_event("verify", %{"id" => id}, socket) do
    user = Organizations.get_organization!(id)

    {:ok, user} = Organizations.update_organization(user, %{role: "verified"})
    IO.inspect(user)

    users = Organizations.list_organizations()

    {:noreply,
     socket
     |> assign(:users, users)
     |> put_flash(:info, "User verified")}
  end

   def handle_event("verify", %{"id" => id}, socket) do
    user = Organizations.get_organization!(id)

    {:ok, user} = Organizations.update_organization(user, %{role: "organization"})
    IO.inspect(user)

    users = Organizations.list_organizations()

    {:noreply,
     socket
     |> assign(:users, users)
     |> put_flash(:info, "User verified")}
  end

  def handle_event("unverify", %{"id" => id}, socket) do
    user = Organizations.get_organization!(id)

    {:ok, user} = Organizations.update_organization(user, %{role: "unverified"})
    IO.inspect(user)

    users = Organizations.list_organizations()

    {:noreply,
     socket
     |> assign(:users, users)
     |> put_flash(:info, "User unverified")}
  end
end
