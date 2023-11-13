defmodule SchedulingTasksWeb.OrganizationSettingsController do
  use SchedulingTasksWeb, :controller

  alias SchedulingTasks.Organizations
  alias SchedulingTasksWeb.OrganizationAuth

  plug :assign_email_and_password_changesets

  def edit(conn, _params) do
    render(conn, "edit.html")
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "organization" => organization_params} = params
    organization = conn.assigns.current_organization

    case Organizations.apply_organization_email(organization, password, organization_params) do
      {:ok, applied_organization} ->
        Organizations.deliver_update_email_instructions(
          applied_organization,
          organization.email,
          &Routes.organization_settings_url(conn, :confirm_email, &1)
        )

        conn
        |> put_flash(
          :info,
          "A link to confirm your email change has been sent to the new address."
        )
        |> redirect(to: Routes.organization_settings_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", email_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "organization" => organization_params} = params
    organization = conn.assigns.current_organization

    case Organizations.update_organization_password(organization, password, organization_params) do
      {:ok, organization} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:organization_return_to, Routes.organization_settings_path(conn, :edit))
        |> OrganizationAuth.log_in_organization(organization)

      {:error, changeset} ->
        render(conn, "edit.html", password_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Organizations.update_organization_email(conn.assigns.current_organization, token) do
      :ok ->
        conn
        |> put_flash(:info, "Email changed successfully.")
        |> redirect(to: Routes.organization_settings_path(conn, :edit))

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> redirect(to: Routes.organization_settings_path(conn, :edit))
    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    organization = conn.assigns.current_organization

    conn
    |> assign(:email_changeset, Organizations.change_organization_email(organization))
    |> assign(:password_changeset, Organizations.change_organization_password(organization))
  end
end
