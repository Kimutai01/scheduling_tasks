defmodule SchedulingTasksWeb.OrganizationAuth do
  import Plug.Conn
  import Phoenix.Controller

  alias SchedulingTasks.Organizations
  alias SchedulingTasksWeb.Router.Helpers, as: Routes

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in OrganizationToken.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_scheduling_tasks_web_organization_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Logs the organization in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  def log_in_organization(conn, organization, params \\ %{}) do
    token = Organizations.generate_organization_session_token(organization)
    organization_return_to = get_session(conn, :organization_return_to)

    conn
    |> renew_session()
    |> put_session(:organization_token, token)
    |> put_session(:live_socket_id, "organizations_sessions:#{Base.url_encode64(token)}")
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: organization_return_to || signed_in_path(conn))
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the organization out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_organization(conn) do
    organization_token = get_session(conn, :organization_token)
    organization_token && Organizations.delete_session_token(organization_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      SchedulingTasksWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: "/")
  end

  @doc """
  Authenticates the organization by looking into the session
  and remember me token.
  """
  def fetch_current_organization(conn, _opts) do
    {organization_token, conn} = ensure_organization_token(conn)
    organization = organization_token && Organizations.get_organization_by_session_token(organization_token)
    assign(conn, :current_organization, organization)
  end

  defp ensure_organization_token(conn) do
    if organization_token = get_session(conn, :organization_token) do
      {organization_token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if organization_token = conn.cookies[@remember_me_cookie] do
        {organization_token, put_session(conn, :organization_token, organization_token)}
      else
        {nil, conn}
      end
    end
  end

  @doc """
  Used for routes that require the organization to not be authenticated.
  """
  def redirect_if_organization_is_authenticated(conn, _opts) do
    if conn.assigns[:current_organization] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the organization to be authenticated.

  If you want to enforce the organization email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_organization(conn, _opts) do
    if conn.assigns[:current_organization] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: Routes.organization_session_path(conn, :new))
      |> halt()
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :organization_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: "/"
end
