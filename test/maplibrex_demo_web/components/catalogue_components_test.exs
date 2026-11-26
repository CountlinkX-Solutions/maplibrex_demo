defmodule MaplibrexDemoWeb.CatalogueComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.CatalogueComponents

  defp lines(n), do: Enum.map_join(1..n, "\n", &"line #{&1}")

  defp render_block(assigns) do
    (&CatalogueComponents.code_block/1)
    |> render_component(assigns)
    |> LazyHTML.from_fragment()
  end

  defp count(document, selector), do: document |> LazyHTML.query(selector) |> Enum.count()

  describe "code_block/1 with collapse" do
    test "caps a long source under a fade and offers to show all of it" do
      block = render_block(id: "long", code: lines(60), collapse: true)

      assert count(block, "#long[data-collapsible]") == 1
      assert count(block, "#long-fade") == 1

      assert count(
               block,
               ~s(button#long-toggle[aria-expanded="false"][aria-controls="long-source"])
             ) == 1
    end

    test "keeps the whole source in the block, so the copy button copies all of it" do
      block = render_block(id: "long", code: lines(60), collapse: true)

      assert block |> LazyHTML.query("#long-source #long-code") |> LazyHTML.text() =~ "line 60"
      assert count(block, ~s(#long button[data-copy-target="long-code"])) == 1
    end

    test "shows a short source whole, without the control" do
      block = render_block(id: "short", code: lines(8), collapse: true)

      assert count(block, "#short-code") == 1
      assert count(block, "#short[data-collapsible]") == 0
      assert count(block, "#short-toggle") == 0
      assert count(block, "#short-fade") == 0
    end
  end

  test "code_block/1 shows a long source whole unless asked to collapse it" do
    block = render_block(id: "whole", code: lines(60))

    assert count(block, "#whole[data-collapsible]") == 0
    assert count(block, "#whole-toggle") == 0
  end
end
