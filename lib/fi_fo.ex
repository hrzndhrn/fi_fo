defmodule FiFo do
  @moduledoc """
  This module provides FIFO queues in an efficient manner.

  The module is a reimplementation of the Erlang module
  [queue](http://erlang.org/doc/man/queue.html) with a different API and without
  reverse operations.
  """

  @compile :inline_list_funcs
  @compile {:inline, to_front: 1}

  @type front :: list
  @type rear :: list
  @type element :: term
  @type value :: {:ok, element}
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
  Pushes an element to the queue.

  ## Examples

      iex> queue = FiFo.new()
      iex> queue = FiFo.push(queue, 2)
      #FiFo<[2]>
      iex> FiFo.push(queue, 4)
      #FiFo<[2, 4]>
  """
  @spec push(t, element) :: t
  def push(%FiFo{rear: [], front: []}, x), do: %FiFo{rear: [x], front: []}

  def push(%FiFo{rear: [_] = rear, front: []}, x), do: %FiFo{rear: [x], front: rear}

  def push(%FiFo{rear: rear, front: front}, x), do: %FiFo{rear: [x | rear], front: front}

  @doc """
  Returns a tuple with an `:ok` tuple containing the element and the remaining
  queue. If the queue is empty a tuple with `{:error, :empty}` and an empty
  queue is returned.

  ## Examples

      iex> queue = FiFo.from_list([1,2,3])
      iex> FiFo.pop(queue) == {{:ok, 1}, FiFo.drop(queue, 1)}
      true

      iex> FiFo.new() |> FiFo.pop() == {{:error, :empty}, %FiFo{}}
      true
  """
  @spec pop(t) :: {value, t} | {{:error, :empty}, empty}
  def pop(%FiFo{rear: [], front: []}), do: {{:error, :empty}, %FiFo{}}

  def pop(%FiFo{rear: [], front: [x]}), do: {{:ok, x}, %FiFo{}}

  def pop(%FiFo{rear: [a], front: [b]}), do: {{:ok, b}, %FiFo{rear: [], front: [a]}}

  def pop(%FiFo{rear: [a, b], front: [x]}), do: {{:ok, x}, %FiFo{rear: [a], front: [b]}}

  def pop(%FiFo{rear: rear, front: [x]}), do: {{:ok, x}, to_front(rear)}

  def pop(%FiFo{rear: rear, front: [x | tail]}), do: {{:ok, x}, %FiFo{rear: rear, front: tail}}

  @spec take(t, non_neg_integer) :: {list, t}
  def take(%FiFo{rear: rear, front: front}, n) when n >= 0 do
    case length(front) - n do
      0 ->
        {front, to_front(rear)}

      diff when diff > 0 ->
        {result, rest} = :lists.split(n, front)
        {result, %FiFo{rear: rear, front: rest}}

      diff ->
        case length(rear) + diff do
          at when at > 0 and at < length(rear) ->
            {rest, result} = :lists.split(at, rear)
            {:lists.append(front, :lists.reverse(result)), to_front(rest)}

          _ ->
            {:lists.append(front, :lists.reverse(rear)), %FiFo{}}
        end
    end
  end

  @spec drop(t, non_neg_integer) :: t
  def drop(%FiFo{rear: rear, front: front}, n) when n >= 0 do
    case length(front) - n do
      0 ->
        to_front(rear)

      diff when diff > 0 ->
        %FiFo{rear: rear, front: Enum.drop(front, n)}

      diff ->
        case length(rear) + diff do
          at when at > 0 ->
            rear |> Enum.take(length(rear) + diff) |> to_front()

          _ ->
            %FiFo{}
        end
    end
  end

  @spec queue?(t) :: boolean
  def queue?(%FiFo{}), do: true

  def queue?(_), do: false

  @spec size(t) :: integer
  def size(%FiFo{rear: rear, front: front}), do: length(rear) + length(front)

  @spec member?(t, element) :: boolean
  def member?(%FiFo{rear: rear, front: front}, x),
    do: :lists.member(x, front) || :lists.member(x, rear)

  @spec to_list(t) :: list
  def to_list(%FiFo{rear: rear, front: front}), do: :lists.append(front, :lists.reverse(rear))

  @spec from_list(list) :: t
  def from_list(list) do
    {front, rear} = :lists.split(div(length(list), 2) + 1, list)
    %FiFo{rear: :lists.reverse(rear), front: front}
  end

  @spec filter(t, (element -> as_boolean(element))) :: t
  def filter(%FiFo{rear: rear, front: front}, fun) do
    rear = Enum.filter(rear, fun)
    front = Enum.filter(front, fun)
    if front == [], do: to_front(rear), else: %FiFo{rear: rear, front: front}
  end

  defp to_front([x]), do: %FiFo{rear: [x], front: []}

  defp to_front([a, b]), do: %FiFo{rear: [a], front: [b]}

  defp to_front(list) do
    {rear, front} = :lists.split(div(length(list), 2) + 1, list)
    %FiFo{rear: rear, front: :lists.reverse(front)}
  end

  defimpl Enumerable do
    def count(queue), do: {:ok, FiFo.size(queue)}

    def member?(queue, x), do: {:ok, FiFo.member?(queue, x)}

    def slice(queue) do
      list = FiFo.to_list(queue)
      size = length(list)
      {:ok, size, &Enumerable.List.slice(list, &1, &2)}
    end

    def reduce(queue, acc, fun), do: queue |> FiFo.to_list() |> Enumerable.List.reduce(acc, fun)
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(queue, opts) do
      opts = %Inspect.Opts{opts | charlists: :as_lists}
      concat(["#FiFo<", Inspect.List.inspect(FiFo.to_list(queue), opts), ">"])
    end
  end
end
