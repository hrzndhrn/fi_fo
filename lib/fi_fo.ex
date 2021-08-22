defmodule FiFo do
  @moduledoc """
  This module provides FIFO queues in an efficient manner.

  `FiFo` is just a rewrite of the [Erlang](http://erlang.org)
  module [queue](http://erlang.org/doc/man/queue.html) in an
  Elixir way. The module includes implementations of the protocols
  `Enumerabale`, `Collectable`, and `Inspect`.
  """

  # All queues generated with functions from this module are wellformed. A
  # malformed queue is a queue with a front-list with more as one element and an
  # empty list for the rear-list or the other way around. This module handles
  # also malformed queues, just slower.

  @compile :inline_list_funcs
  @compile {:inline,
            do_take: 2,
            drop: 3,
            fetch: 1,
            fetch_reverse: 1,
            from_erlang_queue: 1,
            to_front: 1,
            to_rear: 1}

  @type front :: list
  @type rear :: list
  @type element :: term
  @type empty :: %__MODULE__{rear: [], front: []}
  @type t :: %__MODULE__{rear: list, front: list}

  defstruct rear: [], front: []

  @doc """
  Returns an empty queue.

  ## Examples

      iex> FiFo.new()
      #FiFo<[]>
  """
  @spec new :: t
  def new, do: %FiFo{}

  @doc """
  Given a list of `queues`, concatenates the `queues` into a single queue. The
  first queue in the list becomes the front of the queue.

  ## Examples

      iex> FiFo.concat([
      ...>   FiFo.from_range(1..3), FiFo.from_range(4..5), FiFo.from_range(7..9)
      ...> ])
      #FiFo<[1, 2, 3, 4, 5, 7, 8, 9]>
  """
  @spec concat([t]) :: t
  def concat([]), do: %FiFo{}

  def concat([%FiFo{} = queue]), do: queue

  def concat(queues) when is_list(queues) do
    queues
    |> Enum.map(&to_list/1)
    |> Enum.concat()
    |> from_list()
  end

  @doc """
  Concatenates the queue `b` with the queue `a` with queue `a` in front of queue
  `b`.

  ## Examples

      iex> FiFo.concat(FiFo.from_list([1, 2]), FiFo.from_list([3, 4]))
      #FiFo<[1, 2, 3, 4]>
  """
  @spec concat(t, t) :: t
  def concat(%FiFo{} = a, %FiFo{} = b), do: concat([a, b])

  @doc """
  Drops the `amount` of elements from the `queue`.

  If a negative `amount` is given, the `amount` of last values will be dropped.

  ## Examples

      iex> [1, 2, 3] |> FiFo.from_list() |> FiFo.drop(2)
      #FiFo<[3]>

      iex> [1, 2, 3] |> FiFo.from_list() |> FiFo.drop(-2)
      #FiFo<[1]>

      iex> [1, 2, 3] |> FiFo.from_list() |> FiFo.drop(10)
      #FiFo<[]>

      iex> [1, 2, 3] |> FiFo.from_list() |> FiFo.drop(0)
      #FiFo<[1, 2, 3]>
  """
  @spec drop(t, non_neg_integer) :: t
  def drop(queue, 0), do: queue

  def drop(%FiFo{rear: rear, front: front}, amount) when amount > 0 do
    {rear, front} = drop(rear, front, amount)
    %FiFo{rear: rear, front: front}
  end

  def drop(%FiFo{rear: rear, front: front}, amount) when amount < 0 do
    {front, rear} = drop(front, rear, abs(amount))
    %FiFo{rear: rear, front: front}
  end

  defp drop(rear, front, amount) do
    case length(front) - amount do
      0 ->
        to_front(rear)

      diff when diff > 0 ->
        {rear, Enum.drop(front, amount)}

      diff ->
        case length(rear) + diff do
          at when at > 0 ->
            rear |> Enum.take(length(rear) + diff) |> to_front()

          _ ->
            {[], []}
        end
    end
  end

  @doc """
  Determines if the `queue` is empty.

  Returns `true` if `queue` is empty, otherwise `false`.

  ## Examples

      iex> FiFo.empty?(FiFo.new())
      true

      iex> FiFo.empty?(FiFo.from_list([1]))
      false
  """
  @spec empty?(t) :: boolean
  def empty?(queue)

  def empty?(%FiFo{rear: [], front: []}), do: true

  def empty?(%FiFo{}), do: false

  @doc """
  Fetches element at the front of `queue`.

  If `queue` is not empty, then `{:ok, element}` is returned. If `queue` is
  empty `:error` is returned.

  ## Examples

      iex> FiFo.fetch(FiFo.from_list([1, 2]))
      {:ok, 1}

      iex> FiFo.fetch(FiFo.new())
      :error
  """
  @spec fetch(t) :: {:ok, element} | :error
  def fetch(queue)

  # from an empty queue
  def fetch(%FiFo{rear: [], front: []}), do: :error

  # from a queue with one element
  def fetch(%FiFo{rear: [x], front: []}), do: {:ok, x}

  def fetch(%FiFo{rear: [], front: [x]}), do: {:ok, x}

  # from a queue
  def fetch(%FiFo{front: [x | _]}), do: {:ok, x}

  # from a malformed queue
  def fetch(%FiFo{rear: rear}), do: {:ok, :lists.last(rear)}

  @doc """
  Fetches element at the front of `queue`, erroring out if `queue` is empty.

  If `queue` is not empty, then `{:ok, element}` is returned. If `queue` is
  empty a `FiFo.EmptyError` excepetion is raised.

  ## Examples

      iex> FiFo.fetch!(FiFo.from_list([1, 2]))
      1

      iex> FiFo.fetch!(FiFo.new())
      ** (FiFo.EmptyError) empty error
  """
  @spec fetch!(t) :: {:ok, element}
  def fetch!(queue) do
    case fetch(queue) do
      {:ok, x} -> x
      :error -> raise FiFo.EmptyError
    end
  end

  @doc """
  Fetches element at the rear of `queue`.

  If `queue` is not empty, then `{:ok, element}` is returned. If `queue` is
  empty `:error` is returned.

  ## Examples

      iex> FiFo.fetch_reverse(FiFo.from_list([1, 2]))
      {:ok, 2}

      iex> FiFo.fetch_reverse(FiFo.new())
      :error
  """
  @spec fetch_reverse(t) :: {:ok, element} | :error
  def fetch_reverse(queue)

  # from an empty queue
  def fetch_reverse(%FiFo{rear: [], front: []}), do: :error

  # from a queue with one element
  def fetch_reverse(%FiFo{rear: [x], front: []}), do: {:ok, x}

  def fetch_reverse(%FiFo{rear: [], front: [x]}), do: {:ok, x}

  # from a queue
  def fetch_reverse(%FiFo{rear: [x | _]}), do: {:ok, x}

  # from a malformed queue
  def fetch_reverse(%FiFo{front: front}), do: {:ok, :lists.last(front)}

  @doc """
  Fetches element at the rear of `queue`, erroring out if `queue` is empty.

  If `queue` is not empty, then `{:ok, element}` is returned. If `queue` is
  empty a `FiFo.EmptyError` excepetion is raised.

  ## Examples

      iex> FiFo.fetch!(FiFo.from_list([1, 2]))
      1

      iex> FiFo.fetch!(FiFo.new())
      ** (FiFo.EmptyError) empty error
  """
  @spec fetch_reverse!(t) :: {:ok, element} | :error
  def fetch_reverse!(queue) do
    case fetch_reverse(queue) do
      {:ok, x} -> x
      :error -> raise FiFo.EmptyError
    end
  end

  @doc """
  Filters the queue, i.e. returns only those elements for which fun returns
  a truthy value.

  See also reject/2 which discards all elements where the function returns a
  truthy value.

  ## Examples

      iex> FiFo.filter(FiFo.from_list([1, 2, 3, 4]), fn x -> rem(x, 2) == 0 end)
      #FiFo<[2, 4]>
  """
  @spec filter(t, (element -> as_boolean(element))) :: t
  def filter(queue, fun)

  def filter(%FiFo{rear: rear, front: front}, fun) do
    update_queue({Enum.filter(rear, fun), Enum.filter(front, fun)})
  end

  @doc """
  Converts an Erlang queue to a queue.

  ## Examples

      iex> FiFo.from_erlang_queue({[3, 2], [1]})
      #FiFo<[1, 2, 3]>
  """
  @spec from_erlang_queue({rear, front}) :: t
  def from_erlang_queue({rear, front}) do
    %FiFo{rear: rear, front: front}
  end

  @doc """
  Converts a `list` to a queue.

  ## Examples

      iex> FiFo.from_list([1, 2, 3])
      #FiFo<[1, 2, 3]>
  """
  @spec from_list(list) :: t
  def from_list(list) when is_list(list) do
    list |> to_rear() |> from_erlang_queue()
  end

  @doc """
  Converts a range to a `queue`.

  ## Examples

      iex> FiFo.from_range(1..3)
      #FiFo<[1, 2, 3]>
  """
  @spec from_range(Range.t()) :: t
  def from_range(%Range{} = range) do
    range |> Enum.to_list() |> to_rear() |> from_erlang_queue()
  end

  @doc """
  Gets element at the front of `queue`, erroring out if `queue` is empty.

  If `queue` is empty default is returned.

  If `default` is not provided, `nil` is used.

  ## Examples

      iex> FiFo.get(FiFo.from_list([1, 2]))
      1

      iex> FiFo.get(FiFo.new())
      nil

      iex> FiFo.get(FiFo.new(), :empty)
      :empty
  """
  @spec get(t, term) :: element | term | nil
  def get(queue, default \\ nil)

  # from an empty queue
  def get(%FiFo{rear: [], front: []}, default), do: default

  # from a queue with one element
  def get(%FiFo{rear: [x], front: []}, _default), do: x

  def get(%FiFo{rear: [], front: [x]}, _default), do: x

  # from a queue
  def get(%FiFo{front: [x | _]}, _default), do: x

  # from a malformed queue
  def get(%FiFo{rear: rear}, _default), do: :lists.last(rear)

  @doc """
  Gets element at the rear of `queue`, erroring out if `queue` is empty.

  If `queue` is empty default is returned.

  If `default` is not provided, `nil` is used.

  ## Examples

      iex> FiFo.get_reverse(FiFo.from_list([1, 2]))
      2

      iex> FiFo.get_reverse(FiFo.new())
      nil

      iex> FiFo.get_reverse(FiFo.new(), :empty)
      :empty
  """
  @spec get_reverse(t, term) :: element | term | nil
  def get_reverse(queue, default \\ nil)

  # from an empty queue
  def get_reverse(%FiFo{rear: [], front: []}, default), do: default

  # from a queue with one element
  def get_reverse(%FiFo{rear: [x], front: []}, _default), do: x

  def get_reverse(%FiFo{rear: [], front: [x]}, _default), do: x

  # from a queue
  def get_reverse(%FiFo{rear: [x | _]}, _default), do: x

  # from a malformed queue
  def get_reverse(%FiFo{front: front}, _default), do: :lists.last(front)

  @doc """
  Returns a `queue` where each element is the result of invoking fun on each
  corresponding element of `queue`.

  ## Examples

      iex> FiFo.map(FiFo.from_list([1, 2, 3]), fn x -> x + 2 end)
      #FiFo<[3, 4, 5]>
  """
  @spec map(t, (element -> element)) :: t
  def map(queue, fun)

  def map(%FiFo{rear: rear, front: front}, fun) do
    %FiFo{rear: Enum.map(rear, fun), front: Enum.map(front, fun)}
  end

  @doc """
  Checks if `element` exists within the `queue`.

  ## Examples

      iex> FiFo.member?(FiFo.from_list([1, 2, 3]), 2)
      true
      iex> FiFo.member?(FiFo.from_list([1, 2, 3]), 6)
      false
  """
  @spec member?(t, element) :: boolean
  def member?(queue, element)

  def member?(%FiFo{rear: rear, front: front}, x) do
    :lists.member(x, front) || :lists.member(x, rear)
  end

  @doc """
  Removes the `element` at the front of the queue. Returns tuple
  `{{value, element}, queue}`, where `queue` is the remaining queue. If the
  queue is empty a tuple `{:error, %FiFo{}}` is returned.

  ## Examples

      iex> queue = FiFo.from_list([1,2,3])
      iex> FiFo.pop(queue) == {{:ok, 1}, FiFo.drop(queue, 1)}
      true

      iex> FiFo.new() |> FiFo.pop() == {:error, %FiFo{}}
      true
  """
  @spec pop(t) :: {{:ok, element}, t} | {:error, empty}
  def pop(queue)

  # from an empty queue
  def pop(%FiFo{rear: [], front: []}), do: {:error, %FiFo{}}

  # from an queue with one element
  def pop(%FiFo{rear: [], front: [x]}), do: {{:ok, x}, %FiFo{}}

  def pop(%FiFo{rear: [x], front: []}), do: {{:ok, x}, %FiFo{}}

  # from a queue with two elements
  def pop(%FiFo{rear: [a], front: [b]}), do: {{:ok, b}, %FiFo{rear: [], front: [a]}}

  # from a queue with three elements
  def pop(%FiFo{rear: [a, b], front: [x]}), do: {{:ok, x}, %FiFo{rear: [a], front: [b]}}

  def pop(%FiFo{rear: [a], front: [x, b]}), do: {{:ok, x}, %FiFo{rear: [a], front: [b]}}

  # from a queue
  def pop(%FiFo{rear: rear, front: [x]}) do
    {{:ok, x}, rear |> to_front() |> from_erlang_queue()}
  end

  def pop(%FiFo{rear: rear, front: [x | tail]}) do
    {{:ok, x}, %FiFo{rear: rear, front: tail}}
  end

  # from a malformed queue
  def pop(%FiFo{rear: rear, front: []}) do
    {rear, [x | front]} = to_front(rear)
    {{:ok, x}, %FiFo{rear: rear, front: front}}
  end

  @doc """
  Removes the `element` at the front of the queue. Returns tuple
  `{{value, element}, queue}`, where `queue` is the remaining queue. If the
  queue is empty an `EmptyError` is raised.

  ## Examples

      iex> queue = FiFo.from_list([1,2,3])
      iex> FiFo.pop!(queue) == {1, FiFo.drop(queue, 1)}
      true

      iex> FiFo.pop!(FiFo.new()) == {:error, %FiFo{}}
      ** (FiFo.EmptyError) empty error
  """
  @spec pop!(t) :: {element, t}
  def pop!(queue) do
    case pop(queue) do
      {{:ok, x}, q} -> {x, q}
      {:error, _} -> raise FiFo.EmptyError
    end
  end

  @doc """
  Removes the `element` at the rear of the queue. Returns tuple
  `{{value, element}, queue}`, where `queue` is the remaining queue. If the
  queue is empty a tuple `{:error, %FiFo{}}` is returned.

  ## Examples

      iex> queue = FiFo.from_list([1,2,3])
      iex> FiFo.pop_reverse(queue) == {{:ok, 3}, FiFo.drop(queue, -1)}
      true

      iex> FiFo.new() |> FiFo.pop_reverse() == {:error, %FiFo{}}
      true
  """
  @spec pop_reverse(t) :: {{:ok, element}, t} | {:error, empty}
  def pop_reverse(queue)

  # form an empty queue
  def pop_reverse(%FiFo{rear: [], front: []}), do: {:error, %FiFo{}}

  # from a queue with one element
  def pop_reverse(%FiFo{rear: [], front: [x]}), do: {{:ok, x}, %FiFo{}}

  def pop_reverse(%FiFo{rear: [x], front: []}), do: {{:ok, x}, %FiFo{}}

  # from a queue with two elements
  def pop_reverse(%FiFo{rear: [x], front: [a]}), do: {{:ok, x}, %FiFo{front: [a]}}

  # from a queue with three elements
  def pop_reverse(%FiFo{rear: [x], front: [a, b]}), do: {{:ok, x}, %FiFo{rear: [b], front: [a]}}

  def pop_reverse(%FiFo{rear: [x, b], front: [a]}), do: {{:ok, x}, %FiFo{rear: [b], front: [a]}}

  # from a queue
  def pop_reverse(%FiFo{rear: [x], front: front}) do
    {{:ok, x}, front |> to_rear() |> from_erlang_queue()}
  end

  def pop_reverse(%FiFo{rear: [x | tail], front: front}) do
    {{:ok, x}, %FiFo{rear: tail, front: front}}
  end

  # from a malformed queue
  def pop_reverse(%FiFo{rear: [], front: front}) do
    {[x | rear], front} = to_rear(front)
    {{:ok, x}, %FiFo{rear: rear, front: front}}
  end

  @doc """
  Removes the `element` at the rear of the queue. Returns tuple
  `{{value, element}, queue}`, where `queue` is the remaining queue. If the
  queue is empty an `EmptyError` is raised.

  ## Examples

      iex> queue = FiFo.from_list([1,2,3])
      iex> FiFo.pop_reverse!(queue) == {3, FiFo.drop(queue, -1)}
      true

      iex> FiFo.pop!(FiFo.new()) == {:error, %FiFo{}}
      ** (FiFo.EmptyError) empty error
  """
  @spec pop_reverse!(t) :: {element, t}
  def pop_reverse!(queue) do
    case pop_reverse(queue) do
      {{:ok, x}, q} -> {x, q}
      {:error, _} -> raise FiFo.EmptyError
    end
  end

  @doc """
  Pushes an element to the rear of a queue.

  ## Examples

      iex> queue = FiFo.new()
      iex> queue = FiFo.push(queue, 2)
      #FiFo<[2]>
      iex> FiFo.push(queue, 4)
      #FiFo<[2, 4]>
  """
  @spec push(t, element) :: t
  def push(%FiFo{rear: [], front: []}, x) do
    %FiFo{rear: [x], front: []}
  end

  def push(%FiFo{rear: [_] = rear, front: []}, x) do
    %FiFo{rear: [x], front: rear}
  end

  def push(%FiFo{rear: rear, front: []}, x) do
    [x | rear] |> to_front() |> from_erlang_queue()
  end

  def push(%FiFo{rear: rear, front: front}, x) do
    %FiFo{rear: [x | rear], front: front}
  end

  @doc """
  Pushes an element to the front queue.

  ## Examples

      iex> queue = FiFo.new()
      iex> queue = FiFo.push_reverse(queue, 2)
      #FiFo<[2]>
      iex> FiFo.push_reverse(queue, 4)
      #FiFo<[4, 2]>
  """
  @spec push_reverse(t, element) :: t
  def push_reverse(%FiFo{rear: [], front: []}, x) do
    %FiFo{rear: [], front: [x]}
  end

  def push_reverse(%FiFo{rear: [], front: [_] = front}, x) do
    %FiFo{rear: front, front: [x]}
  end

  def push_reverse(%FiFo{rear: rear, front: front}, x) do
    %FiFo{rear: rear, front: [x | front]}
  end

  @doc """
  Returns a queue of elements in `queue` excluding those for which the
  function `fun` returns a truthy value.

  See also filter/2.

  ## Examples

      iex> FiFo.reject(FiFo.from_list([1, 2, 3, 4]), fn x -> rem(x, 2) == 0 end)
      #FiFo<[1, 3]>
  """
  @spec reject(t, (element -> as_boolean(element))) :: t
  def reject(queue, fun)

  def reject(%FiFo{rear: rear, front: front}, fun) do
    update_queue({Enum.reject(rear, fun), Enum.reject(front, fun)})
  end

  @doc """
  Returns `queue` in reverse order.

  ## Examples

      iex> FiFo.reverse(FiFo.from_list([1, 2, 3]))
      #FiFo<[3, 2, 1]>
  """
  @spec reverse(t) :: t
  def reverse(queue)

  def reverse(%FiFo{rear: rear, front: front}), do: %FiFo{rear: front, front: rear}

  @doc """
  Returns the number of elements in `queue`.

  ## Examples

      iex> FiFo.size(FiFo.from_range(1..42))
      42
  """
  @spec size(t) :: integer
  def size(queue)

  def size(%FiFo{rear: rear, front: front}), do: length(rear) + length(front)

  @doc """
  Takes an `amount` of elements from the rear or the front of the `queue`.
  Returns a tuple with taken values and the remaining queue.

  If a negative `amount` is given, the `amount` of elements will be taken from
  rear.

  ## Examples

      iex> queue = FiFo.from_range(1..10)
      iex> FiFo.take(queue, 3) == {[1, 2, 3], FiFo.drop(queue, 3)}
      true
      iex> FiFo.take(queue, 0) == {[], queue}
      true

      iex> FiFo.take(FiFo.new(), 10) == {[], FiFo.new()}
      true
  """
  @spec take(t, integer) :: {list, t}
  def take(queue, amount)

  # take zero
  def take(queue, 0), do: {[], queue}

  # from an empty queue
  def take(%FiFo{rear: [], front: []} = queue, _), do: {[], queue}

  def take(%FiFo{rear: rear, front: front}, n) when n > 0 do
    {result, {rear, front}} = do_take({rear, front}, n)
    {result, %FiFo{rear: rear, front: front}}
  end

  def take(%FiFo{rear: rear, front: front}, n) when n < 0 do
    {result, {front, rear}} = do_take({front, rear}, abs(n))
    {result, %FiFo{rear: rear, front: front}}
  end

  defp do_take({rear, front} = queue, n) when length(rear) + length(front) <= n do
    case queue do
      {[], front} -> {front, {[], []}}
      {[_] = x, front} -> {:lists.append(front, x), {[], []}}
      {rear, []} -> {:lists.reverse(rear), {[], []}}
      {rear, [x]} -> {[x | :lists.reverse(rear)], {[], []}}
      {rear, front} -> {:lists.append(front, :lists.reverse(rear)), {[], []}}
    end
  end

  defp do_take({rear, front}, n) do
    case length(front) - n do
      0 ->
        {front, to_front(rear)}

      diff when diff > 0 ->
        {result, rest} = :lists.split(n, front)
        {result, {rear, rest}}

      diff ->
        case length(rear) + diff do
          at when at > 0 and at < length(rear) ->
            {rest, result} = :lists.split(at, rear)
            {:lists.append(front, :lists.reverse(result)), to_front(rest)}

          _ ->
            {:lists.append(front, :lists.reverse(rear)), {[], []}}
        end
    end
  end

  @doc """
  Converts `queue` to an Erlang queue.

  ## Examples

      iex> q = FiFo.to_erlang_queue(FiFo.from_list([1, 2, 3, 4, 5]))
      {[5, 4], [1, 2, 3]}
      iex> q == :queue.from_list([1, 2, 3, 4, 5])
      true
  """
  @spec to_erlang_queue(t) :: {rear, front}
  def to_erlang_queue(queue)

  def to_erlang_queue(%FiFo{rear: rear, front: front}), do: {rear, front}

  @doc """
  Converts `queue` to a list.

  ## Examples

      iex> FiFo.to_list(FiFo.from_range(1..4))
      [1, 2, 3, 4]
  """
  @spec to_list(t) :: list
  def to_list(queue)

  def to_list(%FiFo{rear: rear, front: front}) do
    :lists.append(front, :lists.reverse(rear))
  end

  # Move half of elements from rear to front, if there are enough.
  defp to_front([]) do
    {[], []}
  end

  defp to_front([_] = x) do
    {x, []}
  end

  defp to_front([a, b]) do
    {[a], [b]}
  end

  defp to_front(list) do
    {rear, front} = :lists.split(div(length(list), 2) + 1, list)
    {rear, :lists.reverse(front)}
  end

  # Move half of elements from front to rear, if there are enough.
  defp to_rear([]) do
    {[], []}
  end

  defp to_rear([_] = x) do
    {x, []}
  end

  defp to_rear([a, b]) do
    {[b], [a]}
  end

  defp to_rear(list) do
    {front, rear} = :lists.split(div(length(list), 2) + 1, list)
    {:lists.reverse(rear), front}
  end

  # Updates an Erlang queue in a wellformed FiFo queue.
  defp update_queue(queue) do
    case queue do
      {[], []} ->
        %FiFo{}

      {[_, _ | _] = rear, []} ->
        rear |> to_front() |> from_erlang_queue()

      {[], [_, _ | _] = front} ->
        front |> to_rear() |> from_erlang_queue()

      queue ->
        from_erlang_queue(queue)
    end
  end

  defimpl Collectable do
    def into(original) do
      fun = fn
        queue, {:cont, x} -> FiFo.push(queue, x)
        queue, :done -> queue
        _queue, :halt -> :ok
      end

      {original, fun}
    end
  end

  defimpl Enumerable do
    def count(queue) do
      {:ok, FiFo.size(queue)}
    end

    def member?(queue, x) do
      {:ok, FiFo.member?(queue, x)}
    end

    def slice(queue) do
      list = FiFo.to_list(queue)
      size = length(list)
      {:ok, size, &Enumerable.List.slice(list, &1, &2, size)}
    end

    def reduce(queue, acc, fun) do
      queue |> FiFo.to_list() |> Enumerable.List.reduce(acc, fun)
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(queue, opts) do
      opts = %Inspect.Opts{opts | charlists: :as_lists}
      concat(["#FiFo<", Inspect.List.inspect(FiFo.to_list(queue), opts), ">"])
    end
  end
end

defmodule FiFo.EmptyError do
  defexception message: "empty error"
end
