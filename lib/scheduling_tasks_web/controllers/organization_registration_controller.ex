defmodule SchedulingTasksWeb.OrganizationRegistrationController do
  use SchedulingTasksWeb, :controller

  alias SchedulingTasks.Organizations
  alias SchedulingTasks.Organizations.Organization
  alias SchedulingTasksWeb.OrganizationAuth

  def new(conn, _params) do
    changeset = Organizations.change_organization_registration(%Organization{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"organization" => organization_params}) do
    case Organizations.register_organization(organization_params) do
      {:ok, organization} ->
        {:ok, _} =
          Organizations.deliver_organization_confirmation_instructions(
            organization,
            &Routes.organization_confirmation_url(conn, :edit, &1)
          )

        conn
        |> put_flash(:info, "Organization created successfully.")
        |> OrganizationAuth.log_in_organization(organization)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
