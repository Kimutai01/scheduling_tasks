defmodule SchedulingTasksWeb.OrganizationConfirmationController do
  use SchedulingTasksWeb, :controller

  alias SchedulingTasks.Organizations

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"organization" => %{"email" => email}}) do
    if organization = Organizations.get_organization_by_email(email) do
      Organizations.deliver_organization_confirmation_instructions(
        organization,
        &Routes.organization_confirmation_url(conn, :edit, &1)
      )
    end

    conn
    |> put_flash(
      :info,
      "If your email is in our system and it has not been confirmed yet, " <>
        "you will receive an email with instructions shortly."
    )
    |> redirect(to: "/")
  end

  def edit(conn, %{"token" => token}) do
    render(conn, "edit.html", token: token)
  end

  # Do not log in the organization after confirmation to avoid a
  # leaked token giving the organization access to the account.
  def update(conn, %{"token" => token}) do
    case Organizations.confirm_organization(token) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Organization confirmed successfully.")
        |> redirect(to: "/")

      :error ->
        # If there is a current organization and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the organization themselves, so we redirect without
        # a warning message.
        case conn.assigns do
          %{current_organization: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            redirect(conn, to: "/")

          %{} ->
            conn
            |> put_flash(:error, "Organization confirmation link is invalid or it has expired.")
            |> redirect(to: "/")
        end
    end
  end
end
