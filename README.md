# FiFo
[![Hex.pm](https://img.shields.io/hexpm/v/fi_fo.svg)](https://hex.pm/packages/fi_fo)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Build Status](https://travis-ci.org/hrzndhrn/fi_fo.svg?branch=master)](https://travis-ci.org/hrzndhrn/fi_fo)
[![Coverage Status](https://coveralls.io/repos/github/hrzndhrn/fi_fo/badge.svg?branch=master)](https://coveralls.io/github/hrzndhrn/fi_fo?branch=master)
[![codebeat badge](https://codebeat.co/badges/c6fb98cb-2044-48b8-9614-100940c62016)](https://codebeat.co/projects/github-com-hrzndhrn-fi_fo-master)

This module provides (double-ended) FIFO queues in an efficient manner.

`FiFo` is just a rewrite of the [Erlang] module [queue] in an Elixir way. The
module includes implementations of the protocols [Enumerabale],
[Collectable], and [Inspect].

## Installation

First, add `fi_fo` to your `mix.exs` dependencies:

```elixir
def deps do
  [{:fi_fo, "~> 0.1"}]
end
```

Then, update your dependencies:

```Shell
$ mix deps.get
```

Documentation can be found at [HexDocs].

## Usage

Construct, write, and read: `FiFo.new/0`, `FiFo.push/2`, and `FiFo.pop/1`:
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
Create a queue from other data structures: `FiFo.from_list/1`,
`FiFo.from_range/1`, and `FiFo.from_erlange_queue`:
```elixir
iex(7)> FiFo.from_list([1, 2, 3, 4])
#FiFo<[1, 2, 3, 4]>
iex(8)> FiFo.from_range(1..10)
#FiFo<[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]>
iex(9)> FiFo.from_erlang_queue({[3, 2], [1]})
#FiFo<[1, 2, 3]>
```
Convert a queue to other data structures: `FiFo.to_list/1` and
`FiFo.to_erlang_queue/1`:
```elixir
iex(10)> queue = FiFo.from_list([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
#FiFo<[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]>
iex(11)> FiFo.to_list(queue)
[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
iex(12)> FiFo.to_erlang_queue(queue)
{[10, 9, 8, 7], [1, 2, 3, 4, 5, 6]}
```
Take and drop elements: `FiFo.drop/2`, `FiFo.take/2`, `Enum.drop/1`, and
`Enum.take/2`:
```elixir
iex(13)> FiFo.drop(queue, 3)
#FiFo<[4, 5, 6, 7, 8, 9, 10]>
iex(14)> FiFo.take(queue, 3)
{[1, 2, 3], #FiFo<[4, 5, 6, 7, 8, 9, 10]>}
iex(15)> Enum.drop(queue, 3)
[4, 5, 6, 7, 8, 9, 10]
iex(16)> Enum.take(queue, 3)
[1, 2, 3]
```

[Erlang]: https://www.erlang.org/
[queue]: http://erlang.org/doc/man/queue.html
[Enumerable]: https://hexdocs.pm/elixir/Enumerable.html
[Collectable]: https://hexdocs.pm/elixir/Collectable.html
[Inspect]: https://hexdocs.pm/elixir/Inspect.html
[HexDocs]: https://hexdocs.pm/fi_fo/api-reference.html
