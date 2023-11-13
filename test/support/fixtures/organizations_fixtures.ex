defmodule SchedulingTasks.OrganizationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `SchedulingTasks.Organizations` context.
  """

  def unique_organization_email, do: "organization#{System.unique_integer()}@example.com"
  def valid_organization_password, do: "hello world!"

  def valid_organization_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_organization_email(),
      password: valid_organization_password()
    })
  end

  def organization_fixture(attrs \\ %{}) do
    {:ok, organization} =
      attrs
      |> valid_organization_attributes()
      |> SchedulingTasks.Organizations.register_organization()

    organization
  end

  def extract_organization_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
