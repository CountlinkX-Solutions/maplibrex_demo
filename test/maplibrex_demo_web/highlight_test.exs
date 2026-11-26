defmodule MaplibrexDemoWeb.HighlightTest do
  use ExUnit.Case, async: true

  alias MaplibrexDemoWeb.Highlight

  @elixir ~S'''
  defmodule MyAppWeb.MapLive do
    use MyAppWeb, :live_view
    import MaplibreX.Components

    # Moves follow the map.
    def handle_event("map:moved", %{"center" => center, "zoom" => zoom}, socket) do
      {:noreply, assign(socket, center: center, zoom: zoom * 1.5)}
    end

    defp render_count(%{count: n}) when n > 0, do: ~s(#{n} "quoted")

    def render(assigns) do
      ~H"""
      <.map id="map" center={@center} />
      """
    end
  end
  '''

  @heex ~S'''
  <%!-- A map driven by assigns --%>
  <.map id="map-example" center={@center} zoom={@zoom} class="h-preview w-full" />
  <button :for={place <- @places} phx-click="go" phx-value-place={place.id} disabled>
    {place.name} costs {%{"a" => "}"}["a"]}
  </button>
  <p :if={@error} role="alert"><%= @error %></p>
  '''

  defp classes(source, language) do
    source
    |> Highlight.tokens(language)
    |> Enum.reject(fn {class, _text} -> is_nil(class) end)
  end

  describe "tokens/2" do
    test "never loses or reorders a character" do
      for {source, language} <- [
            {@elixir, :elixir},
            {@heex, :heex},
            {"import {x} from \"y\" // note\nlet a = 1", :javascript},
            {"@import \"a.css\"; /* c */ .x { color: red }", :css},
            {"npm install --prefix assets maplibre-gl # peer", :shell},
            {"plain <text> {braces", :plain},
            {"<.map id=\"m\" broken={@x", :heex},
            {"\"unterminated", :elixir}
          ] do
        assert source |> Highlight.tokens(language) |> Enum.map_join(&elem(&1, 1)) == source
      end
    end

    test "classifies Elixir" do
      tokens = classes(@elixir, :elixir)

      assert {:keyword, "defmodule"} in tokens
      assert {:module, "MyAppWeb.MapLive"} in tokens
      assert {:atom, ":live_view"} in tokens
      assert {:atom, "noreply:"} not in tokens
      assert {:atom, "center:"} in tokens
      assert {:string, ~s("map:moved")} in tokens
      assert {:comment, "# Moves follow the map."} in tokens
      assert {:function, "handle_event"} in tokens
      assert {:number, "1.5"} in tokens
      assert {:keyword, "when"} in tokens
    end

    test "highlights the HEEx inside a ~H sigil as HEEx" do
      tokens = classes(@elixir, :elixir)

      assert {:tag, "<.map"} in tokens
      assert {:attr_name, "center"} in tokens
      assert {:attribute, "@center"} in tokens
    end

    test "classifies HEEx tags, attributes and expressions" do
      tokens = classes(@heex, :heex)

      assert {:comment, "<%!-- A map driven by assigns --%>"} in tokens
      assert {:tag, "<.map"} in tokens
      assert {:attr_name, "zoom"} in tokens
      assert {:string, ~s("h-preview w-full")} in tokens
      assert {:attribute, "@zoom"} in tokens
      assert {:attr_name, ":for"} in tokens
      assert {:tag, "</button>"} in tokens
      assert {:tag, "/>"} in tokens
    end

    test "keeps a HEEx expression with braces inside strings in one piece" do
      tokens = Highlight.tokens(~S({%{"a" => "}"}["a"]} tail), :heex)

      assert {:string, ~s("}")} in tokens
      assert List.last(tokens) == {nil, " tail"}
    end
  end

  describe "to_html/2" do
    test "escapes the source and wraps classified tokens" do
      html = Highlight.to_html(~S(<.map id="a&b" />), :heex)

      assert html =~ ~s(<span class="tok-tag">&lt;.map</span>)
      assert html =~ ~s(<span class="tok-string">&quot;a&amp;b&quot;</span>)
      refute html =~ "<.map"
    end
  end
end
