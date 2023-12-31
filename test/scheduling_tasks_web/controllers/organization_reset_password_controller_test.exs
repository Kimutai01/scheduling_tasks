defmodule SchedulingTasksWeb.OrganizationResetPasswordControllerTest do
  use SchedulingTasksWeb.ConnCase, async: true

  alias SchedulingTasks.Organizations
  alias SchedulingTasks.Repo
  import SchedulingTasks.OrganizationsFixtures

  setup do
    %{organization: organization_fixture()}
  end

  describe "GET /organizations/reset_password" do
    test "renders the reset password page", %{conn: conn} do
      conn = get(conn, Routes.organization_reset_password_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Forgot your password?</h1>"
    end
  end

  describe "POST /organizations/reset_password" do
    @tag :capture_log
    test "sends a new reset password token", %{conn: conn, organization: organization} do
      conn =
        post(conn, Routes.organization_reset_password_path(conn, :create), %{
          "organization" => %{"email" => organization.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.get_by!(Organizations.OrganizationToken, organization_id: organization.id).context == "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.organization_reset_password_path(conn, :create), %{
          "organization" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.all(Organizations.OrganizationToken) == []
    end
  end

  describe "GET /organizations/reset_password/:token" do
    setup %{organization: organization} do
      token =
        extract_organization_token(fn url ->
          Organizations.deliver_organization_reset_password_instructions(organization, url)
        end)

      %{token: token}
    end

    test "renders reset password", %{conn: conn, token: token} do
      conn = get(conn, Routes.organization_reset_password_path(conn, :edit, token))
      assert html_response(conn, 200) =~ "<h1>Reset password</h1>"
    end

    test "does not render reset password with invalid token", %{conn: conn} do
      conn = get(conn, Routes.organization_reset_password_path(conn, :edit, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Reset password link is invalid or it has expired"
    end
  end

  describe "PUT /organizations/reset_password/:token" do
    setup %{organization: organization} do
      token =
        extract_organization_token(fn url ->
          Organizations.deliver_organization_reset_password_instructions(organization, url)
        end)

      %{token: token}
    end

    test "resets password once", %{conn: conn, organization: organization, token: token} do
      conn =
        put(conn, Routes.organization_reset_password_path(conn, :update, token), %{
          "organization" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(conn) == Routes.organization_session_path(conn, :new)
      refute get_session(conn, :organization_token)
      assert get_flash(conn, :info) =~ "Password reset successfully"
      assert Organizations.get_organization_by_email_and_password(organization.email, "new valid password")
    end

    test "does not reset password on invalid data", %{conn: conn, token: token} do
      conn =
        put(conn, Routes.organization_reset_password_path(conn, :update, token), %{
          "organization" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Reset password</h1>"
      assert response =~ "should be at least 12 character(s)"
      assert response =~ "does not match password"
    end

    test "does not reset password with invalid token", %{conn: conn} do
      conn = put(conn, Routes.organization_reset_password_path(conn, :update, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Reset password link is invalid or it has expired"
    end
  end
end
