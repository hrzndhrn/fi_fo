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
  [{:fi_fo, "~> 0.1"}]
end
```

Then, update your dependencies:

```Shell
$ mix deps.get
```

Documentation can be found at [HexDocs](fi_fo).

## Usage

Construct, write, and read: `new/0`, `push/2`, and `pop/1`:
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
A queue from other data structures: `from_list/1`, `from_range/1`, and
`from_erlange_queue`:
```elixir
iex(7)> FiFo.from_list([1, 2, 3, 4])
#FiFo<[1, 2, 3, 4]>
iex(8)> FiFo.from_range(1..10)
#FiFo<[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]>
iex(9)> FiFo.from_erlang_queue({[3, 2], [1]})
#FiFo<[1, 2, 3]>
```

[erl]: https://www.erlang.org/
[erl_queue]: http://erlang.org/doc/man/queue.html
[enumerable]: https://hexdocs.pm/elixir/Enumerable.html
[collectable]: https://hexdocs.pm/elixir/Collectable.html
[inspect]: https://hexdocs.pm/elixir/Inspect.html
[fi_fo]: https://hexdocs.pm/fi_fo/api-reference.html
