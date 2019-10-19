defmodule Bench do
  def erl_in_out(n) do
    queue = :queue.new()

    queue =
      Enum.reduce(1..n, queue, fn x, acc ->
        :queue.in(x, acc)
      end)

    {[], []} =
      Enum.reduce(1..n, queue, fn x, acc ->
        {{:value, ^x}, queue} = :queue.out(acc)
        queue
      end)
  end

  def ex_push_pop(n) do
    queue = FiFo.new()

    queue =
      Enum.reduce(1..n, queue, fn x, acc ->
        FiFo.push(acc, x)
      end)

    %FiFo{} =
      Enum.reduce(1..n, queue, fn x, acc ->
        {{:ok, ^x}, queue} = FiFo.pop(acc)
        queue
      end)
  end

  def run do
    Benchee.run(
      %{
        ":queue" => &erl_in_out/1,
        "FiFo" => &ex_push_pop/1
      },
      inputs: %{"short" => 10, "long" => 10_000},
      time: 10,
      print: [fast_warning: false],
      formatters: [Benchee.Formatters.Console]
    )
  end
end

Bench.run()
