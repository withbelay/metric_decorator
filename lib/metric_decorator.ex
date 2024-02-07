defmodule MetricDecorator do
  use Decorator.Define, metric: 1, rescued_metric: 1

  # @decorate applies the decorator function to all following functions with the same name and arity w/i the module
  # This allows caller to avoid invoking the telemetry handler for the following name/arity combinations
  def metric(:skip, body, _context) do
    quote do
      unquote(body)
    end
  end

  def metric(handler, body, context) do
    target = context.name

    quote do
      result = unquote(body)

      params =
        Kernel.binding()
        |> Enum.into(%{}, fn {k, v} -> {MetricDecorator.remove_underscore(k), v} end)

      Kernel.apply(unquote(handler), unquote(target), [result, params])

      result
    end
  end

  # Setting up a rescue handler is expensive.  Only do it when needed.
  def rescued_metric(:skip, body, _context) do
    quote do
      unquote(body)
    end
  end

  def rescued_metric(handler, body, context) do
    target = context.name

    quote do
      params =
        Kernel.binding()
        |> Enum.into(%{}, fn {k, v} -> {MetricDecorator.remove_underscore(k), v} end)

      try do
        result = unquote(body)

        Kernel.apply(unquote(handler), unquote(target), [result, params])

        result
      rescue
        e ->
          Kernel.apply(unquote(handler), unquote(target), [{:rescued, e}, params])

          reraise e, __STACKTRACE__
      end
    end
  end

  # Allow functions to have underscores in their parameter names, but remove them when we call the handler
  # Needed to pass along parameter values that are not needed in the called function or pattern-matched
  def remove_underscore(name) when is_atom(name), do: name |> Atom.to_string() |> remove_underscore()
  def remove_underscore("_" <> name), do: String.to_existing_atom(name)
  def remove_underscore(name), do: String.to_existing_atom(name)
end
