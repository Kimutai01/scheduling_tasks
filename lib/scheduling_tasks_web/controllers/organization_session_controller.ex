defmodule SchedulingTasksWeb.OrganizationSessionController do
  use SchedulingTasksWeb, :controller

  alias SchedulingTasks.Organizations
  alias SchedulingTasksWeb.OrganizationAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"organization" => organization_params}) do
    %{"email" => email, "password" => password} = organization_params

    if organization = Organizations.get_organization_by_email_and_password(email, password) do
      OrganizationAuth.log_in_organization(conn, organization, organization_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      render(conn, "new.html", error_message: "Invalid email or password")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> OrganizationAuth.log_out_organization()
  end
end
