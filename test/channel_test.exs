defmodule Phoenix.LiveReload.ChannelTest do
  use ExUnit.Case, async: true
  alias Phoenix.LiveReload.Channel

  @patterns [
    ~r{priv/static/.*(js|css|png|jpeg|jpg|gif)$},
    ~r{web/views/.*(ex)$},
    ~r{web/templates/.*(eex)$}
  ]

  test "matches_any_pattern? returns true if any @patterns match changed path" do
    assert Channel.matches_any_pattern?("web/templates/user/show.html.eex", @patterns)
    assert Channel.matches_any_pattern?("a/b/c/web/views/user_view.ex", @patterns)
    assert Channel.matches_any_pattern?("priv/static/js/app.js", @patterns)
    assert Channel.matches_any_pattern?("priv/static/js/app.css", @patterns)
    assert Channel.matches_any_pattern?("priv/static/js/app.png", @patterns)
  end

  test "matches_any_pattern? returns false for _build directories" do
    refute Channel.matches_any_pattern?("_build/app/web/templates/user/show.html.eex", @patterns)
    refute Channel.matches_any_pattern?("a/b/c/_build/app/web/views/user_view.ex", @patterns)
    refute Channel.matches_any_pattern?("_build/app/priv/static/js/app.js", @patterns)
    refute Channel.matches_any_pattern?("_build/app/priv/static/js/app.css", @patterns)
    refute Channel.matches_any_pattern?("_build/app/priv/static/js/app.png", @patterns)
  end
end
