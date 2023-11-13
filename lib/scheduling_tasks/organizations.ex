defmodule SchedulingTasks.Organizations do
  @moduledoc """
  The Organizations context.
  """

  import Ecto.Query, warn: false
  alias SchedulingTasks.Repo

  alias SchedulingTasks.Organizations.{Organization, OrganizationToken, OrganizationNotifier}

  ## Database getters

  @doc """
  Gets a organization by email.

  ## Examples

      iex> get_organization_by_email("foo@example.com")
      %Organization{}

      iex> get_organization_by_email("unknown@example.com")
      nil

  """

   def update_organization(%Organization{} = organization, attrs) do
    organization
    |> Organization.changeset(attrs)
    |> Repo.update()
  end

  def list_organizations do
    Repo.all(Organization)
  end

  def get_organization_by_email(email) when is_binary(email) do
    Repo.get_by(Organization, email: email)
  end

  @doc """
  Gets a organization by email and password.

  ## Examples

      iex> get_organization_by_email_and_password("foo@example.com", "correct_password")
      %Organization{}

      iex> get_organization_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_organization_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    organization = Repo.get_by(Organization, email: email)
    if Organization.valid_password?(organization, password), do: organization
  end

  @doc """
  Gets a single organization.

  Raises `Ecto.NoResultsError` if the Organization does not exist.

  ## Examples

      iex> get_organization!(123)
      %Organization{}

      iex> get_organization!(456)
      ** (Ecto.NoResultsError)

  """
  def get_organization!(id), do: Repo.get!(Organization, id)

  ## Organization registration

  @doc """
  Registers a organization.

  ## Examples

      iex> register_organization(%{field: value})
      {:ok, %Organization{}}

      iex> register_organization(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_organization(attrs) do
    %Organization{}
    |> Organization.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking organization changes.

  ## Examples

      iex> change_organization_registration(organization)
      %Ecto.Changeset{data: %Organization{}}

  """
  def change_organization_registration(%Organization{} = organization, attrs \\ %{}) do
    Organization.registration_changeset(organization, attrs, hash_password: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the organization email.

  ## Examples

      iex> change_organization_email(organization)
      %Ecto.Changeset{data: %Organization{}}

  """
  def change_organization_email(organization, attrs \\ %{}) do
    Organization.email_changeset(organization, attrs)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_organization_email(organization, "valid password", %{email: ...})
      {:ok, %Organization{}}

      iex> apply_organization_email(organization, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_organization_email(organization, password, attrs) do
    organization
    |> Organization.email_changeset(attrs)
    |> Organization.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the organization email using the given token.

  If the token matches, the organization email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_organization_email(organization, token) do
    context = "change:#{organization.email}"

    with {:ok, query} <- OrganizationToken.verify_change_email_token_query(token, context),
         %OrganizationToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(organization_email_multi(organization, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp organization_email_multi(organization, email, context) do
    changeset =
      organization
      |> Organization.email_changeset(%{email: email})
      |> Organization.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:organization, changeset)
    |> Ecto.Multi.delete_all(:tokens, OrganizationToken.organization_and_contexts_query(organization, [context]))
  end

  @doc """
  Delivers the update email instructions to the given organization.

  ## Examples

      iex> deliver_update_email_instructions(organization, current_email, &Routes.organization_update_email_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_update_email_instructions(%Organization{} = organization, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, organization_token} = OrganizationToken.build_email_token(organization, "change:#{current_email}")

    Repo.insert!(organization_token)
    OrganizationNotifier.deliver_update_email_instructions(organization, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the organization password.

  ## Examples

      iex> change_organization_password(organization)
      %Ecto.Changeset{data: %Organization{}}

  """
  def change_organization_password(organization, attrs \\ %{}) do
    Organization.password_changeset(organization, attrs, hash_password: false)
  end

  @doc """
  Updates the organization password.

  ## Examples

      iex> update_organization_password(organization, "valid password", %{password: ...})
      {:ok, %Organization{}}

      iex> update_organization_password(organization, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_organization_password(organization, password, attrs) do
    changeset =
      organization
      |> Organization.password_changeset(attrs)
      |> Organization.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:organization, changeset)
    |> Ecto.Multi.delete_all(:tokens, OrganizationToken.organization_and_contexts_query(organization, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{organization: organization}} -> {:ok, organization}
      {:error, :organization, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_organization_session_token(organization) do
    {token, organization_token} = OrganizationToken.build_session_token(organization)
    Repo.insert!(organization_token)
    token
  end

  @doc """
  Gets the organization with the given signed token.
  """
  def get_organization_by_session_token(token) do
    {:ok, query} = OrganizationToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_session_token(token) do
    Repo.delete_all(OrganizationToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc """
  Delivers the confirmation email instructions to the given organization.

  ## Examples

      iex> deliver_organization_confirmation_instructions(organization, &Routes.organization_confirmation_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_organization_confirmation_instructions(confirmed_organization, &Routes.organization_confirmation_url(conn, :edit, &1))
      {:error, :already_confirmed}

  """
  def deliver_organization_confirmation_instructions(%Organization{} = organization, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if organization.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, organization_token} = OrganizationToken.build_email_token(organization, "confirm")
      Repo.insert!(organization_token)
      OrganizationNotifier.deliver_confirmation_instructions(organization, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a organization by the given token.

  If the token matches, the organization account is marked as confirmed
  and the token is deleted.
  """
  def confirm_organization(token) do
    with {:ok, query} <- OrganizationToken.verify_email_token_query(token, "confirm"),
         %Organization{} = organization <- Repo.one(query),
         {:ok, %{organization: organization}} <- Repo.transaction(confirm_organization_multi(organization)) do
      {:ok, organization}
    else
      _ -> :error
    end
  end

  defp confirm_organization_multi(organization) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:organization, Organization.confirm_changeset(organization))
    |> Ecto.Multi.delete_all(:tokens, OrganizationToken.organization_and_contexts_query(organization, ["confirm"]))
  end

  ## Reset password

  @doc """
  Delivers the reset password email to the given organization.

  ## Examples

      iex> deliver_organization_reset_password_instructions(organization, &Routes.organization_reset_password_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_organization_reset_password_instructions(%Organization{} = organization, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, organization_token} = OrganizationToken.build_email_token(organization, "reset_password")
    Repo.insert!(organization_token)
    OrganizationNotifier.deliver_reset_password_instructions(organization, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the organization by reset password token.

  ## Examples

      iex> get_organization_by_reset_password_token("validtoken")
      %Organization{}

      iex> get_organization_by_reset_password_token("invalidtoken")
      nil

  """
  def get_organization_by_reset_password_token(token) do
    with {:ok, query} <- OrganizationToken.verify_email_token_query(token, "reset_password"),
         %Organization{} = organization <- Repo.one(query) do
      organization
    else
      _ -> nil
    end
  end

  @doc """
  Resets the organization password.

  ## Examples

      iex> reset_organization_password(organization, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %Organization{}}

      iex> reset_organization_password(organization, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_organization_password(organization, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:organization, Organization.password_changeset(organization, attrs))
    |> Ecto.Multi.delete_all(:tokens, OrganizationToken.organization_and_contexts_query(organization, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{organization: organization}} -> {:ok, organization}
      {:error, :organization, changeset, _} -> {:error, changeset}
    end
  end
end
