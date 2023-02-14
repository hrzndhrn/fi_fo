defmodule Bench.GetBench do
  use BencheeDsl.Benchmark

  inputs(%{
    "short" => FiFo.new(1..10),
    "long" => FiFo.new(1..100_000)
  })

  job ":queue.out", queue do
    n = FiFo.size(queue)

    Enum.reduce(1..n, queue, fn _, queue ->
      {_value, queue} = :queue.out(queue)
      queue
    end)
  end

  job "FiFo.get", queue do
    n = FiFo.size(queue)

    Enum.reduce(1..n, queue, fn _, queue ->
      {_value, queue} = FiFo.get(queue)
      queue
    end)
  end
end
