defmodule SchedulingTasksWeb.HomeLive.Index do
  use SchedulingTasksWeb, :live_view
  alias SchedulingTasks.Accounts

  @spec handle_event(<<_::64>>, any(), any()) :: {:noreply, any()}
  def handle_event("validate", params, socket) do
    IO.inspect(params)

    {
      :noreply,
      socket

      #  |> assign(:models, models)}
    }
  end

  @impl true
  def mount(_params, session, socket) do
    user_signed_in =
      if is_nil(session["user_token"]) do
        false
      else
        true
      end

    current_user =
      if user_signed_in do
        Accounts.get_user_by_session_token(session["user_token"])
      end

    IO.inspect(current_user)

    {:ok,
     socket
     |> assign(:user_signed_in, user_signed_in)
     |> assign(:current_user, current_user)}
  end
end
