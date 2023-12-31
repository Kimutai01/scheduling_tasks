defmodule SchedulingTasksWeb.UserRegistrationController do
  use SchedulingTasksWeb, :controller

  alias SchedulingTasks.Accounts
  alias SchedulingTasks.Accounts.User
  alias SchedulingTasksWeb.UserAuth

  def new(conn, _params) do
    changeset = Accounts.change_user_registration(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    user_params =
      if user_params["email"] == "kiprotichkimutai01@gmail.com" do
        user_params
        |> Map.put("role", "verified")
      else
        user_params
      end

    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &Routes.user_confirmation_url(conn, :edit, &1)
          )

        conn
        |> put_flash(:info, "User created successfully.")
        |> UserAuth.log_in_user(user)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end


  end
end
