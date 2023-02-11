defmodule Bench.PushPopBench do
  use BencheeDsl.Benchmark

  inputs %{
    "shourt" => 10,
    "long" => 100_000
  }

  job ":queue in/out", n do
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

  job "FiFo push/pop", n do
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
end
