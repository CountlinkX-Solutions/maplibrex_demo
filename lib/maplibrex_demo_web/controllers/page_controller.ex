defmodule MaplibrexDemoWeb.PageController do
  use MaplibrexDemoWeb, :controller

  plug :put_layout, html: false

  # The demo index. Kept here rather than in the template so the catalogue is
  # data — one place to add a demo, and the template stays presentational.
  @demos [
    %{
      path: "/map",
      label_key: :core,
      title_key: :interactive_map,
      icon:
        "M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7"
    },
    %{
      path: "/tiles",
      label_key: :server,
      title_key: :vector_tiles,
      icon:
        "M5 12h14M5 12a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v4a2 2 0 01-2 2M5 12a2 2 0 00-2 2v4a2 2 0 002 2h14a2 2 0 002-2v-4a2 2 0 00-2-2m-2-4h.01M17 16h.01"
    },
    %{
      path: "/ogc",
      label_key: :standards,
      title_key: :ogc_features,
      icon:
        "M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
    },
    %{
      path: "/deckgl",
      label_key: :visualization,
      title_key: :deckgl_layers,
      icon: "M7 12l3-3 3 3 4-4M8 21l4-4 4 4M3 4h18M4 4h16v12a1 1 0 01-1 1H5a1 1 0 01-1-1V4z"
    },
    %{
      path: "/terrain",
      label_key: :visualization,
      title_key: :terrain_3d,
      icon:
        "M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
    },
    %{
      path: "/heatmap",
      label_key: :visualization,
      title_key: :heatmap,
      icon: "M13 10V3L4 14h7v7l9-11h-7z"
    },
    %{
      path: "/buildings",
      label_key: :visualization,
      title_key: :buildings_3d,
      icon:
        "M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-2 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
    },
    %{
      path: "/markers",
      label_key: :interactive,
      title_key: :markers_filters,
      icon:
        "M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z M15 11a3 3 0 11-6 0 3 3 0 016 0z"
    },
    %{
      path: "/particles",
      label_key: :advanced,
      title_key: :webgl_particles,
      icon:
        "M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z"
    }
  ]

  def home(conn, _params) do
    conn
    |> assign(:demos, Enum.map(@demos, &translate_demo/1))
    |> assign(:stats, stats())
    |> render(:home)
  end

  defp translate_demo(demo) do
    demo
    |> Map.put(:label, label(demo.label_key))
    |> Map.put(:title, title(demo.title_key))
    |> Map.put(:desc, description(demo.title_key))
  end

  defp stats do
    [
      {gettext("Components"), "32"},
      {gettext("Demos"), "9"},
      {"LiveView", "1.0"},
      {"MapLibre GL", "5.x"}
    ]
  end

  defp label(:core), do: gettext("Core")
  defp label(:server), do: gettext("Server")
  defp label(:standards), do: gettext("Standards")
  defp label(:visualization), do: gettext("Visualization")
  defp label(:interactive), do: gettext("Interactive")
  defp label(:advanced), do: gettext("Advanced")

  defp title(:interactive_map), do: gettext("Interactive Map")
  defp title(:vector_tiles), do: gettext("Vector Tiles")
  defp title(:ogc_features), do: gettext("OGC Features")
  defp title(:deckgl_layers), do: gettext("Deck.GL Layers")
  defp title(:terrain_3d), do: gettext("3D Terrain")
  defp title(:heatmap), do: gettext("Heatmap")
  defp title(:buildings_3d), do: gettext("3D Buildings")
  defp title(:markers_filters), do: gettext("Markers & Filters")
  defp title(:webgl_particles), do: gettext("WebGL Particles")

  defp description(:interactive_map),
    do: gettext("Draggable markers, GeoJSON layers, real-time style switching")

  defp description(:vector_tiles),
    do: gettext("Vector tile rendering from a self-hosted tile server, with a public fallback")

  defp description(:ogc_features),
    do: gettext("OGC API Features conformance against real geographic data")

  defp description(:deckgl_layers),
    do: gettext("3D ArcLayer, HexagonLayer density and ScatterplotLayer with integrated deck.gl")

  defp description(:terrain_3d),
    do: gettext("Elevation rendering with DEM sources, hillshade and extruded terrain up to 3x")

  defp description(:heatmap),
    do: gettext("500 seismic points on a heatmap with adjustable radius, intensity and opacity")

  defp description(:buildings_3d),
    do: gettext("Extruded New York buildings with configurable color schemes and height")

  defp description(:markers_filters),
    do: gettext("Category markers with real-time filtering and drag to update coordinates")

  defp description(:webgl_particles),
    do: gettext("System of 1,000 animated particles with custom GLSL shaders (vertex + fragment)")
end
