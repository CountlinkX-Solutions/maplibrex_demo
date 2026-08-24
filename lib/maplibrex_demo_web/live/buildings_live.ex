defmodule MaplibrexDemoWeb.BuildingsLive do
  @moduledoc """
  Extruded 3D buildings driven by a `fill-extrusion` layer.

  Height, opacity and the colour expression all come from assigns, so every
  control is an ordinary LiveView event — no client-side state to keep in sync.
  """
  use MaplibrexDemoWeb, :live_view
  on_mount {MaplibrexDemoWeb.LocaleHook, :set_locale}

  import MaplibreX.Components

  @center [-74.006, 40.7128]
  @zoom 14

  @color_schemes [
    %{id: "height", label_key: :by_height},
    %{id: "uniform", label_key: :uniform_blue},
    %{id: "type", label_key: :by_type}
  ]

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:center, @center)
      |> assign(:zoom, @zoom)
      |> assign(:current_center, @center)
      |> assign(:current_zoom, @zoom)
      |> assign(:height_exaggeration, 1.0)
      |> assign(:opacity, 0.8)
      |> assign(:color_scheme, "height")
      |> assign(:color_schemes, @color_schemes)
      |> assign(:buildings_data, generate_buildings_data())

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.demo_page
      path={~p"/buildings"}
      locale={@locale}
      title={gettext("3D Buildings")}
      subtitle={gettext("Extruded NYC building geometry with real-time height and color controls")}
    >
      <:map>
        <.map
          id="buildings-map"
          center={@center}
          zoom={@zoom}
          pitch={60}
          bearing={-17.6}
          style="https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json"
          class="absolute inset-0 h-full w-full"
        />

        <.navigation_control id="nav-control" map_id="buildings-map" position="top-left" />

        <.geojson_layer
          id="buildings-3d"
          map_id="buildings-map"
          data={@buildings_data}
          type="fill-extrusion"
          paint={extrusion_paint(@color_scheme, @height_exaggeration, @opacity)}
        />
      </:map>

      <:panel>
        <.panel_section label={gettext("Color Scheme")} class="space-y-1.5">
          <.option_button
            :for={scheme <- @color_schemes}
            active={@color_scheme == scheme.id}
            phx-click="set_color_scheme"
            phx-value-id={scheme.id}
          >
            {scheme_label(scheme.label_key)}
          </.option_button>
        </.panel_section>

        <.panel_section label={gettext("Height Exaggeration")}>
          <.slider
            label={gettext("Vertical scale")}
            name="value"
            value={@height_exaggeration}
            min="0.5"
            max="3.0"
            step="0.1"
            on_change="update_height"
            display={"#{Float.round(@height_exaggeration * 1.0, 1)}x"}
          />
          <.slider_bounds min="0.5x" max="3.0x" />
        </.panel_section>

        <.panel_section label={gettext("Opacity")}>
          <.slider
            label={gettext("Layer opacity")}
            name="value"
            value={@opacity}
            min="0.3"
            max="1.0"
            step="0.05"
            on_change="update_opacity"
            display={"#{trunc(@opacity * 100)}%"}
          />
          <.slider_bounds min="30%" max="100%" />
        </.panel_section>
      </:panel>

      <:telemetry>
        <.stat first label={gettext("Location")} value={format_center(@current_center)} />
        <.stat label={gettext("Zoom")} value={Float.round(@current_zoom * 1.0, 1)} />
        <.stat label={gettext("Height")} value={"#{Float.round(@height_exaggeration * 1.0, 1)}x"} />
        <.stat label={gettext("Opacity")} value={"#{trunc(@opacity * 100)}%"} />
      </:telemetry>
    </.demo_page>
    """
  end

  @impl true
  def handle_event("set_color_scheme", %{"id" => scheme}, socket) do
    {:noreply, assign(socket, :color_scheme, scheme)}
  end

  def handle_event("update_height", %{"value" => value}, socket) do
    {:noreply, assign(socket, :height_exaggeration, parse_float(value, 1.0))}
  end

  def handle_event("update_opacity", %{"value" => value}, socket) do
    {:noreply, assign(socket, :opacity, parse_float(value, 0.8))}
  end

  def handle_event("map:moved", %{"center" => center, "zoom" => zoom}, socket) do
    {:noreply, socket |> assign(:current_center, center) |> assign(:current_zoom, zoom)}
  end

  def handle_event("map:" <> _, _params, socket), do: {:noreply, socket}
  def handle_event("layer:" <> _, _params, socket), do: {:noreply, socket}

  defp scheme_label(:by_height), do: gettext("By Height")
  defp scheme_label(:uniform_blue), do: gettext("Uniform Blue")
  defp scheme_label(:by_type), do: gettext("By Type")

  defp extrusion_paint(color_scheme, height_exaggeration, opacity) do
    %{
      "fill-extrusion-color" => color_expression(color_scheme),
      "fill-extrusion-height" => ["*", ["get", "height"], height_exaggeration],
      "fill-extrusion-base" => ["get", "base_height"],
      "fill-extrusion-opacity" => opacity,
      "fill-extrusion-vertical-gradient" => true
    }
  end

  defp color_expression("height") do
    ["interpolate", ["linear"], ["get", "height"], 0, "#fbb03b", 50, "#223b53", 150, "#e55e5e"]
  end

  defp color_expression("type") do
    [
      "match",
      ["get", "type"],
      "residential",
      "#fbb03b",
      "commercial",
      "#223b53",
      "office",
      "#e55e5e",
      "#888888"
    ]
  end

  defp color_expression(_uniform), do: "#4a90e2"

  defp format_center([lng, lat]) do
    "#{Float.round(lat * 1.0, 2)}, #{Float.round(lng * 1.0, 2)}"
  end

  defp parse_float(value, fallback) do
    case Float.parse(value) do
      {parsed, _} -> parsed
      :error -> fallback
    end
  end

  # A 15x15 grid of blocks standing in for Manhattan.
  defp generate_buildings_data do
    [center_lng, center_lat] = @center
    building_types = ["residential", "commercial", "office"]

    features =
      for x <- 0..14, y <- 0..14 do
        lng = center_lng + (x - 7) * 0.002
        lat = center_lat + (y - 7) * 0.002

        width = 0.0008 + :rand.uniform() * 0.0004
        depth = 0.0008 + :rand.uniform() * 0.0004

        %{
          "type" => "Feature",
          "geometry" => %{
            "type" => "Polygon",
            "coordinates" => [
              [
                [lng - width / 2, lat - depth / 2],
                [lng + width / 2, lat - depth / 2],
                [lng + width / 2, lat + depth / 2],
                [lng - width / 2, lat + depth / 2],
                [lng - width / 2, lat - depth / 2]
              ]
            ]
          },
          "properties" => %{
            "height" => 20 + :rand.uniform() * 130,
            "base_height" => if(:rand.uniform() < 0.1, do: 5, else: 0),
            "type" => Enum.random(building_types)
          }
        }
      end

    %{"type" => "FeatureCollection", "features" => features}
  end
end
