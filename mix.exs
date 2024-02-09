defmodule TypedStructCtor.MixProject do
  use Mix.Project

  def project do
    [
      app: :metric_decorator,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "MetricDecorator"
    ]
  end

  def application do
    []
  end

  defp description() do
    """
    A `@decorate` macro to invoke :telemetry events for the wrapped function
    """
  end

  defp package() do
    []
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false},
      {:decorator, github: "/withbelay/decorator", tag: "v1.4.1"},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false}
    ]
  end
end
