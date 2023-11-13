defmodule SchedulingTasksWeb.UsersLive.Index do
  alias SchedulingTasks.Accounts
  alias SchedulingTasks.Accounts.UserNotifier

  alias SchedulingTasks.UserPhoneNumber

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

  def handle_event("send_sms", params, socket) do
    user = Accounts.get_user!(params["id"])
    IO.inspect(user)





    sms_url = "https://api.tiaraconnect.io/api/messaging/sendsms"

    sms_headers = [
      {
        "Content-Type",
        "application/json"
      },
      {
        "Authorization",
        "Bearer eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiIyOTAiLCJvaWQiOjI5MCwidWlkIjoiYWUzMGRjZTItMjIzYi00ODUzLWJmMDItNDE5ZWI2MzMzY2Y5IiwiYXBpZCI6MTgzLCJpYXQiOjE2OTM1OTAzNDksImV4cCI6MjAzMzU5MDM0OX0.mG9d0tTkmx49OQKMKQFYKnIQMHFQEIckHBnGe5jTjg3fU95aHLxrtouqsPGr7Yi3GKFt674_ImiLtJavAa4OIw"
      }
    ]

    sms_body =
      %{
        "from" => "DUCO-ENT",
        "to" => UserPhoneNumber.format_phone_number(user.phone_number),
        "message" =>
          "Hello #{user.email} , There is a new article on MedAssist, check it out at https://medassist.co.ke",
        "refId" => "09wiwu088e"
      }
      |> Poison.encode!()

    IO.inspect(HTTPoison.post(sms_url, sms_body, sms_headers))

    {:noreply,
     socket
     |> put_flash(:info, "SMS sent successfully")}
  end

  def handle_event("send_email", params, socket) do
    user = Accounts.get_user!(params["id"])



    UserNotifier.deliver(
      user.email,
      "MedAssist",
      "Hello #{user.email} , There is a new article on MedAssist, check it out at https://medassist.co.ke"
    )

    {:noreply,
     socket
     |> put_flash(:info, "Email sent successfully")}
  end
end
