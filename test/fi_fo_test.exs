defmodule FiFoTest do
  use ExUnit.Case
  doctest FiFo

  import FiFo

  test "new/0" do
    assert new() == %FiFo{}
  end

  test "push/2" do
    queue = new()
    assert %FiFo{rear: [1], front: []} = queue = push(queue, 1)
    assert %FiFo{rear: [2], front: [1]} = queue = push(queue, 2)
    assert %FiFo{rear: [3, 2], front: [1]} = queue = push(queue, 3)
    assert %FiFo{rear: [4, 3, 2], front: [1]} = push(queue, 4)
  end

  @tag :only
  test "pop/1" do
    queue = Enum.reduce(1..10, new(), fn x, q -> push(q, x) end)

    assert {{:ok, 1}, queue} = pop(queue)
    assert queue == %FiFo{rear: [10, 9, 8, 7, 6], front: [2, 3, 4, 5]}
    assert {{:ok, 2}, queue} = pop(queue)
    assert queue == %FiFo{rear: [10, 9, 8, 7, 6], front: [3, 4, 5]}
    assert {{:ok, 3}, queue} = pop(queue)
    assert queue == %FiFo{rear: [10, 9, 8, 7, 6], front: [4, 5]}
    assert {{:ok, 4}, queue} = pop(queue)
    assert queue == %FiFo{rear: [10, 9, 8, 7, 6], front: [5]}
    assert {{:ok, 5}, queue} = pop(queue)
    assert queue == %FiFo{rear: [10, 9, 8], front: [6, 7]}
    assert {{:ok, 6}, queue} = pop(queue)
    assert queue == %FiFo{rear: [10, 9, 8], front: [7]}
    assert {{:ok, 7}, queue} = pop(queue)
    assert queue == %FiFo{rear: [10, 9], front: [8]}
    assert {{:ok, 8}, queue} = pop(queue)
    assert queue == %FiFo{rear: [10], front: [9]}
    assert {{:ok, 9}, queue} = pop(queue)
    assert queue == %FiFo{rear: [], front: [10]}
    assert {{:ok, 10}, queue} = pop(queue)
    assert queue == %FiFo{}
    assert {{:error, :empty}, %FiFo{}} = pop(queue)
  end

  test "queue?/1" do
    assert queue?(new())
    assert queue?(from_list([1, 2, 3]))
    refute queue?(:foo)
  end

  test "size/1" do
    queue = new()
    assert size(queue) == 0
    queue = push(queue, 2)
    assert size(queue) == 1
  end

  test "Enum.count/" do
    queue = new()
    queue = push(queue, 2)
    assert Enum.count(queue) == 1
  end

  test "member/2" do
    queue = Enum.reduce(1..10, new(), fn x, q -> push(q, x) end)
    assert member?(queue, 5)
    refute member?(queue, 55)
  end

  test "Enum.member?/2" do
    queue = Enum.reduce(1..10, new(), fn x, q -> push(q, x) end)
    assert Enum.member?(queue, 5)
    refute Enum.member?(queue, 55)
  end

  test "to_list/1" do
    queue = Enum.reduce(1..3, new(), fn x, q -> push(q, x) end)
    assert to_list(queue) == [1, 2, 3]
  end

  test "Enum.slice/1" do
    queue = Enum.reduce(1..20, new(), fn x, q -> push(q, x) end)
    assert Enum.slice(queue, 5..10) == [6, 7, 8, 9, 10, 11]
  end

  test "Enum.with_index/1" do
    queue = Enum.reduce(3..1, new(), fn x, q -> push(q, x) end)
    assert Enum.with_index(queue) == [{3, 0}, {2, 1}, {1, 2}]
  end

  test "Enum.filter/2" do
    queue = Enum.reduce(1..10, new(), fn x, q -> push(q, x) end)
    assert Enum.filter(queue, fn x -> rem(x, 2) == 0 end) == [2, 4, 6, 8, 10]
  end

  test "filter/2" do
    queue = Enum.reduce(1..10, new(), fn x, q -> push(q, x) end)
    assert filter(queue, fn x -> rem(x, 2) == 0 end) == %FiFo{front: [2, 4], rear: [10, 8, 6]}
  end

  test "from_list/1" do
    list = Enum.to_list(500..510)

    assert from_list(list) == %FiFo{
             rear: [510, 509, 508, 507, 506],
             front: [500, 501, 502, 503, 504, 505]
           }
  end

  test "Enum.take/2" do
    queue = Enum.reduce(1..10, new(), fn x, q -> push(q, x) end)
    assert Enum.take(queue, 3) == [1, 2, 3]
  end

  test "take/2" do
    queue = 1..10 |> Enum.to_list() |> from_list()

    assert queue == %FiFo{front: [1, 2, 3, 4, 5, 6], rear: [10, 9, 8, 7]}

    assert take(queue, 1) == {[1], %FiFo{front: [2, 3, 4, 5, 6], rear: [10, 9, 8, 7]}}
    assert take(queue, 2) == {[1, 2], %FiFo{front: [3, 4, 5, 6], rear: [10, 9, 8, 7]}}
    assert take(queue, 6) == {[1, 2, 3, 4, 5, 6], %FiFo{front: [7], rear: [10, 9, 8]}}
    assert take(queue, 8) == {[1, 2, 3, 4, 5, 6, 7, 8], %FiFo{front: [9], rear: [10]}}
    assert take(queue, 8) == {[1, 2, 3, 4, 5, 6, 7, 8], %FiFo{front: [9], rear: [10]}}
    assert take(queue, 9) == {[1, 2, 3, 4, 5, 6, 7, 8, 9], %FiFo{front: [], rear: [10]}}
    assert take(queue, 10) == {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10], %FiFo{front: [], rear: []}}
    assert take(queue, 11) == {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10], %FiFo{front: [], rear: []}}
  end

  test "drop/2" do
    queue = 1..10 |> Enum.to_list() |> from_list()

    assert queue == %FiFo{front: [1, 2, 3, 4, 5, 6], rear: [10, 9, 8, 7]}

    assert drop(queue, 1) == %FiFo{front: [2, 3, 4, 5, 6], rear: [10, 9, 8, 7]}
    assert drop(queue, 2) == %FiFo{front: [3, 4, 5, 6], rear: [10, 9, 8, 7]}
    assert drop(queue, 6) == %FiFo{front: [7], rear: [10, 9, 8]}
    assert drop(queue, 8) == %FiFo{front: [9], rear: [10]}
    assert drop(queue, 8) == %FiFo{front: [9], rear: [10]}
    assert drop(queue, 9) == %FiFo{front: [], rear: [10]}
    assert drop(queue, 10) == %FiFo{front: [], rear: []}
    assert drop(queue, 11) == %FiFo{front: [], rear: []}
  end

  test "inspect/1" do
    assert from_list([1,2,3]) |> inspect == "#FiFo<[1, 2, 3]>"
  end
end
