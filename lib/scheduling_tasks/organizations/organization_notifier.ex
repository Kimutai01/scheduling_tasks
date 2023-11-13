defmodule SchedulingTasks.Organizations.OrganizationNotifier do
  import Swoosh.Email

  alias SchedulingTasks.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
        |> from({"Scheduling tasks", "thekultureke@gmail.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(organization, url) do
    deliver(organization.email, "Confirmation instructions", """

    ==============================

    Hi #{organization.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a organization password.
  """
  def deliver_reset_password_instructions(organization, url) do
    deliver(organization.email, "Reset password instructions", """

    ==============================

    Hi #{organization.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a organization email.
  """
  def deliver_update_email_instructions(organization, url) do
    deliver(organization.email, "Update email instructions", """

    ==============================

    Hi #{organization.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
