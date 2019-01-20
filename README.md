A project for live-reload functionality for [Phoenix](http://github.com/phoenixframework/phoenix) during development.

## Usage

You can use `phoenix_live_reload` in your projects by adding it to your `mix.exs` dependencies:

```elixir
def deps do
  [{:phoenix_live_reload, "~> 1.2"}]
end
```

You can configure the reloading interval in ms in your `config/dev.exs`:

```elixir
# Watch static and templates for browser reloading.
config :my_app, MyAppWeb.Endpoint,
  live_reload: [
    interval: 1000,
    patterns: [
      ...
```

The default interval is 100ms.

## Backends

This project uses [`FileSystem`](https://github.com/falood/file_system) as a dependency to watch your filesystem whenever there is a change and it supports the following operating systems:

* Linux via [inotify](https://github.com/rvoicilas/inotify-tools/wiki) (installation required)
* Windows via [inotify-win](https://github.com/thekid/inotify-win) (no installation required)
* Mac OS X via fsevents (no installation required)
* FreeBSD/OpenBSD/~BSD via [inotify](https://github.com/rvoicilas/inotify-tools/wiki) (installation required)

There is also a `:fs_poll` backend that polls the filesystem and is available on all Operating Systems in case you don't want to install any dependency. You can configure the `:backend` in your `config/config.exs`:

```elixir
config :phoenix_live_reload,
  backend: :fs_poll
```

By default the entire application directory is watched by the backend. However, with some environments and backends, this may be inefficient, resulting in slow response times to file modifications. To account for this, it's also possible to explicitly declare a list of directories for the backend to watch, and additional options for the backend:

```elixir
config :phoenix_live_reload,
  dirs: [
    "priv/static",
    "priv/gettext",
    "lib/example_web/views",
    "lib/example_web/templates",
  ],
  backend: :fs_poll,
  backend_opts: [
    interval: 500
  ]
```


## Skipping remote CSS reload

All stylesheets are reloaded without a page refresh anytime a style is detected as having changed. In certain cases such as serving stylesheets from a remote host, you may wish to prevent unnecessary reload of these stylesheets during development. For this, you can include a `data-no-reload` attribute on the link tag, ie:

    <link rel="stylesheet" href="http://example.com/style.css" data-no-reload>

## Differences between [Phoenix.CodeReloader](https://hexdocs.pm/phoenix/Phoenix.CodeReloader.html#content)

[Phoenix.CodeReloader](https://hexdocs.pm/phoenix/Phoenix.CodeReloader.html#content) recompiles code in the lib directory. This means that if you change anything in the lib directory (such as a context) then the Elixir code will be reloaded and used on your next request.

In contrast, this project adds a plug which injects some JavaScript into your page with a WebSocket connection to the server. When you make a change to anything in your config for live\_reload (JavaScript, stylesheets, templates and views by default) then the page will be reloaded in response to a message sent via the WebSocket. If the change was to an Elixir file then it will be recompiled and served when the page is reloaded. If it is JavaScript or CSS, then only assets are reloaded, without triggering a full page load.

## License

[Same license as Phoenix](https://github.com/phoenixframework/phoenix/blob/master/LICENSE.md).
