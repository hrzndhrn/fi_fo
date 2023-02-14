defmodule FiFo do
  @moduledoc """
  This module provides FIFO queues in an efficient manner.

  `FiFo` is just a rewrite of the [Erlang](http://erlang.org)
  module [queue](http://erlang.org/doc/man/queue.html) in an
  Elixir way.

  All queues generated with functions from this module are wellformed. A
  malformed queue is a queue with a front-list with more as one value and an
  empty list for the rear-list or the other way around. This module handles
  also malformed queues, just slower.
  """

  import FiFo.Guards

  @compile :inline_list_funcs
  @compile {:inline, do_take: 2, drop: 3, fetch: 1, fetch_reverse: 1, to_front: 1, to_rear: 1}

  @type front :: list
  @type rear :: list
  @type queue :: {rear, front}
  @type empty :: {[], []}
  @type value :: any

  defstruct rear: [], front: []

  @doc """
  Returns an empty queue.

  ## Examples

      iex> FiFo.new()
      {[], []}
  """
  @spec new :: queue
  def new, do: {[], []}

  @doc """
  Return a `queue` from the given `enumerable`.

  ## Examples

      iex> FiFo.new([1, 2, 3])
      {[3, 2], [1]}

      iex> FiFo.new(1..10)
      {[10, 9, 8, 7, 6], [1, 2, 3, 4, 5]}
  """
  @spec new(enumerable :: Enumerable.t()) :: queue
  def new([]), do: {[], []}

  def new([value]), do: {[value], []}

  def new([value_a, value_b]), do: {[value_b], [value_a]}

  def new([value_a, value_b, value_c]), do: {[value_c, value_b], [value_a]}

  def new(list) when is_list(list) do
    {front, [value_a, value_b | rest]} = :lists.split(div(length(list), 2), list)
    {:lists.reverse(rest, [value_b, value_a]), front}
  end

  def new(enumerable), do: enumerable |> Enum.to_list() |> new()

  @doc """
  Converts `queue` to a list.

  ## Examples

      iex> FiFo.to_list(FiFo.new(1..4))
      [1, 2, 3, 4]
  """
  @spec to_list(queue) :: list
  def to_list(queue)

  def to_list({[], []}), do: []

  def to_list({[], front}), do: front

  def to_list({rear, []}), do: :lists.reverse(rear, [])

  def to_list({rear, front}) when is_queue(rear, front) do
    :lists.append(front, :lists.reverse(rear, []))
  end

  @doc """
  Given a list of `queues`, concatenates the `queues` into a single queue. The
  first queue in the list becomes the front of the queue.

  ## Examples

      iex> FiFo.concat([
      ...>   FiFo.new(1..3), FiFo.new(4..5), FiFo.new(7..9)
      ...> ])
      {[9, 8, 7, 5], [1, 2, 3, 4]}
  """
  @spec concat([queue]) :: queue
  def concat([]), do: {[], []}

  def concat([{rear, front} = queue]) when is_queue(rear, front), do: queue

  def concat(list) when is_list(list) do
    to_rear(:lists.foldl(fn queue, acc -> acc ++ to_list(queue) end, [], list))
  end

  @doc """
  Concatenates the queue `right` with the queue `left` with queue `left` in
  front of queue `right`.

  ## Examples

      iex> FiFo.concat(FiFo.new([1, 2]), FiFo.new([3, 4]))
      {[4, 3], [1, 2]}
  """
  @spec concat(left :: queue, right :: queue) :: queue
  def concat({rear_left, front_left} = left, {rear_right, front_right} = right)
      when is_queue(rear_left, front_left) and is_queue(rear_right, front_right) do
    concat([left, right])
  end

  @doc """
  Drops the `amount` of elements from the `queue`.

  If a negative `amount` is given, the `amount` of last values will be dropped.

  ## Examples

      iex> [1, 2, 3] |> FiFo.new() |> FiFo.drop(2)
      {[3],[]}

      iex> [1, 2, 3] |> FiFo.new() |> FiFo.drop(-2)
      {[],[1]}

      iex> [1, 2, 3] |> FiFo.new() |> FiFo.drop(10)
      {[], []}

      iex> [1, 2, 3] |> FiFo.new() |> FiFo.drop(0)
      {[3, 2], [1]}
  """
  @spec drop(queue, non_neg_integer) :: queue
  def drop({[], []} = queue, _amount), do: queue

  def drop({rear, front} = queue, 0) when is_queue(rear, front), do: queue

  def drop({rear, front}, amount) when is_queue(rear, front) do
    if amount > 0 do
      drop(rear, front, amount)
    else
      {front, rear} = drop(front, rear, abs(amount))
      {rear, front}
    end
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

      iex> FiFo.empty?(FiFo.new([1]))
      false
  """
  @spec empty?(queue) :: boolean
  def empty?(queue)

  def empty?({[], []}), do: true

  def empty?({rear, front}) when is_queue(rear, front), do: false

  @doc """
  Fetches value at the front of `queue`.

  If `queue` is not empty, then `{{:ok, value}, queue}` is returned. If `queue` is
  empty `{:error, queue}` is returned.

  ## Examples

      iex> FiFo.fetch(FiFo.new([1, 2]))
      {{:ok, 1}, {[2],[]}}

      iex> FiFo.fetch(FiFo.new())
      {:error, {[], []}}
  """
  @spec fetch(queue) :: {{:ok, value}, queue} | {:error, empty}
  def fetch(queue)

  def fetch({[], []}), do: {:error, {[], []}}

  def fetch({[value], []}), do: {{:ok, value}, {[], []}}

  def fetch({[], [value]}), do: {{:ok, value}, {[], []}}

  def fetch({rear, []}) when is_list(rear) do
    {rear, [value | front]} = to_front(rear)
    {{:ok, value}, {rear, front}}
  end

  def fetch({[], [value | front]}) do
    {{:ok, value}, to_rear(front)}
  end

  def fetch({rear, [value]}) when is_list(rear) do
    {{:ok, value}, to_front(rear)}
  end

  def fetch({rear, [value | front]}) when is_list(rear) do
    {{:ok, value}, {rear, front}}
  end

  @doc """
  Fetches element at the front of `queue`, erroring out if `queue` is empty.

  If `queue` is not empty, then `{:ok, value}` is returned. If `queue` is
  empty a `FiFo.EmptyError` excepetion is raised.

  ## Examples

      iex> FiFo.fetch!(FiFo.new([1, 2]))
      {1, {[2], []}}

      iex> FiFo.fetch!(FiFo.new())
      ** (FiFo.EmptyError) empty queue
  """
  @spec fetch!(queue) :: value
  def fetch!({rear, front} = queue) when is_list(rear) and is_list(front) do
    case fetch(queue) do
      {{:ok, value}, queue} -> {value, queue}
      {:error, _queue} -> raise FiFo.EmptyError
    end
  end

  @doc """
  Fetches `value` at the rear of `queue`.

  If `queue` is not empty, then `{:ok, value}` is returned. If `queue` is
  empty `:error` is returned.

  ## Examples

      iex> FiFo.fetch_reverse(FiFo.new([1, 2]))
      {{:ok, 2}, {[1], []}}

      iex> FiFo.fetch_reverse(FiFo.new())
      {:error, {[], []}}
  """
  @spec fetch_reverse(queue) :: {{:ok, value}, queue} | {:error, empty}
  def fetch_reverse(queue)

  def fetch_reverse({[], []}), do: {:error, {[], []}}

  def fetch_reverse({[], [value]}), do: {{:ok, value}, {[], []}}

  def fetch_reverse({[value], []}), do: {{:ok, value}, {[], []}}

  def fetch_reverse({[value], front}), do: {{:ok, value}, to_rear(front)}

  def fetch_reverse({[value | rear], []}), do: {{:ok, value}, to_front(rear)}

  def fetch_reverse({[], front}) when is_list(front) do
    {[value | rear], front} = to_rear(front)
    {{:ok, value}, {rear, front}}
  end

  def fetch_reverse({[value | rear], front}) when is_list(front) do
    {{:ok, value}, {rear, front}}
  end

  @doc """
  Fetches `value` at the rear of `queue`, erroring out if `queue` is empty.

  If `queue` is not empty, then `{:ok, value}` is returned. If `queue` is
  empty a `FiFo.EmptyError` excepetion is raised.

  ## Examples

      iex> q = FiFo.new()
      iex> FiFo.fetch!(q)
      ** (FiFo.EmptyError) empty queue

      iex> q = FiFo.new([1, 2, 3])
      iex> FiFo.fetch!(q)
      {1, {[3], [2]}}
  """
  @spec fetch_reverse!(queue) :: {:ok, value} | :error
  def fetch_reverse!({rear, front} = queue) when is_list(rear) and is_list(front) do
    case fetch_reverse(queue) do
      {{:ok, value}, queue} -> {value, queue}
      {:error, _queue} -> raise FiFo.EmptyError
    end
  end

  @doc """
  Filters the queue, i.e. returns only those values for which fun returns
  a truthy value.

  See also `reject/2` which discards all values where the function returns a
  truthy value.

  ## Examples

      iex> [1, 2, 3, 4]
      ...> |> FiFo.new()
      ...> |> FiFo.filter(fn x -> rem(x, 2) == 0 end)
      ...> |> FiFo.to_list()
      [2, 4]
  """
  @spec filter(queue, fun :: (value -> as_boolean(value))) :: queue
  def filter(queue, fun)

  def filter({rear, front}, fun) when is_list(rear) and is_list(front) do
    case {:lists.filter(fun, rear), :lists.filter(fun, front)} do
      {[], []} -> {[], []}
      {rear, []} -> to_front(rear)
      {[], front} -> to_rear(front)
      queue -> queue
    end
  end

  @doc """
  Gets `value` at the front of `queue`, erroring out if `queue` is empty.

  If `queue` is empty default is returned.

  If `default` is not provided, `nil` is used.

  ## Examples

      iex> FiFo.get(FiFo.new([1, 2]))
      {1, {[2], []}}

      iex> FiFo.get(FiFo.new())
      {nil, {[], []}}

      iex> FiFo.get(FiFo.new(), :empty)
      {:empty, {[], []}}
  """
  @spec get(queue, default :: value) :: value
  def get(queue, default \\ nil)

  def get({[], []}, default), do: {default, {[], []}}

  def get({[value], []}, _default), do: {value, {[], []}}

  def get({[], [value]}, _default), do: {value, {[], []}}

  def get({rear, []}, _default) when is_list(rear) do
    {rear, [value | front]} = to_front(rear)
    {value, {rear, front}}
  end

  def get({[], [value | front]}, _default) do
    {value, to_rear(front)}
  end

  def get({rear, [value]}, _default) when is_list(rear) do
    {value, to_front(rear)}
  end

  def get({rear, [value | front]}, _default) when is_list(rear) do
    {value, {rear, front}}
  end

  @doc """
  Gets `value` at the rear of `queue`, erroring out if `queue` is empty.

  If `queue` is empty default is returned.

  If `default` is not provided, `nil` is used.

  ## Examples

      iex> FiFo.get_reverse(FiFo.new([1, 2]))
      {2, {[1], []}}

      iex> FiFo.get_reverse(FiFo.new())
      {nil, {[], []}}

      iex> FiFo.get_reverse(FiFo.new(), :empty)
      {:empty, {[], []}}
  """
  @spec get_reverse(queue, default :: value) :: value
  def get_reverse(queue, default \\ nil)

  def get_reverse({[], []}, default), do: {default, {[], []}}

  def get_reverse({[], [value]}, _default), do: {value, {[], []}}

  def get_reverse({[value], []}, _default), do: {value, {[], []}}

  def get_reverse({[value], front}, _default), do: {value, to_rear(front)}

  def get_reverse({[value | rear], []}, _default), do: {value, to_front(rear)}

  def get_reverse({[], front}, _default) when is_list(front) do
    {[value | rear], front} = to_rear(front)
    {value, {rear, front}}
  end

  def get_reverse({[value | rear], front}, _default) when is_list(front) do
    {value, {rear, front}}
  end

  @doc """
  Returns a `queue` where each `value` is the result of invoking fun on each
  corresponding `value` of `queue`.

  ## Examples

      iex> FiFo.map(FiFo.new([1, 2, 3]), fn x -> x + 2 end)
      {[5, 4], [3]}
  """
  @spec map(queue, (value -> value)) :: queue
  def map(queue, fun)

  def map({rear, front}, fun) when is_queue(rear, front) and is_function(fun, 1) do
    {:lists.map(fun, rear), :lists.map(fun, front)}
  end

  @doc """
  Checks if `value` exists within the `queue`.

  ## Examples

      iex> FiFo.member?(FiFo.new([1, 2, 3]), 2)
      true
      iex> FiFo.member?(FiFo.new([1, 2, 3]), 6)
      false
  """
  @spec member?(queue, value) :: boolean
  def member?(queue, value)

  def member?({rear, front}, value) when is_queue(rear, front) do
    :lists.member(value, front) || :lists.member(value, rear)
  end

  @doc """
  Pushes a list of values to a queue.

  ## Examples

      iex> queue = FiFo.new()
      iex> queue = FiFo.push(queue, [1, 2])
      {[2], [1]}
      iex> FiFo.push(queue, [3, 4])
      {[4, 3, 2], [1]}
  """
  @spec push(queue, [value]) :: queue
  def push(queue, list)

  def push({[], []}, values) when is_list(values), do: new(values)

  def push({[value], []}, values) when is_list(values) do
    {rear, front} = new(values)
    {rear, [value | front]}
  end

  def push({rear, []}, values) when is_list(rear) and is_list(values) do
    {rear, front} = to_front(rear)
    {:lists.reverse(values, rear), front}
  end

  def push({rear, front}, values) when is_queue(rear, front) and is_list(values) do
    {:lists.reverse(values, rear), front}
  end

  @doc """
  Pushes an element to the front queue.

  ## Examples

      iex> queue = FiFo.new()
      iex> queue = FiFo.push_reverse(queue, [3, 4])
      {[4], [3]}
      iex> FiFo.push_reverse(queue, [1, 2])
      {[4], [1, 2, 3]}
  """
  @spec push_reverse(queue, [value]) :: queue
  def push_reverse(queue, list)

  def push_reverse({[], []}, values) when is_list(values), do: new(values)

  def push_reverse({[], front}, values) when is_list(front) and is_list(values) do
    {rear, front} = to_rear(front)
    {rear, values ++ front}
  end

  def push_reverse({rear, []}, values) when is_list(rear) and is_list(values) do
    {rear, values}
  end

  def push_reverse({rear, front}, values) when is_queue(rear, front) and is_list(values) do
    {rear, values ++ front}
  end

  @doc """
  Returns a queue of elements in `queue` excluding those for which the
  function `fun` returns a truthy value.

  See also `filter/2`.

  ## Examples

      iex> FiFo.reject(FiFo.new([1, 2, 3, 4]), fn x -> rem(x, 2) == 0 end)
      {[3], [1]}
  """
  @spec reject(queue, (value -> as_boolean(value))) :: queue
  def reject(queue, fun)

  def reject({rear, front}, fun) when is_queue(rear, front) and is_function(fun, 1) do
    fun = fn value -> !fun.(value) end

    case {:lists.filter(fun, rear), :lists.filter(fun, front)} do
      {[], []} -> {[], []}
      {rear, []} -> to_front(rear)
      {[], front} -> to_rear(front)
      queue -> queue
    end
  end

  @doc """
  Returns `queue` in reverse order.

  ## Examples

      iex> FiFo.reverse(FiFo.new([1, 2, 3]))
      {[1], [3,2]}
  """
  @spec reverse(queue) :: queue
  def reverse(queue)

  def reverse({rear, front}), do: {front, rear}

  @doc """
  Returns the number of elements in `queue`.

  ## Examples

      iex> FiFo.size(FiFo.new(1..42))
      42
  """
  @spec size(queue) :: integer
  def size(queue)

  def size({rear, front}) when is_queue(rear, front), do: length(rear) + length(front)

  @doc """
  Takes an `amount` of elements from the rear or the front of the `queue`.
  Returns a tuple with taken values and the remaining queue.

  If a negative `amount` is given, the `amount` of elements will be taken from
  rear.

  ## Examples

      iex> queue = FiFo.new(1..10)
      iex> FiFo.take(queue, 3) == {[1, 2, 3], FiFo.drop(queue, 3)}
      true
      iex> FiFo.take(queue, 0) == {[], queue}
      true

      iex> FiFo.take(FiFo.new(), 10) == {[], FiFo.new()}
      true
  """
  @spec take(queue, amount :: integer) :: {[value], queue}
  def take({rear, front} = queue, 0) when is_queue(rear, front), do: {[], queue}

  def take({[], []} = queue, _amount), do: {[], queue}

  def take({rear, front}, amount) when is_queue(rear, front) and amount > 0 do
    do_take({rear, front}, amount)
  end

  def take({rear, front}, amount) when is_queue(rear, front) and amount < 0 do
    {result, {front, rear}} = do_take({front, rear}, abs(amount))
    {result, {rear, front}}
  end

  defp do_take({rear, front}, amount) when length(rear) + length(front) > amount do
    diff = length(front) - amount

    cond do
      diff == 0 ->
        {front, to_front(rear)}

      diff > 0 ->
        {result, rest} = :lists.split(amount, front)
        queue = if rear == [], do: to_rear(rest), else: {rear, rest}
        {result, queue}

      true ->
        at = length(rear) + diff
        {rest, result} = :lists.split(at, rear)
        {:lists.append(front, :lists.reverse(result, [])), to_front(rest)}
    end
  end

  defp do_take({rear, front}, _amount) do
    {:lists.append(front, :lists.reverse(rear, [])), {[], []}}
  end

  @doc """
  Puts the given `value` to the rear of the `queue`.
  """
  @spec put(queue, value) :: queue
  def put(queue, value)

  def put({[], []}, value), do: {[value], []}

  def put({[rear], []}, value), do: {[value], [rear]}

  def put({rear, []}, value) when is_list(rear) do
    {rear, front} = to_front(rear)
    {[value | rear], front}
  end

  def put({rear, front}, value) when is_queue(rear, front) do
    {[value | rear], front}
  end

  @doc """
  Puts the given `value` to the front of the `queue`.
  """
  @spec put_reverse(queue, value) :: queue
  def put_reverse(queue, value)

  def put_reverse({[], []}, value), do: {[], [value]}

  def put_reverse({[], [front]}, value), do: {[front], [value]}

  def put_reverse({[], front}, value) when is_list(front) do
    {rear, front} = to_rear(front)
    {rear, [value | front]}
  end

  def put_reverse({rear, front}, value) when is_queue(rear, front) do
    {rear, [value | front]}
  end

  @doc """
  Returns the first item from the `queue`.
  """
  @spec peek(queue, default :: value) :: queue
  def peek(queue, default \\ nil)

  def peek({[], []}, default), do: default

  def peek({rear, [value | _rest]}, _default) when is_list(rear), do: value

  def peek({[value], []}, _default), do: value

  def peek({[_value | rear], []}, _default), do: :lists.last(rear)

  @doc """
  Returns the last item from the `queue`.
  """
  @spec peek_reverse(queue, default :: value) :: queue
  def peek_reverse(queue, default \\ nil)

  def peek_reverse({[], []}, default), do: default

  def peek_reverse({[value | _rear], front}, _default) when is_list(front), do: value

  def peek_reverse({[], [value]}, _default), do: value

  def peek_reverse({[], [_value | front]}, _default), do: :lists.last(front)

  @doc """
  Returns `true` if `fun.(value)` is truthy for all values in the `queue`.
  """
  @spec all?(queue, (value -> as_boolean(value))) :: boolean
  def all?(queue, fun)

  def all?({rear, front}, fun) when is_queue(rear, front) and is_function(fun, 1) do
    :lists.all(fun, rear) and :lists.all(fun, front)
  end

  @doc """
  Returns `true` if `fun.(value)` is truthy for at least one value in the `queue`.
  """
  @spec any?(queue, (value -> as_boolean(value))) :: boolean
  def any?(queue, fun)

  def any?({rear, front}, fun) when is_queue(rear, front) and is_function(fun, 1) do
    :lists.any(fun, rear) or :lists.any(fun, front)
  end

  # Move half of elements from rear to front, if there are enough.
  defp to_front([_] = rear), do: {rear, []}

  defp to_front([value_a, value_b]), do: {[value_a], [value_b]}

  defp to_front([value_a, value_b, value_c]), do: {[value_a, value_b], [value_c]}

  defp to_front(list) do
    {rear, [value_a, value_b | rest]} = :lists.split(div(length(list), 2), list)
    {rear, :lists.reverse(rest, [value_b, value_a])}
  end

  # Move half of elements from front to rear, if there are enough.
  defp to_rear([_] = rear), do: {rear, []}

  defp to_rear([value_a, value_b]), do: {[value_b], [value_a]}

  defp to_rear([value_a, value_b, value_c]), do: {[value_c, value_b], [value_a]}

  defp to_rear(list) do
    {front, [value_a, value_b | rest]} = :lists.split(div(length(list), 2), list)
    {:lists.reverse(rest, [value_b, value_a]), front}
  end
end
