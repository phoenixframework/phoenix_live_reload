Application.put_env(:phoenix_live_reload, MyApp.Endpoint,
  pubsub_server: MyApp.PubSub,
  live_reload: [
    url: "ws://localhost:4000",
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif)$},
      ~r{web/views/.*(ex)$},
      ~r{web/templates/.*(eex)$}
    ]
  ]
)

Application.put_env(:phoenix_live_reload, MyApp.EndpointScript,
  live_reload: [
    url: "ws://localhost:4000",
    patterns: [~r{priv/static/.*(js|css|png|jpeg|jpg|gif)$}]
  ],
  url: [path: "/foo/bar"]
)

Application.put_env(:phoenix_live_reload, MyApp.EndpointConfig,
  live_reload: [
    url: "ws://localhost:4000",
    suffix: "/foo/bar",
    iframe_attrs: [class: "foo", data_attr: "bar"],
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif)$},
      ~r{web/views/.*(ex)$},
      ~r{web/templates/.*(eex)$}
    ]
  ]
)

Application.put_env(:phoenix_live_reload, MyApp.EndpointParentWindow,
  pubsub_server: MyApp.PubSub,
  live_reload: [
    target_window: :parent,
  ]
)

Application.put_env(:phoenix_live_reload, MyApp.EndpointWrongWindow,
  pubsub_server: MyApp.PubSub,
  live_reload: [
    target_window: "other",
  ]
)

defmodule MyApp.Endpoint do
  use Phoenix.Endpoint, otp_app: :phoenix_live_reload

  socket "/socket", Phoenix.LiveReloader.Socket, websocket: true, longpoll: true
end

defmodule MyApp.EndpointScript do
  use Phoenix.Endpoint, otp_app: :phoenix_live_reload
end

defmodule MyApp.EndpointConfig do
  use Phoenix.Endpoint, otp_app: :phoenix_live_reload
end

defmodule MyApp.EndpointParentWindow do
  use Phoenix.Endpoint, otp_app: :phoenix_live_reload
end

defmodule MyApp.EndpointWrongWindow do
  use Phoenix.Endpoint, otp_app: :phoenix_live_reload
end

children = [
  {Phoenix.PubSub, name: MyApp.PubSub, adapter: Phoenix.PubSub.PG2},
  MyApp.Endpoint,
  MyApp.EndpointScript,
  MyApp.EndpointConfig,
  MyApp.EndpointParentWindow,
  MyApp.EndpointWrongWindow,
]

Supervisor.start_link(children, strategy: :one_for_one)

ExUnit.start()
