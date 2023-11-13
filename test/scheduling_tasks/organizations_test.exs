defmodule SchedulingTasks.OrganizationsTest do
  use SchedulingTasks.DataCase

  alias SchedulingTasks.Organizations

  import SchedulingTasks.OrganizationsFixtures
  alias SchedulingTasks.Organizations.{Organization, OrganizationToken}

  describe "get_organization_by_email/1" do
    test "does not return the organization if the email does not exist" do
      refute Organizations.get_organization_by_email("unknown@example.com")
    end

    test "returns the organization if the email exists" do
      %{id: id} = organization = organization_fixture()
      assert %Organization{id: ^id} = Organizations.get_organization_by_email(organization.email)
    end
  end

  describe "get_organization_by_email_and_password/2" do
    test "does not return the organization if the email does not exist" do
      refute Organizations.get_organization_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the organization if the password is not valid" do
      organization = organization_fixture()
      refute Organizations.get_organization_by_email_and_password(organization.email, "invalid")
    end

    test "returns the organization if the email and password are valid" do
      %{id: id} = organization = organization_fixture()

      assert %Organization{id: ^id} =
               Organizations.get_organization_by_email_and_password(organization.email, valid_organization_password())
    end
  end

  describe "get_organization!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Organizations.get_organization!(-1)
      end
    end

    test "returns the organization with the given id" do
      %{id: id} = organization = organization_fixture()
      assert %Organization{id: ^id} = Organizations.get_organization!(organization.id)
    end
  end

  describe "register_organization/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Organizations.register_organization(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Organizations.register_organization(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Organizations.register_organization(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = organization_fixture()
      {:error, changeset} = Organizations.register_organization(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Organizations.register_organization(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers organizations with a hashed password" do
      email = unique_organization_email()
      {:ok, organization} = Organizations.register_organization(valid_organization_attributes(email: email))
      assert organization.email == email
      assert is_binary(organization.hashed_password)
      assert is_nil(organization.confirmed_at)
      assert is_nil(organization.password)
    end
  end

  describe "change_organization_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Organizations.change_organization_registration(%Organization{})
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = unique_organization_email()
      password = valid_organization_password()

      changeset =
        Organizations.change_organization_registration(
          %Organization{},
          valid_organization_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_organization_email/2" do
    test "returns a organization changeset" do
      assert %Ecto.Changeset{} = changeset = Organizations.change_organization_email(%Organization{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_organization_email/3" do
    setup do
      %{organization: organization_fixture()}
    end

    test "requires email to change", %{organization: organization} do
      {:error, changeset} = Organizations.apply_organization_email(organization, valid_organization_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{organization: organization} do
      {:error, changeset} =
        Organizations.apply_organization_email(organization, valid_organization_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{organization: organization} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Organizations.apply_organization_email(organization, valid_organization_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{organization: organization} do
      %{email: email} = organization_fixture()

      {:error, changeset} =
        Organizations.apply_organization_email(organization, valid_organization_password(), %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{organization: organization} do
      {:error, changeset} =
        Organizations.apply_organization_email(organization, "invalid", %{email: unique_organization_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{organization: organization} do
      email = unique_organization_email()
      {:ok, organization} = Organizations.apply_organization_email(organization, valid_organization_password(), %{email: email})
      assert organization.email == email
      assert Organizations.get_organization!(organization.id).email != email
    end
  end

  describe "deliver_update_email_instructions/3" do
    setup do
      %{organization: organization_fixture()}
    end

    test "sends token through notification", %{organization: organization} do
      token =
        extract_organization_token(fn url ->
          Organizations.deliver_update_email_instructions(organization, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert organization_token = Repo.get_by(OrganizationToken, token: :crypto.hash(:sha256, token))
      assert organization_token.organization_id == organization.id
      assert organization_token.sent_to == organization.email
      assert organization_token.context == "change:current@example.com"
    end
  end

  describe "update_organization_email/2" do
    setup do
      organization = organization_fixture()
      email = unique_organization_email()

      token =
        extract_organization_token(fn url ->
          Organizations.deliver_update_email_instructions(%{organization | email: email}, organization.email, url)
        end)

      %{organization: organization, token: token, email: email}
    end

    test "updates the email with a valid token", %{organization: organization, token: token, email: email} do
      assert Organizations.update_organization_email(organization, token) == :ok
      changed_organization = Repo.get!(Organization, organization.id)
      assert changed_organization.email != organization.email
      assert changed_organization.email == email
      assert changed_organization.confirmed_at
      assert changed_organization.confirmed_at != organization.confirmed_at
      refute Repo.get_by(OrganizationToken, organization_id: organization.id)
    end

    test "does not update email with invalid token", %{organization: organization} do
      assert Organizations.update_organization_email(organization, "oops") == :error
      assert Repo.get!(Organization, organization.id).email == organization.email
      assert Repo.get_by(OrganizationToken, organization_id: organization.id)
    end

    test "does not update email if organization email changed", %{organization: organization, token: token} do
      assert Organizations.update_organization_email(%{organization | email: "current@example.com"}, token) == :error
      assert Repo.get!(Organization, organization.id).email == organization.email
      assert Repo.get_by(OrganizationToken, organization_id: organization.id)
    end

    test "does not update email if token expired", %{organization: organization, token: token} do
      {1, nil} = Repo.update_all(OrganizationToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Organizations.update_organization_email(organization, token) == :error
      assert Repo.get!(Organization, organization.id).email == organization.email
      assert Repo.get_by(OrganizationToken, organization_id: organization.id)
    end
  end

  describe "change_organization_password/2" do
    test "returns a organization changeset" do
      assert %Ecto.Changeset{} = changeset = Organizations.change_organization_password(%Organization{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Organizations.change_organization_password(%Organization{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_organization_password/3" do
    setup do
      %{organization: organization_fixture()}
    end

    test "validates password", %{organization: organization} do
      {:error, changeset} =
        Organizations.update_organization_password(organization, valid_organization_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{organization: organization} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Organizations.update_organization_password(organization, valid_organization_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{organization: organization} do
      {:error, changeset} =
        Organizations.update_organization_password(organization, "invalid", %{password: valid_organization_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{organization: organization} do
      {:ok, organization} =
        Organizations.update_organization_password(organization, valid_organization_password(), %{
          password: "new valid password"
        })

      assert is_nil(organization.password)
      assert Organizations.get_organization_by_email_and_password(organization.email, "new valid password")
    end

    test "deletes all tokens for the given organization", %{organization: organization} do
      _ = Organizations.generate_organization_session_token(organization)

      {:ok, _} =
        Organizations.update_organization_password(organization, valid_organization_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(OrganizationToken, organization_id: organization.id)
    end
  end

  describe "generate_organization_session_token/1" do
    setup do
      %{organization: organization_fixture()}
    end

    test "generates a token", %{organization: organization} do
      token = Organizations.generate_organization_session_token(organization)
      assert organization_token = Repo.get_by(OrganizationToken, token: token)
      assert organization_token.context == "session"

      # Creating the same token for another organization should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%OrganizationToken{
          token: organization_token.token,
          organization_id: organization_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_organization_by_session_token/1" do
    setup do
      organization = organization_fixture()
      token = Organizations.generate_organization_session_token(organization)
      %{organization: organization, token: token}
    end

    test "returns organization by token", %{organization: organization, token: token} do
      assert session_organization = Organizations.get_organization_by_session_token(token)
      assert session_organization.id == organization.id
    end

    test "does not return organization for invalid token" do
      refute Organizations.get_organization_by_session_token("oops")
    end

    test "does not return organization for expired token", %{token: token} do
      {1, nil} = Repo.update_all(OrganizationToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Organizations.get_organization_by_session_token(token)
    end
  end

  describe "delete_session_token/1" do
    test "deletes the token" do
      organization = organization_fixture()
      token = Organizations.generate_organization_session_token(organization)
      assert Organizations.delete_session_token(token) == :ok
      refute Organizations.get_organization_by_session_token(token)
    end
  end

  describe "deliver_organization_confirmation_instructions/2" do
    setup do
      %{organization: organization_fixture()}
    end

    test "sends token through notification", %{organization: organization} do
      token =
        extract_organization_token(fn url ->
          Organizations.deliver_organization_confirmation_instructions(organization, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert organization_token = Repo.get_by(OrganizationToken, token: :crypto.hash(:sha256, token))
      assert organization_token.organization_id == organization.id
      assert organization_token.sent_to == organization.email
      assert organization_token.context == "confirm"
    end
  end

  describe "confirm_organization/1" do
    setup do
      organization = organization_fixture()

      token =
        extract_organization_token(fn url ->
          Organizations.deliver_organization_confirmation_instructions(organization, url)
        end)

      %{organization: organization, token: token}
    end

    test "confirms the email with a valid token", %{organization: organization, token: token} do
      assert {:ok, confirmed_organization} = Organizations.confirm_organization(token)
      assert confirmed_organization.confirmed_at
      assert confirmed_organization.confirmed_at != organization.confirmed_at
      assert Repo.get!(Organization, organization.id).confirmed_at
      refute Repo.get_by(OrganizationToken, organization_id: organization.id)
    end

    test "does not confirm with invalid token", %{organization: organization} do
      assert Organizations.confirm_organization("oops") == :error
      refute Repo.get!(Organization, organization.id).confirmed_at
      assert Repo.get_by(OrganizationToken, organization_id: organization.id)
    end

    test "does not confirm email if token expired", %{organization: organization, token: token} do
      {1, nil} = Repo.update_all(OrganizationToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Organizations.confirm_organization(token) == :error
      refute Repo.get!(Organization, organization.id).confirmed_at
      assert Repo.get_by(OrganizationToken, organization_id: organization.id)
    end
  end

  describe "deliver_organization_reset_password_instructions/2" do
    setup do
      %{organization: organization_fixture()}
    end

    test "sends token through notification", %{organization: organization} do
      token =
        extract_organization_token(fn url ->
          Organizations.deliver_organization_reset_password_instructions(organization, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert organization_token = Repo.get_by(OrganizationToken, token: :crypto.hash(:sha256, token))
      assert organization_token.organization_id == organization.id
      assert organization_token.sent_to == organization.email
      assert organization_token.context == "reset_password"
    end
  end

  describe "get_organization_by_reset_password_token/1" do
    setup do
      organization = organization_fixture()

      token =
        extract_organization_token(fn url ->
          Organizations.deliver_organization_reset_password_instructions(organization, url)
        end)

      %{organization: organization, token: token}
    end

    test "returns the organization with valid token", %{organization: %{id: id}, token: token} do
      assert %Organization{id: ^id} = Organizations.get_organization_by_reset_password_token(token)
      assert Repo.get_by(OrganizationToken, organization_id: id)
    end

    test "does not return the organization with invalid token", %{organization: organization} do
      refute Organizations.get_organization_by_reset_password_token("oops")
      assert Repo.get_by(OrganizationToken, organization_id: organization.id)
    end

    test "does not return the organization if token expired", %{organization: organization, token: token} do
      {1, nil} = Repo.update_all(OrganizationToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Organizations.get_organization_by_reset_password_token(token)
      assert Repo.get_by(OrganizationToken, organization_id: organization.id)
    end
  end

  describe "reset_organization_password/2" do
    setup do
      %{organization: organization_fixture()}
    end

    test "validates password", %{organization: organization} do
      {:error, changeset} =
        Organizations.reset_organization_password(organization, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{organization: organization} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Organizations.reset_organization_password(organization, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{organization: organization} do
      {:ok, updated_organization} = Organizations.reset_organization_password(organization, %{password: "new valid password"})
      assert is_nil(updated_organization.password)
      assert Organizations.get_organization_by_email_and_password(organization.email, "new valid password")
    end

    test "deletes all tokens for the given organization", %{organization: organization} do
      _ = Organizations.generate_organization_session_token(organization)
      {:ok, _} = Organizations.reset_organization_password(organization, %{password: "new valid password"})
      refute Repo.get_by(OrganizationToken, organization_id: organization.id)
    end
  end

  describe "inspect/2" do
    test "does not include password" do
      refute inspect(%Organization{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
