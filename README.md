# FiFo
[![Hex.pm: version](https://img.shields.io/hexpm/v/fi_fo.svg?style=flat-square)](https://hex.pm/packages/fi_fo)
[![GitHub: CI status](https://img.shields.io/github/actions/workflow/status/hrzndhrn/fi_fo/ci.yml?branch=main&style=flat-square)](https://github.com/hrzndhrn/fi_fo/actions)
[![Coveralls: coverage](https://img.shields.io/coveralls/github/hrzndhrn/fi_fo?style=flat-square)](https://coveralls.io/github/hrzndhrn/fi_fo)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://github.com/hrzndhrn/fi_fo/blob/main/LICENSE.md)

This module provides (double-ended) FIFO queues in an efficient manner.

`FiFo` is just a rewrite of the [Erlang] module [queue] in an Elixir way.

## Installation

First, add `fi_fo` to your `mix.exs` dependencies:

```elixir
def deps do
  [{:fi_fo, "~> 0.2"}]
end
```

Then, update your dependencies:

```Shell
$ mix deps.get
```

Documentation can be found at [HexDocs].

## Usage

Construct, write, and read: `FiFo.new/0`, `FiFo.put/2`, and `FiFo.get/1`:
```elixir
iex(1)> queue = FiFo.new()
{[], []}
iex(2)> queue = FiFo.put(queue, 1)
{[1], []}
iex(3)> queue = FiFo.push(queue, 2)
{[2], [1]}
iex(4)> {1, queue} = FiFo.get(queue)
{1, {[2], []}}
iex(5)> {2, queue} = FiFo.get(queue)
{2, {[], []}}
iex(6)> FiFo.get(queue)
{nil, {[], []}}
iex(7)> FiFo.get(queue, :empty)
{:empty, {[], []}}
```
Create a queue from other data structures: `FiFo.new/1`
```elixir
iex(7)> FiFo.new([1, 2, 3, 4])
{[4, 3], [1, 2]}
iex(8)> FiFo.new(1..10)
{[10, 9, 8, 7, 6], [1, 2, 3, 4, 5]}
```
Convert a queue to a list: `FiFo.to_list/1`
```elixir
iex(9)> FiFo.new([1..3]) |> FiFo.to_list()
[1, 2, 3]
```
Take and drop elements: `FiFo.drop/2` and `FiFo.take/2`
```elixir
iex(10)> FiFo.new(1..10)
{[10, 9, 8, 7, 6], [1, 2, 3, 4, 5]}
iex(11)> FiFo.drop(queue, 3)
{[10, 9, 8, 7, 6], [4, 5]}
iex(12)> FiFo.drop(queue, -6)
{[4, 3], [1, 2]}
iex(13)> FiFo.take(queue, 3)
{[1, 2, 3], {[10, 9, 8, 7, 6], [4, 5]}}
iex(12)> FiFo.take(queue, -6)
{[10, 9, 8, 7, 6, 5], {[4, 3], [1, 2]}}
```

[Erlang]: https://www.erlang.org/
[queue]: http://erlang.org/doc/man/queue.html
[Enumerable]: https://hexdocs.pm/elixir/Enumerable.html
[Collectable]: https://hexdocs.pm/elixir/Collectable.html
[Inspect]: https://hexdocs.pm/elixir/Inspect.html
[HexDocs]: https://hexdocs.pm/fi_fo/api-reference.html
