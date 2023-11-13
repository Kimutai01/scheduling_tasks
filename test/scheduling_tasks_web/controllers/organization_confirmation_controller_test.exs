defmodule SchedulingTasksWeb.OrganizationConfirmationControllerTest do
  use SchedulingTasksWeb.ConnCase, async: true

  alias SchedulingTasks.Organizations
  alias SchedulingTasks.Repo
  import SchedulingTasks.OrganizationsFixtures

  setup do
    %{organization: organization_fixture()}
  end

  describe "GET /organizations/confirm" do
    test "renders the resend confirmation page", %{conn: conn} do
      conn = get(conn, Routes.organization_confirmation_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Resend confirmation instructions</h1>"
    end
  end

  describe "POST /organizations/confirm" do
    @tag :capture_log
    test "sends a new confirmation token", %{conn: conn, organization: organization} do
      conn =
        post(conn, Routes.organization_confirmation_path(conn, :create), %{
          "organization" => %{"email" => organization.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.get_by!(Organizations.OrganizationToken, organization_id: organization.id).context == "confirm"
    end

    test "does not send confirmation token if Organization is confirmed", %{conn: conn, organization: organization} do
      Repo.update!(Organizations.Organization.confirm_changeset(organization))

      conn =
        post(conn, Routes.organization_confirmation_path(conn, :create), %{
          "organization" => %{"email" => organization.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      refute Repo.get_by(Organizations.OrganizationToken, organization_id: organization.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.organization_confirmation_path(conn, :create), %{
          "organization" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.all(Organizations.OrganizationToken) == []
    end
  end

  describe "GET /organizations/confirm/:token" do
    test "renders the confirmation page", %{conn: conn} do
      conn = get(conn, Routes.organization_confirmation_path(conn, :edit, "some-token"))
      response = html_response(conn, 200)
      assert response =~ "<h1>Confirm account</h1>"

      form_action = Routes.organization_confirmation_path(conn, :update, "some-token")
      assert response =~ "action=\"#{form_action}\""
    end
  end

  describe "POST /organizations/confirm/:token" do
    test "confirms the given token once", %{conn: conn, organization: organization} do
      token =
        extract_organization_token(fn url ->
          Organizations.deliver_organization_confirmation_instructions(organization, url)
        end)

      conn = post(conn, Routes.organization_confirmation_path(conn, :update, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "Organization confirmed successfully"
      assert Organizations.get_organization!(organization.id).confirmed_at
      refute get_session(conn, :organization_token)
      assert Repo.all(Organizations.OrganizationToken) == []

      # When not logged in
      conn = post(conn, Routes.organization_confirmation_path(conn, :update, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Organization confirmation link is invalid or it has expired"

      # When logged in
      conn =
        build_conn()
        |> log_in_organization(organization)
        |> post(Routes.organization_confirmation_path(conn, :update, token))

      assert redirected_to(conn) == "/"
      refute get_flash(conn, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, organization: organization} do
      conn = post(conn, Routes.organization_confirmation_path(conn, :update, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Organization confirmation link is invalid or it has expired"
      refute Organizations.get_organization!(organization.id).confirmed_at
    end
  end
end
