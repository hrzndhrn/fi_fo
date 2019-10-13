defmodule FiFoTest do
  use ExUnit.Case
  doctest FiFo

  test "new/0" do
    assert FiFo.new() == %FiFo{}
  end

  describe "concat/1" do
    test "with an empty list" do
      assert FiFo.concat([]) == %FiFo{}
    end

    test "with one queue" do
      assert FiFo.concat([%FiFo{rear: [1], front: []}]) == %FiFo{rear: [1], front: []}
    end

    test "with a list of queues" do
      assert FiFo.concat([
               %FiFo{rear: [], front: [1, 2]},
               %FiFo{rear: [], front: []},
               %FiFo{rear: [5, 4], front: [3]}
             ]) == %FiFo{rear: [5, 4], front: [1, 2, 3]}
    end
  end

  describe "drop/2" do
    test "with an empty queue" do
      assert FiFo.drop(%FiFo{}, 2) == %FiFo{}
      assert FiFo.drop(%FiFo{}, 0) == %FiFo{}
      assert FiFo.drop(%FiFo{}, -2) == %FiFo{}
    end

    test "drops a part from front" do
      assert FiFo.drop(%FiFo{rear: [8, 7, 6], front: [1, 2, 3, 4, 5]}, 3) ==
               %FiFo{rear: [8, 7, 6], front: [4, 5]}
    end

    test "drops a part from rear" do
      assert FiFo.drop(%FiFo{rear: [8, 7, 6], front: [1, 2, 3, 4, 5]}, -2) ==
               %FiFo{rear: [6], front: [1, 2, 3, 4, 5]}
    end

    test "drops the whole front" do
      assert FiFo.drop(%FiFo{rear: [2], front: [1]}, 1) ==
               %FiFo{rear: [2], front: []}

      assert FiFo.drop(%FiFo{rear: [8, 7, 6], front: [1, 2, 3, 4, 5]}, 5) ==
               %FiFo{rear: [8, 7], front: [6]}
    end

    test "drops the whole rear" do
      assert FiFo.drop(%FiFo{rear: [2], front: [1]}, -1) ==
               %FiFo{rear: [], front: [1]}

      assert FiFo.drop(%FiFo{rear: [8, 7, 6], front: [1, 2, 3, 4, 5]}, -3) ==
               %FiFo{rear: [5, 4], front: [1, 2, 3]}
    end

    test "drops the whole front and a part from rear" do
      assert FiFo.drop(%FiFo{rear: [8, 7, 6], front: [1, 2, 3, 4, 5]}, 6) ==
               %FiFo{rear: [8], front: [7]}

      assert FiFo.drop(%FiFo{rear: [8, 7, 6], front: [1, 2, 3, 4, 5]}, 7) ==
               %FiFo{rear: [8], front: []}
    end

    test "drops the whole rear and a part from front" do
      assert FiFo.drop(%FiFo{rear: [8, 7, 6], front: [1, 2, 3, 4, 5]}, -6) ==
               %FiFo{rear: [2], front: [1]}

      assert FiFo.drop(%FiFo{rear: [8, 7, 6], front: [1, 2, 3, 4, 5]}, -7) ==
               %FiFo{rear: [], front: [1]}
    end

    test "drops the whole queue from front" do
      assert FiFo.drop(%FiFo{rear: [4, 3], front: [1, 2]}, 4) ==
               %FiFo{rear: [], front: []}

      assert FiFo.drop(%FiFo{rear: [4, 3], front: [1, 2]}, 6) ==
               %FiFo{rear: [], front: []}
    end

    test "drops the whole queue from rear" do
      assert FiFo.drop(%FiFo{rear: [4, 3], front: [1, 2]}, -4) ==
               %FiFo{rear: [], front: []}

      assert FiFo.drop(%FiFo{rear: [4, 3], front: [1, 2]}, -6) ==
               %FiFo{rear: [], front: []}
    end

    test "drops elements from a malformed queue from front" do
      assert FiFo.drop(%FiFo{rear: [3, 2, 1], front: []}, 2) ==
               %FiFo{rear: [3], front: []}

      assert FiFo.drop(%FiFo{rear: [5, 4, 3, 2, 1], front: []}, 2) ==
               %FiFo{rear: [5, 4], front: [3]}

      assert FiFo.drop(%FiFo{rear: [], front: [1, 2, 3]}, 2) ==
               %FiFo{rear: [], front: [3]}

      assert FiFo.drop(%FiFo{rear: [], front: [1, 2, 3, 4, 5]}, 2) ==
               %FiFo{rear: [], front: [3, 4, 5]}
    end

    test "drops elements from a malformed queue from rear" do
      assert FiFo.drop(%FiFo{rear: [3, 2, 1], front: []}, -2) ==
               %FiFo{rear: [1], front: []}

      assert FiFo.drop(%FiFo{rear: [5, 4, 3, 2, 1], front: []}, -2) ==
               %FiFo{rear: [3, 2, 1], front: []}

      assert FiFo.drop(%FiFo{rear: [], front: [1, 2, 3]}, -2) ==
               %FiFo{rear: [], front: [1]}

      assert FiFo.drop(%FiFo{rear: [], front: [1, 2, 3, 4, 5]}, -2) ==
               %FiFo{rear: [3], front: [1, 2]}
    end
  end

  describe "fetch/1" do
    test "with an empty queue" do
      assert FiFo.fetch(%FiFo{}) == :error
    end

    test "with a non-empty queue" do
      assert FiFo.fetch(%FiFo{rear: [1], front: []}) == {:ok, 1}
      assert FiFo.fetch(%FiFo{rear: [], front: [1]}) == {:ok, 1}
      assert FiFo.fetch(%FiFo{rear: [2], front: [1]}) == {:ok, 1}
      assert FiFo.fetch(%FiFo{rear: [3, 2], front: [1]}) == {:ok, 1}
      assert FiFo.fetch(%FiFo{rear: [3], front: [1, 2]}) == {:ok, 1}
      assert FiFo.fetch(%FiFo{rear: [4, 3], front: [1, 2]}) == {:ok, 1}
    end

    test "with a malformed queue" do
      assert FiFo.fetch(%FiFo{rear: [], front: [1, 2]}) == {:ok, 1}
      assert FiFo.fetch(%FiFo{rear: [2, 1], front: []}) == {:ok, 1}
    end
  end

  describe "fetch!/1" do
    test "with an empty queue" do
      assert_raise FiFo.EmptyError, fn ->
        FiFo.fetch!(%FiFo{})
      end
    end

    test "with a non-empty queue" do
      assert FiFo.fetch!(%FiFo{rear: [1], front: []}) == 1
      assert FiFo.fetch!(%FiFo{rear: [], front: [1]}) == 1
      assert FiFo.fetch!(%FiFo{rear: [2], front: [1]}) == 1
      assert FiFo.fetch!(%FiFo{rear: [3, 2], front: [1]}) == 1
      assert FiFo.fetch!(%FiFo{rear: [3], front: [1, 2]}) == 1
      assert FiFo.fetch!(%FiFo{rear: [4, 3], front: [1, 2]}) == 1
    end

    test "with a malformed queue" do
      assert FiFo.fetch!(%FiFo{rear: [], front: [1, 2]}) == 1
      assert FiFo.fetch!(%FiFo{rear: [2, 1], front: []}) == 1
    end
  end

  describe "fetch_reverse/1" do
    test "with an empty queue" do
      assert FiFo.fetch_reverse(%FiFo{}) == :error
    end

    test "with a non-empty queue" do
      assert FiFo.fetch_reverse(%FiFo{rear: [1], front: []}) == {:ok, 1}
      assert FiFo.fetch_reverse(%FiFo{rear: [], front: [1]}) == {:ok, 1}
      assert FiFo.fetch_reverse(%FiFo{rear: [2], front: [1]}) == {:ok, 2}
      assert FiFo.fetch_reverse(%FiFo{rear: [3, 2], front: [1]}) == {:ok, 3}
      assert FiFo.fetch_reverse(%FiFo{rear: [3], front: [1, 2]}) == {:ok, 3}
      assert FiFo.fetch_reverse(%FiFo{rear: [4, 3], front: [1, 2]}) == {:ok, 4}
    end

    test "with a malformed queue" do
      assert FiFo.fetch_reverse(%FiFo{rear: [], front: [1, 2]}) == {:ok, 2}
      assert FiFo.fetch_reverse(%FiFo{rear: [2, 1], front: []}) == {:ok, 2}
    end
  end

  describe "fetch_reverse!/1" do
    test "with an empty queue" do
      assert_raise FiFo.EmptyError, fn ->
        FiFo.fetch_reverse!(%FiFo{})
      end
    end

    test "with a non-empty queue" do
      assert FiFo.fetch_reverse!(%FiFo{rear: [1], front: []}) == 1
      assert FiFo.fetch_reverse!(%FiFo{rear: [], front: [1]}) == 1
      assert FiFo.fetch_reverse!(%FiFo{rear: [2], front: [1]}) == 2
      assert FiFo.fetch_reverse!(%FiFo{rear: [3, 2], front: [1]}) == 3
      assert FiFo.fetch_reverse!(%FiFo{rear: [3], front: [1, 2]}) == 3
      assert FiFo.fetch_reverse!(%FiFo{rear: [4, 3], front: [1, 2]}) == 4
    end

    test "with a malformed queue" do
      assert FiFo.fetch_reverse!(%FiFo{rear: [], front: [1, 2]}) == 2
      assert FiFo.fetch_reverse!(%FiFo{rear: [2, 1], front: []}) == 2
    end
  end

  describe "filter/2" do
    test "removes all elements from front" do
      assert FiFo.filter(%FiFo{rear: [7, 6, 5, 4, 3], front: [1, 2]}, fn x -> x > 2 end) ==
               %FiFo{rear: [7, 6, 5], front: [3, 4]}
    end

    test "removes all elements from rear" do
      assert FiFo.filter(%FiFo{rear: [7, 6, 5, 4, 3], front: [1, 2]}, fn x -> x <= 2 end) ==
               %FiFo{rear: [2], front: [1]}
    end

    test "removes all elements" do
      assert FiFo.filter(%FiFo{rear: [3], front: [1, 2]}, fn x -> x > 20 end) == %FiFo{}
    end

    test "with malformed queue" do
      assert FiFo.filter(%FiFo{rear: [4, 3, 2, 1]}, fn x -> rem(x, 2) == 0 end) ==
               %FiFo{rear: [4], front: [2]}

      assert FiFo.filter(%FiFo{front: [1, 2, 3, 4]}, fn x -> rem(x, 2) == 0 end) ==
               %FiFo{rear: [4], front: [2]}
    end
  end

  describe "get/1" do
    test "with an empty queue" do
      assert FiFo.get(%FiFo{}) == nil
    end

    test "with a non-empty queue" do
      assert FiFo.get(%FiFo{rear: [1], front: []}) == 1
      assert FiFo.get(%FiFo{rear: [], front: [1]}) == 1
      assert FiFo.get(%FiFo{rear: [2], front: [1]}) == 1
      assert FiFo.get(%FiFo{rear: [3, 2], front: [1]}) == 1
      assert FiFo.get(%FiFo{rear: [3], front: [1, 2]}) == 1
      assert FiFo.get(%FiFo{rear: [4, 3], front: [1, 2]}) == 1
    end

    test "with a malformed queue" do
      assert FiFo.get(%FiFo{rear: [], front: [1, 2]}) == 1
      assert FiFo.get(%FiFo{rear: [2, 1], front: []}) == 1
    end
  end

  describe "get_reverse/1" do
    test "with an empty queue" do
      assert FiFo.get_reverse(%FiFo{}) == nil
    end

    test "with a non-empty queue" do
      assert FiFo.get_reverse(%FiFo{rear: [1], front: []}) == 1
      assert FiFo.get_reverse(%FiFo{rear: [], front: [1]}) == 1
      assert FiFo.get_reverse(%FiFo{rear: [2], front: [1]}) == 2
      assert FiFo.get_reverse(%FiFo{rear: [3, 2], front: [1]}) == 3
      assert FiFo.get_reverse(%FiFo{rear: [3], front: [1, 2]}) == 3
      assert FiFo.get_reverse(%FiFo{rear: [4, 3], front: [1, 2]}) == 4
    end

    test "with a malformed queue" do
      assert FiFo.get_reverse(%FiFo{rear: [], front: [1, 2]}) == 2
      assert FiFo.get_reverse(%FiFo{rear: [2, 1], front: []}) == 2
    end
  end

  describe "pop/2" do
    test "with an empty queue" do
      assert FiFo.pop(%FiFo{}) == {:error, %FiFo{}}
    end

    test "with a non-empty queue" do
      assert FiFo.pop(%FiFo{rear: [1], front: []}) ==
               {{:ok, 1}, %FiFo{}}

      assert FiFo.pop(%FiFo{rear: [], front: [1]}) ==
               {{:ok, 1}, %FiFo{}}

      assert FiFo.pop(%FiFo{rear: [2], front: [1]}) ==
               {{:ok, 1}, %FiFo{front: [2]}}

      assert FiFo.pop(%FiFo{rear: [7, 6, 5, 4, 3, 2], front: [1]}) ==
               {{:ok, 1}, %FiFo{rear: [7, 6, 5, 4], front: [2, 3]}}

      assert FiFo.pop(%FiFo{rear: [3], front: [1, 2]}) ==
               {{:ok, 1}, %FiFo{rear: [3], front: [2]}}

      assert FiFo.pop(%FiFo{rear: [4, 3], front: [1, 2]}) ==
               {{:ok, 1}, %FiFo{rear: [4, 3], front: [2]}}
    end

    test "with a malformed queue" do
      assert FiFo.pop(%FiFo{rear: [], front: [1, 2, 3, 4]}) ==
               {{:ok, 1}, %FiFo{rear: [], front: [2, 3, 4]}}

      assert FiFo.pop(%FiFo{rear: [4, 3, 2, 1], front: []}) ==
               {{:ok, 1}, %FiFo{rear: [4, 3, 2], front: []}}
    end
  end

  describe "pop!/2" do
    test "with an empty queue" do
      assert_raise FiFo.EmptyError, fn ->
        FiFo.pop!(%FiFo{})
      end
    end

    test "with a non-empty queue" do
      assert FiFo.pop!(%FiFo{rear: [1], front: []}) ==
               {1, %FiFo{}}

      assert FiFo.pop!(%FiFo{rear: [], front: [1]}) ==
               {1, %FiFo{}}

      assert FiFo.pop!(%FiFo{rear: [2], front: [1]}) ==
               {1, %FiFo{front: [2]}}

      assert FiFo.pop!(%FiFo{rear: [7, 6, 5, 4, 3, 2], front: [1]}) ==
               {1, %FiFo{rear: [7, 6, 5, 4], front: [2, 3]}}

      assert FiFo.pop!(%FiFo{rear: [3], front: [1, 2]}) ==
               {1, %FiFo{rear: [3], front: [2]}}

      assert FiFo.pop!(%FiFo{rear: [4, 3], front: [1, 2]}) ==
               {1, %FiFo{rear: [4, 3], front: [2]}}
    end

    test "with a malformed queue" do
      assert FiFo.pop!(%FiFo{rear: [], front: [1, 2, 3, 4]}) ==
               {1, %FiFo{rear: [], front: [2, 3, 4]}}

      assert FiFo.pop!(%FiFo{rear: [4, 3, 2, 1], front: []}) ==
               {1, %FiFo{rear: [4, 3, 2], front: []}}
    end
  end

  describe "pop_reverse/2" do
    test "with an empty queue" do
      assert FiFo.pop_reverse(%FiFo{}) == {:error, %FiFo{}}
    end

    test "with a non-empty queue" do
      assert FiFo.pop_reverse(%FiFo{rear: [1], front: []}) ==
               {{:ok, 1}, %FiFo{}}

      assert FiFo.pop_reverse(%FiFo{rear: [], front: [1]}) ==
               {{:ok, 1}, %FiFo{}}

      assert FiFo.pop_reverse(%FiFo{rear: [2], front: [1]}) ==
               {{:ok, 2}, %FiFo{front: [1]}}

      assert FiFo.pop_reverse(%FiFo{rear: [7, 6, 5, 4, 3, 2], front: [1]}) ==
               {{:ok, 7}, %FiFo{rear: [6, 5, 4, 3, 2], front: [1]}}

      assert FiFo.pop_reverse(%FiFo{rear: [7], front: [1, 2, 3, 4, 5, 6]}) ==
               {{:ok, 7}, %FiFo{rear: [6, 5], front: [1, 2, 3, 4]}}

      assert FiFo.pop_reverse(%FiFo{rear: [4, 3], front: [1, 2]}) ==
               {{:ok, 4}, %FiFo{rear: [3], front: [1, 2]}}
    end

    test "with a malformed queue" do
      assert FiFo.pop_reverse(%FiFo{rear: [], front: [1, 2, 3, 4]}) ==
               {{:ok, 4}, %FiFo{rear: [], front: [1, 2, 3]}}

      assert FiFo.pop_reverse(%FiFo{rear: [4, 3, 2, 1], front: []}) ==
               {{:ok, 4}, %FiFo{rear: [3, 2, 1], front: []}}
    end
  end

  describe "pop_reverse!/2" do
    test "with an empty queue" do
      assert_raise FiFo.EmptyError, fn ->
        FiFo.pop_reverse!(%FiFo{})
      end
    end

    test "with a non-empty queue" do
      assert FiFo.pop_reverse!(%FiFo{rear: [1], front: []}) ==
               {1, %FiFo{}}

      assert FiFo.pop_reverse!(%FiFo{rear: [], front: [1]}) ==
               {1, %FiFo{}}

      assert FiFo.pop_reverse!(%FiFo{rear: [2], front: [1]}) ==
               {2, %FiFo{front: [1]}}

      assert FiFo.pop_reverse!(%FiFo{rear: [7, 6, 5, 4, 3, 2], front: [1]}) ==
               {7, %FiFo{rear: [6, 5, 4, 3, 2], front: [1]}}

      assert FiFo.pop_reverse!(%FiFo{rear: [3], front: [1, 2]}) ==
               {3, %FiFo{rear: [2], front: [1]}}

      assert FiFo.pop_reverse!(%FiFo{rear: [4, 3], front: [1, 2]}) ==
               {4, %FiFo{rear: [3], front: [1, 2]}}
    end

    test "with a malformed queue" do
      assert FiFo.pop_reverse!(%FiFo{rear: [], front: [1, 2, 3, 4]}) ==
               {4, %FiFo{rear: [], front: [1, 2, 3]}}

      assert FiFo.pop_reverse!(%FiFo{rear: [4, 3, 2, 1], front: []}) ==
               {4, %FiFo{rear: [3, 2, 1], front: []}}
    end
  end

  describe "push/2" do
    test "with an empty queue" do
      assert FiFo.push(%FiFo{}, 1) == %FiFo{rear: [1], front: []}
    end

    test "with a non-empty queue" do
      assert FiFo.push(%FiFo{rear: [1], front: []}, 2) ==
               %FiFo{rear: [2], front: [1]}

      assert FiFo.push(%FiFo{rear: [], front: [1]}, 2) ==
               %FiFo{rear: [2], front: [1]}

      assert FiFo.push(%FiFo{rear: [2], front: [1]}, 3) ==
               %FiFo{rear: [3, 2], front: [1]}

      assert FiFo.push(%FiFo{rear: [3, 2], front: [1]}, 4) ==
               %FiFo{rear: [4, 3, 2], front: [1]}

      assert FiFo.push(%FiFo{rear: [4, 3], front: [1, 2]}, 5) ==
               %FiFo{rear: [5, 4, 3], front: [1, 2]}
    end

    test "with a malformed queue" do
      assert FiFo.push(%FiFo{rear: [], front: [1, 2]}, 3) ==
               %FiFo{rear: [3], front: [1, 2]}

      assert FiFo.push(%FiFo{rear: [2, 1], front: []}, 3) ==
               %FiFo{rear: [3, 2], front: [1]}
    end
  end

  describe "push_reverse/2" do
    test "with an empty queue" do
      assert FiFo.push_reverse(%FiFo{}, 1) == %FiFo{rear: [], front: [1]}
    end

    test "with a non-empty queue" do
      assert FiFo.push_reverse(%FiFo{rear: [1], front: []}, 2) ==
               %FiFo{rear: [1], front: [2]}

      assert FiFo.push_reverse(%FiFo{rear: [], front: [1]}, 2) ==
               %FiFo{rear: [1], front: [2]}

      assert FiFo.push_reverse(%FiFo{rear: [3], front: [2]}, 1) ==
               %FiFo{rear: [3], front: [1, 2]}

      assert FiFo.push_reverse(%FiFo{rear: [4, 3], front: [2]}, 1) ==
               %FiFo{rear: [4, 3], front: [1, 2]}

      assert FiFo.push_reverse(%FiFo{rear: [5, 4], front: [2, 3]}, 1) ==
               %FiFo{rear: [5, 4], front: [1, 2, 3]}
    end

    test "with a malformed queue" do
      assert FiFo.push_reverse(%FiFo{rear: [], front: [2, 3]}, 1) ==
               %FiFo{rear: [], front: [1, 2, 3]}

      assert FiFo.push_reverse(%FiFo{rear: [3, 2], front: []}, 1) ==
               %FiFo{rear: [3, 2], front: [1]}
    end
  end

  describe "reject/2" do
    test "removes all elements from front" do
      assert FiFo.reject(%FiFo{rear: [7, 6, 5, 4, 3], front: [1, 2]}, fn x -> x <= 2 end) ==
               %FiFo{rear: [7, 6, 5], front: [3, 4]}
    end

    test "removes all elements from rear" do
      assert FiFo.reject(%FiFo{rear: [7, 6, 5, 4, 3], front: [1, 2]}, fn x -> x > 2 end) ==
               %FiFo{rear: [2], front: [1]}
    end

    test "removes all elements" do
      assert FiFo.reject(%FiFo{rear: [3], front: [1, 2]}, fn x -> x < 20 end) == %FiFo{}
    end

    test "with malformed queue" do
      assert FiFo.reject(%FiFo{rear: [4, 3, 2, 1]}, fn x -> rem(x, 2) != 0 end) ==
               %FiFo{rear: [4], front: [2]}

      assert FiFo.reject(%FiFo{front: [1, 2, 3, 4]}, fn x -> rem(x, 2) != 0 end) ==
               %FiFo{rear: [4], front: [2]}
    end
  end

  describe "take" do
    setup do
      %{queue: %FiFo{rear: [10, 9, 8, 7, 6], front: [1, 2, 3, 4, 5]}}
    end

    test "take some from front", %{queue: queue} do
      assert FiFo.take(queue, 3) == {[1, 2, 3], %FiFo{rear: [10, 9, 8, 7, 6], front: [4, 5]}}
    end

    test "take all from front", %{queue: queue} do
      assert FiFo.take(queue, 5) == {[1, 2, 3, 4, 5], %FiFo{rear: [10, 9, 8], front: [6, 7]}}
    end

    test "take all from front and some from rear", %{queue: queue} do
      assert FiFo.take(queue, 7) == {[1, 2, 3, 4, 5, 6, 7], %FiFo{rear: [10, 9], front: [8]}}
    end

    test "take all", %{queue: queue} do
      assert FiFo.take(queue, 10) == {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10], %FiFo{}}
      assert FiFo.take(queue, 15) == {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10], %FiFo{}}
      assert FiFo.take(queue, -10) == {[10, 9, 8, 7, 6, 5, 4, 3, 2, 1], %FiFo{}}
      assert FiFo.take(queue, -15) == {[10, 9, 8, 7, 6, 5, 4, 3, 2, 1], %FiFo{}}
    end

    test "take some from rear", %{queue: queue} do
      assert FiFo.take(queue, -3) == {[10, 9, 8], %FiFo{rear: [7, 6], front: [1, 2, 3, 4, 5]}}
    end

    test "take all from rear", %{queue: queue} do
      assert FiFo.take(queue, -5) == {[10, 9, 8, 7, 6], %FiFo{rear: [5, 4], front: [1, 2, 3]}}
    end

    test "take all from rear and some from front", %{queue: queue} do
      assert FiFo.take(queue, -7) == {[10, 9, 8, 7, 6, 5, 4], %FiFo{rear: [3], front: [1, 2]}}
    end
  end

  describe "enumerable" do
    test "slice" do
      assert Enum.slice(FiFo.from_range(1..6), 2, 4) == [3, 4, 5, 6]
    end

    test "reduce" do
      assert Enum.reduce(FiFo.from_range(1..3), 0, fn x, acc -> x + acc end) == 6
    end
  end

  test "Enum.into/2" do
    assert Enum.into([1, 2, 3], FiFo.new()) == FiFo.from_range(1..3)
  end
end
