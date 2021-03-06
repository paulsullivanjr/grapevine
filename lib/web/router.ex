defmodule Web.Router do
  use Web, :router

  pipeline :browser do
    plug(:accepts, ["html", "json"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(Web.Plugs.FetchUser)
  end

  pipeline :api do
    plug(:accepts, ["json"])
    plug Web.Plugs.FetchUser, api: true
  end

  pipeline :api_authenticated do
    plug Web.Plugs.EnsureUser, api: true
  end

  pipeline :logged_in do
    plug Web.Plugs.EnsureUser
  end

  scope "/", Web do
    pipe_through(:browser)

    get("/", PageController, :index)

    get("/conduct", PageController, :conduct)

    get("/docs", PageController, :docs)

    get("/media", PageController, :media)

    if Mix.env() == :dev do
      get("/colors", PageController, :colors)
    end

    resources("/mssp", MSSPController, only: [:index])

    get("/games/online", GameController, :online)

    resources("/games", GameController, only: [:index, :show]) do
      resources("/achievements", AchievementController, only: [:index])

      get("/stats/players", GameStatisticController, :players, as: :statistic)
    end

    resources("/register", RegistrationController, only: [:new, :create])

    get("/register/reset", RegistrationResetController, :new)
    post("/register/reset", RegistrationResetController, :create)

    get("/register/reset/verify", RegistrationResetController, :edit)
    post("/register/reset/verify", RegistrationResetController, :update)

    resources("/sign-in", SessionController, only: [:new, :create, :delete], singleton: true)
  end

  scope "/", Web do
    pipe_through([:browser, :logged_in])

    resources("/chat", ChatController, only: [:index])

    get("/games/:game_id/play", PlayController, :show)
  end

  scope "/manage", Web.Manage, as: :manage do
    pipe_through([:browser, :logged_in])

    resources("/achievements", AchievementController, only: [:edit, :update, :delete])

    resources("/characters", CharacterController, only: [:index]) do
      post("/approve", CharacterController, :approve, as: :action)

      post("/deny", CharacterController, :deny, as: :action)
    end

    resources("/connections", ConnectionController, only: [:delete])

    resources("/events", EventController, only: [:edit, :update, :delete])

    resources("/games", GameController, only: [:index, :show, :new, :create, :edit, :update]) do
      resources("/achievements", AchievementController, only: [:index, :new, :create])

      resources("/client", ClientController, only: [:show], singleton: true)

      resources("/connections", ConnectionController, only: [:create])

      resources("/events", EventController, only: [:index, :new, :create])

      resources("/gauges", GaugeController, only: [:new, :create])

      resources("/redirect-uris", RedirectURIController, only: [:create])
    end

    post("/games/:id/regenerate", GameController, :regenerate)

    resources("/gauges", GaugeController, only: [:edit, :update, :delete])

    resources("/redirect-uris", RedirectURIController, only: [:delete])

    resources("/settings", SettingController, only: [:show, :edit, :update], singleton: true)
  end

  scope "/", Web do
    pipe_through([:api, :api_authenticated])

    get("/users/me", UserController, :show)
  end

  scope "/oauth", Web.Oauth do
    pipe_through([:browser, :logged_in])

    get("/authorize", AuthorizationController, :new)

    resources("/authorizations", AuthorizationController, only: [:update], singleton: true)
  end

  scope "/oauth", Web.Oauth do
    pipe_through([:api])

    post("/token", TokenController, :create)
  end

  if Mix.env() == :dev do
    forward("/emails/sent", Bamboo.SentEmailViewerPlug)
  end
end
