defmodule MaplibrexDemoWeb.HeatmapLive do
  @moduledoc """
  A heatmap layer over 500 synthetic seismic events, with radius, intensity and
  opacity driven from LiveView assigns.

  Every slider re-renders the layer's `paint` map; the GeoJSON layer hook diffs
  it and applies only the properties that changed, so dragging a slider does
  not re-add the source.
  """
  use MaplibrexDemoWeb, :live_view
  on_mount {MaplibrexDemoWeb.LocaleHook, :set_locale}

  import MaplibreX.Components

  @point_count 500

  @gradient "linear-gradient(to right, rgba(33,102,172,0), rgb(103,169,207), rgb(209,229,240), rgb(253,219,199), rgb(239,138,98), rgb(178,24,43))"

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:radius, 25)
      |> assign(:intensity, 1.0)
      |> assign(:opacity, 0.8)
      |> assign(:point_count, @point_count)
      |> assign(:gradient, @gradient)
      |> assign(:earthquake_data, generate_earthquake_data())

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.demo_page
      path={~p"/heatmap"}
      locale={@locale}
      title={gettext("Heatmap")}
      subtitle={gettext("500-point earthquake density visualization across the US")}
    >
      <:map>
        <.map
          id="heatmap-map"
          center={[-98.5, 39.8]}
          zoom={3.5}
          pitch={0}
          bearing={0}
          style="https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json"
          class="absolute inset-0 h-full w-full"
        />

        <.navigation_control id="nav-control" map_id="heatmap-map" position="top-left" />

        <.geojson_layer
          id="earthquake-heatmap"
          map_id="heatmap-map"
          data={@earthquake_data}
          type="heatmap"
          paint={heatmap_paint(@radius, @intensity, @opacity)}
        />
      </:map>

      <:panel>
        <.panel_section label={gettext("Radius")}>
          <.slider
            label={gettext("Kernel size")}
            name="value"
            value={@radius}
            min="10"
            max="50"
            step="1"
            on_change="update_radius"
            display={"#{@radius}px"}
          />
          <.slider_bounds min="10px" max="50px" />
        </.panel_section>

        <.panel_section label={gettext("Intensity")}>
          <.slider
            label={gettext("Weight multiplier")}
            name="value"
            value={@intensity}
            min="0.5"
            max="3.0"
            step="0.1"
            on_change="update_intensity"
            display={"#{Float.round(@intensity * 1.0, 1)}x"}
          />
          <.slider_bounds min="0.5x" max="3.0x" />
        </.panel_section>

        <.panel_section label={gettext("Opacity")}>
          <.slider
            label={gettext("Layer opacity")}
            name="value"
            value={@opacity}
            min="0"
            max="1"
            step="0.05"
            on_change="update_opacity"
            display={"#{trunc(@opacity * 100)}%"}
          />
          <.slider_bounds min="0%" max="100%" />
        </.panel_section>

        <.panel_section label={gettext("Gradient")}>
          <.gradient_bar css_gradient={@gradient} low={gettext("Low")} high={gettext("High")} />
        </.panel_section>
      </:panel>

      <:telemetry>
        <.stat first label={gettext("Points")} value={@point_count} />
        <.stat label={gettext("Radius")} value={"#{@radius}px"} />
        <.stat label={gettext("Intensity")} value={"#{Float.round(@intensity * 1.0, 1)}x"} />
        <.stat label={gettext("Opacity")} value={"#{trunc(@opacity * 100)}%"} />
      </:telemetry>
    </.demo_page>
    """
  end

  @impl true
  def handle_event("update_radius", %{"value" => value}, socket) do
    {:noreply, assign(socket, :radius, parse_integer(value, 25))}
  end

  def handle_event("update_intensity", %{"value" => value}, socket) do
    {:noreply, assign(socket, :intensity, parse_float(value, 1.0))}
  end

  def handle_event("update_opacity", %{"value" => value}, socket) do
    {:noreply, assign(socket, :opacity, parse_float(value, 0.8))}
  end

  def handle_event("map:" <> _, _params, socket), do: {:noreply, socket}
  def handle_event("layer:" <> _, _params, socket), do: {:noreply, socket}

  # MapLibre paint properties. Radius and intensity are zoom-interpolated so
  # the heatmap keeps a consistent visual density as you zoom in.
  defp heatmap_paint(radius, intensity, opacity) do
    %{
      "heatmap-weight" => ["interpolate", ["linear"], ["get", "magnitude"], 0, 0, 6, 1],
      "heatmap-intensity" => [
        "interpolate",
        ["linear"],
        ["zoom"],
        0,
        intensity,
        9,
        intensity * 3
      ],
      "heatmap-color" => [
        "interpolate",
        ["linear"],
        ["heatmap-density"],
        0,
        "rgba(33,102,172,0)",
        0.2,
        "rgb(103,169,207)",
        0.4,
        "rgb(209,229,240)",
        0.6,
        "rgb(253,219,199)",
        0.8,
        "rgb(239,138,98)",
        1,
        "rgb(178,24,43)"
      ],
      "heatmap-radius" => ["interpolate", ["linear"], ["zoom"], 0, radius / 4, 9, radius],
      "heatmap-opacity" => opacity
    }
  end

  defp parse_integer(value, fallback) do
    case Integer.parse(value) do
      {parsed, _} -> parsed
      :error -> fallback
    end
  end

  defp parse_float(value, fallback) do
    case Float.parse(value) do
      {parsed, _} -> parsed
      :error -> fallback
    end
  end

  # Synthetic seismic events spread across the continental US.
  defp generate_earthquake_data do
    features =
      for _ <- 1..@point_count do
        %{
          "type" => "Feature",
          "geometry" => %{
            "type" => "Point",
            "coordinates" => [-125.0 + :rand.uniform() * 55.0, 25.0 + :rand.uniform() * 25.0]
          },
          "properties" => %{
            "magnitude" => 2.0 + :rand.uniform() * 4.0,
            "depth" => :rand.uniform() * 100
          }
        }
      end

    %{"type" => "FeatureCollection", "features" => features}
  end
end
