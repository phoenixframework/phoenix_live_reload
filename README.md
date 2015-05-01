A project for live-reload functionality for [Phoenix](http://github.com/phoenixframework/phoenix) during development.

## Usage

You can use `phoenix_live_reload` in your projects by adding it your `mix.exs` dependencies:

```elixir
def deps do
  [{:phoenix_live_reload, "~> 0.3"}]
end
```

## Backends

This project uses [`fs`](https://github.com/synrc/fs) as a dependency to watch your filesystem whenever there is a change and it supports the following operating systems:

* Linux via [inotify](https://github.com/rvoicilas/inotify-tools/wiki) (installation required)
* Windows via [inotify-win](https://github.com/thekid/inotify-win) (no installation required)
* Mac OS X via fsevents (no installation required)

## License

Same license as Phoenix.
