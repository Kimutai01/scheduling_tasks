defmodule SchedulingTasksWeb.Router do
  alias Hex.API.Key.Organization
  use SchedulingTasksWeb, :router

  import SchedulingTasksWeb.OrganizationAuth

  import SchedulingTasksWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {SchedulingTasksWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_organization
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SchedulingTasksWeb do
    pipe_through :browser
    live "/about", AboutLive.Index, :index
    live "/", HomeLive.Index, :index

    # get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", SchedulingTasksWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      # live_dashboard "/dashboard", metrics: SchedulingTasksWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", SchedulingTasksWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", SchedulingTasksWeb do
    pipe_through [:browser, :require_authenticated_user]

    live "/users", UsersLive.Index, :index
    live "/organizations", OrganizationsLive.Index, :index
    live "/dashboard", DashboardLive.Index, :index
    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
  end

  scope "/", SchedulingTasksWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
  end

  ## Authentication routes

  scope "/", SchedulingTasksWeb do
    pipe_through [:browser, :redirect_if_organization_is_authenticated]

    get "/organizations/register", OrganizationRegistrationController, :new
    post "/organizations/register", OrganizationRegistrationController, :create
    get "/organizations/log_in", OrganizationSessionController, :new
    post "/organizations/log_in", OrganizationSessionController, :create
    get "/organizations/reset_password", OrganizationResetPasswordController, :new
    post "/organizations/reset_password", OrganizationResetPasswordController, :create
    get "/organizations/reset_password/:token", OrganizationResetPasswordController, :edit
    put "/organizations/reset_password/:token", OrganizationResetPasswordController, :update
  end

  scope "/", SchedulingTasksWeb do
    pipe_through [:browser, :require_authenticated_organization]

    get "/organizations/settings", OrganizationSettingsController, :edit
    put "/organizations/settings", OrganizationSettingsController, :update
    get "/organizations/settings/confirm_email/:token", OrganizationSettingsController, :confirm_email
  end

  scope "/", SchedulingTasksWeb do
    pipe_through [:browser]

    delete "/organizations/log_out", OrganizationSessionController, :delete
    get "/organizations/confirm", OrganizationConfirmationController, :new
    post "/organizations/confirm", OrganizationConfirmationController, :create
    get "/organizations/confirm/:token", OrganizationConfirmationController, :edit
    post "/organizations/confirm/:token", OrganizationConfirmationController, :update
  end
end
