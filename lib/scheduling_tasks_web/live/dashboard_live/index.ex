defmodule SchedulingTasksWeb.DashboardLive.Index do
  use SchedulingTasksWeb, :dashboard_live_view

  alias SchedulingTasks.Users
  alias SchedulingTasks.Events
  alias SchedulingTasks.Tickets

  def mount(params, session, socket) do




    user_signed_in =
      if is_nil(session["user_token"]) do
        false
      else
        true
      end

    current_user =
      if user_signed_in do
        Users.get_user_by_session_token(session["user_token"])
      end

    IO.inspect(Tickets.list_tickets())


    staff = Users.list_users() |> Enum.filter(fn x -> x.role == "verified" end) |> Enum.count()

    {:ok,
     socket
     |> assign(:url, "/dashboard")
     |> assign(:user_signed_in, user_signed_in)
     |> assign(:current_user, current_user)

     |> assign(:staff, staff)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Quotes")
    |> assign(:quote, nil)
  end

  def handle_event("send_sms", params, socket) do
    IO.inspect(params)

    ticket = Tickets.get_ticket!(params["id"])

    sms_url = "https://api.tiaraconnect.io/api/messaging/sendsms"

    sms_headers = [
      {
        "Content-Type",
        "application/json"
      },
      {
        "Authorization",
        "Bearer eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiIzMDciLCJvaWQiOjMwNywidWlkIjoiY2VkZTU3ZWItMWI1NS00MTQ0LWI5MzEtMzU2Y2MwNDVkN2UzIiwiYXBpZCI6MTk2LCJpYXQiOjE2OTc1NDg4MDcsImV4cCI6MjAzNzU0ODgwN30.GF7Hw_fvQryzd1NdPpHsCz9zh_8ykVdzHRTLrm5rceeOX4u6QKhxtiCgGsxtiH1qdr6-Q0U3Eh-2ySrvTfv9qw"
      }
    ]

    sms_body =
      %{
        "from" => "TIARACONECT",
        "to" => ticket.phone_number,
        "message" => "Your booking has been confirmed.",
        "refId" => "09wiwu088e"
      }
      |> Poison.encode!()

    IO.inspect(HTTPoison.post(sms_url, sms_body, sms_headers))

    {:noreply,
     socket
     |> put_flash(:info, "SMS sent successfully")}

    {:noreply,
     socket
     |> put_flash(:info, "SMS sent successfully")}
  end

  @spec handle_event(<<_::64>>, any(), any()) :: {:noreply, any()}
  def handle_event("validate", _params, socket) do
    {:noreply,
     socket
     |> assign(:error_modal, false)}
  end

  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> apply_action(socket.assigns.live_action, params)}
  end
end
