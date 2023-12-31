defmodule SchedulingTasksWeb.OrganizationResetPasswordController do
  use SchedulingTasksWeb, :controller

  alias SchedulingTasks.Organizations

  plug :get_organization_by_reset_password_token when action in [:edit, :update]

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"organization" => %{"email" => email}}) do
    if organization = Organizations.get_organization_by_email(email) do
      Organizations.deliver_organization_reset_password_instructions(
        organization,
        &Routes.organization_reset_password_url(conn, :edit, &1)
      )
    end

    conn
    |> put_flash(
      :info,
      "If your email is in our system, you will receive instructions to reset your password shortly."
    )
    |> redirect(to: "/")
  end

  def edit(conn, _params) do
    render(conn, "edit.html", changeset: Organizations.change_organization_password(conn.assigns.organization))
  end

  # Do not log in the organization after reset password to avoid a
  # leaked token giving the organization access to the account.
  def update(conn, %{"organization" => organization_params}) do
    case Organizations.reset_organization_password(conn.assigns.organization, organization_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Password reset successfully.")
        |> redirect(to: Routes.organization_session_path(conn, :new))

      {:error, changeset} ->
        render(conn, "edit.html", changeset: changeset)
    end
  end

  defp get_organization_by_reset_password_token(conn, _opts) do
    %{"token" => token} = conn.params

    if organization = Organizations.get_organization_by_reset_password_token(token) do
      conn |> assign(:organization, organization) |> assign(:token, token)
    else
      conn
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: "/")
      |> halt()
    end
  end
end
