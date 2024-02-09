defmodule TestMetricsHandler do
  def some_function({:ok, result}, %{test_pid: pid} = vars) do
    send(pid, {:ok_handler, result, vars: vars})
  end

  def some_function({:error, err}, %{test_pid: pid} = vars) do
    send(pid, {:error_handler, err, vars: vars})
  end

  def some_function({:rescued, err}, %{test_pid: pid} = vars) do
    send(pid, {:rescued_handler, err, vars: vars})
  end
end

defmodule MetricDecoratorTestModule do
  use MetricDecorator

  @decorate metric(TestMetricsHandler)
  def some_function(_test_pid, "AAPL" = sym) do
    _foo = "bar"
    {:ok, sym}
  end

  def some_function(_test_pid, "error" = _sym) do
    {:error, "an error"}
  end

  def some_function(_test_pid, %{sym: sym}) do
    {:ok, sym}
  end

  @decorate rescued_metric(TestMetricsHandler)
  def some_function(_test_pid, "RAISE" = _sym) do
    raise "RAISE"
  end

  @decorate metric(:skip)
  def some_function(_test_pid, sym) do
    {:ok, sym}
  end

  def another_function(_test_pid, sym) do
    {:ok, sym}
  end
end

defmodule Belay.Utils.MetricDecoratorTest do
  use ExUnit.Case

  test "when pattern matched to ok handler, get result from that handler" do
    assert {:ok, "AAPL"} == MetricDecoratorTestModule.some_function(self(), "AAPL")

    assert_receive {:ok_handler, "AAPL", vars: %{sym: "AAPL", foo: "bar"}}
  end

  test "when pattern matched to :error handler, get result from that handler" do
    assert {:error, "an error"} = MetricDecoratorTestModule.some_function(self(), "error")

    assert_receive {:error_handler, "an error", vars: %{sym: "error"}}
  end

  test "when params are a map, sends pattern-match keys to handler function" do
    assert {:ok, "AAPL"} == MetricDecoratorTestModule.some_function(self(), %{sym: "AAPL"})

    assert_receive {:ok_handler, "AAPL", vars: %{sym: "AAPL"}}
  end

  test "when wrapped function raises, handler is called and re-raised" do
    assert_raise RuntimeError, fn ->
      MetricDecoratorTestModule.some_function(self(), "RAISE")
    end

    assert_receive {:rescued_handler, %RuntimeError{message: "RAISE"}, vars: %{sym: "RAISE"}}
  end

  test "when wrapped function is `:skip`ed, handler is NOT called" do
    assert {:ok, "skip"} == MetricDecoratorTestModule.some_function(self(), "skip")

    refute_receive _
  end

  test "when not decorated, no handler is called" do
    assert {:ok, "AAPL"} == MetricDecoratorTestModule.another_function(self(), "AAPL")

    refute_receive _
  end
end
