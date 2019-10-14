# FiFo

This module provides (double-ended) FIFO queues in an efficient manner.

`FiFo` is just a rewrite of the [Erlang](erl) module [queue](erl_queue) in an
Elixir way. The module includes implementations of the protocols
[Enumerabale](enumerable), [Collectable](collectable), and [Inspect](inspect).

## Installation

If [available in Hex](https://hex.pm/docs/publish):

First, add Xema to your `mix.exs` dependencies:

```elixir
def deps do
  [{:xema, "~> 0.9"}]
end
```

Then, update your dependencies:

```Shell
$ mix deps.get
```

Documentation can be found at [HexDocs](https://hexdocs.pm/fi_fo/api-reference.html).

## Usage

new, push, and pop
```elixir
iex(1)> queue = FiFo.new()
#FiFo<[]>
iex(2)> queue = FiFo.push(queue, 1)
#FiFo<[1]>
iex(3)> queue = FiFo.push(queue, 2)
#FiFo<[1, 2]>
iex(4)> {{:ok, x}, queue} = FiFo.pop(queue)
{{:ok, 1}, #FiFo<[2]>}
iex(5)> {{:ok, x}, queue} = FiFo.pop(queue)
{{:ok, 2}, #FiFo<[]>}
iex(6)> FiFo.pop(queue)
{:error, #FiFo<[]>}
```

[erl]: https://www.erlang.org/
[erl_queue]: http://erlang.org/doc/man/queue.html
[enumerable]: https://hexdocs.pm/elixir/Enumerable.html
[collectable]: https://hexdocs.pm/elixir/Collectable.html
[inspect]: https://hexdocs.pm/elixir/Inspect.html
