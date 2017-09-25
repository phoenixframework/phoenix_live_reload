A project for live-reload functionality for [Phoenix](http://github.com/phoenixframework/phoenix) during development.

## Usage

You can use `phoenix_live_reload` in your projects by adding it to your `mix.exs` dependencies:

```elixir
def deps do
  [{:phoenix_live_reload, "~> 1.1"}]
end
```

## Backends

This project uses [`FileSystem`](https://github.com/falood/file_system) as a dependency to watch your filesystem whenever there is a change and it supports the following operating systems:

* Linux via [inotify](https://github.com/rvoicilas/inotify-tools/wiki) (installation required)
* Windows via [inotify-win](https://github.com/thekid/inotify-win) (no installation required)
* Mac OS X via fsevents (no installation required)

## Skipping remote CSS reload

All stylesheets are reloaded without a page refresh anytime a style is detected as having changed. In certain cases such as serving stylesheets from a remote host, you may wish to prevent unnecessary reload of these stylesheets during development. For this, you can include a `data-no-reload` attribute on the link tag, ie:

    <link rel="stylesheet" href="http://example.com/style.css" data-no-reload>

## Differences between [Phoenix.CodeReloader](https://hexdocs.pm/phoenix/Phoenix.CodeReloader.html#content)

[Phoenix.CodeReloader](https://hexdocs.pm/phoenix/Phoenix.CodeReloader.html#content) recompiles code in the lib directory. This means that if you change anything in the lib directory (such as a context) then the Elixir code will be reloaded and used on your next request.

In contrast, this project adds a plug which injects some JavaScript into your page with a WebSocket connection to the server. When you make a change to anything in your config for live\_reload (JavaScript, stylesheets, templates and views by default) then the page will be reloaded in response to a message sent via the WebSocket. If the change was to an Elixir file then it will be recompiled and served when the page is reloaded. If it is JavaScript or CSS, then only assets are reloaded, without triggering a full page load.

## License

[Same license as Phoenix](https://github.com/phoenixframework/phoenix/blob/master/LICENSE.md).
