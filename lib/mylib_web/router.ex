defmodule MylibWeb.Router do
  use MylibWeb, :router

  import MylibWeb.AdminAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MylibWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_admin
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # ✅ Public scope (e.g. home page)
  scope "/", MylibWeb do
    pipe_through [:browser]

    get "/", PageController, :home
  end

  # ✅ Admin routes: register, login, forgot password
  scope "/", MylibWeb do
    pipe_through [:browser, :redirect_if_admin_is_authenticated]

    live_session :redirect_if_admin_is_authenticated,
      on_mount: [{MylibWeb.AdminAuth, :redirect_if_admin_is_authenticated}] do

      live "/admins/register", AdminRegistrationLive, :new
      live "/admins/log_in", AdminLoginLive, :new
      live "/admins/reset_password", AdminForgotPasswordLive, :new
      live "/admins/reset_password/:token", AdminResetPasswordLive, :edit
    end

    post "/admins/log_in", AdminSessionController, :create
  end

  # ✅ Admin settings: email, password changes
  scope "/", MylibWeb do
    pipe_through [:browser, :require_authenticated_admin]

    live_session :require_authenticated_admin,
      on_mount: [{MylibWeb.AdminAuth, :ensure_authenticated}] do

      live "/admins/settings", AdminSettingsLive, :edit
      live "/admins/settings/confirm_email/:token", AdminSettingsLive, :confirm_email

      # 🔐 PROTECTED resource LiveViews
      live "/users", UserLive.Index, :index
      live "/users/new", UserLive.Index, :new
      live "/users/:id/edit", UserLive.Index, :edit

      live "/users/:id", UserLive.Show, :show
      live "/users/:id/show/edit", UserLive.Show, :edit

      live "/books", BookLive.Index, :index
      live "/books/new", BookLive.Index, :new
      live "/books/:id/edit", BookLive.Index, :edit

      live "/books/:id", BookLive.Show, :show
      live "/books/:id/show/edit", BookLive.Show, :edit

      live "/loans", LoanLive.Index, :index
      live "/loans/new", LoanLive.Index, :new
      live "/loans/:id/edit", LoanLive.Index, :edit

      live "/loans/:id", LoanLive.Show, :show
      live "/loans/:id/show/edit", LoanLive.Show, :edit

      live "/admin_profiles", AdminProfileLive.Index, :index
      live "/admin_profiles/new", AdminProfileLive.Index, :new
      live "/admin_profiles/:id/edit", AdminProfileLive.Index, :edit
      live "/admin_profiles/:id", AdminProfileLive.Show, :show
      live "/admin_profiles/:id/show/edit", AdminProfileLive.Show, :edit
    end
  end

  # ✅ Logout and email confirmation
  scope "/", MylibWeb do
    pipe_through [:browser]

    delete "/admins/log_out", AdminSessionController, :delete

    live_session :current_admin,
      on_mount: [{MylibWeb.AdminAuth, :mount_current_admin}] do

      live "/admins/confirm", AdminConfirmationInstructionsLive, :new
      live "/admins/confirm/:token", AdminConfirmationLive, :edit
    end
  end

  # ✅ Optional Dev-only tools
  if Application.compile_env(:mylib, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: MylibWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
