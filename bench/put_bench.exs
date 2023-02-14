defmodule Bench.PutBench do
  use BencheeDsl.Benchmark

  inputs(%{
    "short" => 10,
    "long" => 100_000
  })

  job ":queue.in", n do
    Enum.reduce(1..n, :queue.new(), fn x, acc ->
      :queue.in(x, acc)
    end)
  end

  job "FiFo.put", n do
    Enum.reduce(1..n, FiFo.new(), fn x, acc ->
      FiFo.put(acc, x)
    end)
  end
end
