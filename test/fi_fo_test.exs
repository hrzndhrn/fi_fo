defmodule FiFoTest do
  use ExUnit.Case

  import Prove

  doctest FiFo

  batch "new/0 create an empty queue" do
    prove FiFo.new() == {[], []}
  end

  describe "new/1" do
    batch "creates a queue from a list" do
      prove FiFo.new([]) == {[], []}
      prove FiFo.new([1]) == {[1], []}
      prove FiFo.new([1, 2]) == {[2], [1]}
      prove FiFo.new([1, 2, 3]) == {[3, 2], [1]}
      prove FiFo.new([1, 2, 3, 4]) == {[4, 3], [1, 2]}
    end

    batch "creates a queue form a range" do
      prove FiFo.new(1..1) == {[1], []}
      prove FiFo.new(1..2) == {[2], [1]}
      prove FiFo.new(1..3) == {[3, 2], [1]}
      prove FiFo.new(1..4) == {[4, 3], [1, 2]}
    end
  end

  describe "to_list/1" do
    batch "returns the list for a queue" do
      prove [] |> FiFo.new() |> FiFo.to_list() == []
      prove [1] |> FiFo.new() |> FiFo.to_list() == [1]
      prove [1, 2] |> FiFo.new() |> FiFo.to_list() == [1, 2]
      prove [1, 2, 3] |> FiFo.new() |> FiFo.to_list() == [1, 2, 3]
      prove [1, 2, 3, 4] |> FiFo.new() |> FiFo.to_list() == [1, 2, 3, 4]

      prove FiFo.to_list({[], [1, 2]}) == [1, 2]
      prove FiFo.to_list({[2, 1], []}) == [1, 2]
    end
  end

  describe "concat/1" do
    batch "with an empty list" do
      prove FiFo.concat([]) == {[], []}
    end

    batch "with one queue" do
      prove FiFo.concat([FiFo.new(1..10)]) == FiFo.new(1..10)
    end

    batch "with a list of queues" do
      prove FiFo.concat([
              FiFo.new(1..3),
              FiFo.new(4..10),
              FiFo.new(11..15)
            ]) == FiFo.new(1..15)
    end
  end

  describe "concat/2" do
    batch "with two queues" do
      prove FiFo.concat(FiFo.new(1..5), FiFo.new(6..10)) == FiFo.new(1..10)
    end
  end

  describe "drop/2" do
    batch "with an empty queue" do
      prove FiFo.drop({[], []}, 2) == {[], []}
      prove FiFo.drop({[], []}, 0) == {[], []}
      prove FiFo.drop({[], []}, -2) == {[], []}
    end

    batch "drops a part from front" do
      prove FiFo.drop({[8, 7, 6], [1, 2, 3, 4, 5]}, 3) == {[8, 7, 6], [4, 5]}
    end

    batch "drops a part from rear" do
      prove FiFo.drop({[8, 7, 6], [1, 2, 3, 4, 5]}, -2) == {[6], [1, 2, 3, 4, 5]}
    end

    batch "drops the whole front" do
      prove FiFo.drop({[2], [1]}, 1) == {[2], []}
      prove FiFo.drop({[8, 7, 6, 5], [1, 2, 3, 4]}, 4) == {[8, 7], [5, 6]}
    end

    batch "drops the whole rear" do
      prove FiFo.drop({[2], [1]}, -1) == {[], [1]}
      prove FiFo.drop({[8, 7, 6], [1, 2, 3, 4, 5]}, -3) == {[5, 4, 3], [1, 2]}
    end

    batch "drops the whole front and a part from rear" do
      prove FiFo.drop({[8, 7, 6], [1, 2, 3, 4, 5]}, 6) == {[8], [7]}
      prove FiFo.drop({[8, 7, 6], [1, 2, 3, 4, 5]}, 7) == {[8], []}
    end

    batch "drops the whole rear and a part from front" do
      prove FiFo.drop({[8, 7, 6], [1, 2, 3, 4, 5]}, -6) == {[2], [1]}
      prove FiFo.drop({[8, 7, 6], [1, 2, 3, 4, 5]}, -7) == {[], [1]}
    end

    batch "drops the whole queue from front" do
      prove FiFo.drop({[4, 3], [1, 2]}, 4) == {[], []}
      prove FiFo.drop({[4, 3], [1, 2]}, 6) == {[], []}
    end

    batch "drops the whole queue from rear" do
      prove FiFo.drop({[4, 3], [1, 2]}, -4) == {[], []}
      prove FiFo.drop({[4, 3], [1, 2]}, -6) == {[], []}
    end

    batch "drops elements from a malformed queue from front" do
      prove FiFo.drop({[3, 2, 1], []}, 2) == {[3], []}
      prove FiFo.drop({[5, 4, 3, 2, 1], []}, 2) == {[5, 4], [3]}
      prove FiFo.drop({[], [1, 2, 3]}, 2) == {[], [3]}
      prove FiFo.drop({[], [1, 2, 3, 4, 5]}, 2) == {[], [3, 4, 5]}
    end

    batch "drops elements from a malformed queue from rear" do
      prove FiFo.drop({[3, 2, 1], []}, -2) == {[1], []}
      prove FiFo.drop({[5, 4, 3, 2, 1], []}, -2) == {[3, 2, 1], []}
      prove FiFo.drop({[], [1, 2, 3]}, -2) == {[], [1]}
      prove FiFo.drop({[], [1, 2, 3, 4, 5]}, -2) == {[3], [1, 2]}
    end
  end

  describe "empty?/1" do
    batch "returns true for an empty queue" do
      prove [] |> FiFo.new() |> FiFo.empty?() == true
      prove [1] |> FiFo.new() |> FiFo.empty?() == false
    end
  end

  describe "fetch/1" do
    batch "with an empty queue" do
      prove FiFo.fetch({[], []}) == {:error, {[], []}}
    end

    batch "with a non-empty queue" do
      prove FiFo.fetch({[1], []}) == {{:ok, 1}, {[], []}}
      prove FiFo.fetch({[], [1]}) == {{:ok, 1}, {[], []}}
      prove FiFo.fetch({[2], [1]}) == {{:ok, 1}, {[2], []}}
      prove FiFo.fetch({[3, 2], [1]}) == {{:ok, 1}, {[3], [2]}}
      prove FiFo.fetch({[3], [1, 2]}) == {{:ok, 1}, {[3], [2]}}
      prove FiFo.fetch({[4, 3], [1, 2]}) == {{:ok, 1}, {[4, 3], [2]}}
    end

    batch "with a malformed queue" do
      prove FiFo.fetch({[], [1, 2]}) == {{:ok, 1}, {[2], []}}
      prove FiFo.fetch({[2, 1], []}) == {{:ok, 1}, {[2], []}}
    end
  end

  describe "fetch!/1" do
    batch "from a queue" do
      prove FiFo.fetch!({[2], [1]}) == {1, {[2], []}}
    end

    test "raises an error for an empty queue" do
      assert_raise FiFo.EmptyError, "empty queue", fn ->
        FiFo.fetch!(FiFo.new())
      end
    end
  end

  describe "fetch_reverse/1" do
    batch "with an empty queue" do
      prove FiFo.fetch_reverse({[], []}) == {:error, {[], []}}
    end

    batch "with a non-empty queue" do
      prove FiFo.fetch_reverse({[1], []}) == {{:ok, 1}, {[], []}}
      prove FiFo.fetch_reverse({[], [1]}) == {{:ok, 1}, {[], []}}
      prove FiFo.fetch_reverse({[2], [1]}) == {{:ok, 2}, {[1], []}}
      prove FiFo.fetch_reverse({[3, 2], [1]}) == {{:ok, 3}, {[2], [1]}}
      prove FiFo.fetch_reverse({[3], [1, 2]}) == {{:ok, 3}, {[2], [1]}}
      prove FiFo.fetch_reverse({[4, 3], [1, 2]}) == {{:ok, 4}, {[3], [1, 2]}}
    end

    batch "with a malformed queue" do
      prove FiFo.fetch_reverse({[], [1, 2]}) == {{:ok, 2}, {[], [1]}}
      prove FiFo.fetch_reverse({[2, 1], []}) == {{:ok, 2}, {[1], []}}
    end
  end

  describe "fetch_reverse!/1" do
    batch "from a queue" do
      prove FiFo.fetch_reverse!({[3, 2], [1]}) == {3, {[2], [1]}}
    end

    test "raises an error for an empty queue" do
      assert_raise FiFo.EmptyError, "empty queue", fn ->
        FiFo.fetch_reverse!(FiFo.new())
      end
    end
  end

  describe "filter/2" do
    batch "filter a queue" do
      prove FiFo.filter({[7, 6, 5, 4, 3], [1, 2, 3, 4]}, fn x -> x > 3 end) == {[7, 6, 5, 4], [4]}
    end

    batch "removes all elements from front" do
      prove FiFo.filter({[7, 6, 5, 4, 3], [1, 2]}, fn x -> x > 2 end) == {[7, 6], [3, 4, 5]}
    end

    batch "removes all elements from rear" do
      prove FiFo.filter({[7, 6, 5, 4, 3], [1, 2]}, fn x -> x <= 2 end) == {[2], [1]}
    end

    batch "removes all elements" do
      prove FiFo.filter({[3], [1, 2]}, fn x -> x > 20 end) == {[], []}
    end

    batch "with malformed queue" do
      prove FiFo.filter({[4, 3, 2, 1], []}, fn x -> rem(x, 2) == 0 end) == {[4], [2]}
    end
  end

  describe "get/1" do
    batch "with an empty queue" do
      prove FiFo.get({[], []}) == {nil, {[], []}}
      prove FiFo.get({[], []}, :empty) == {:empty, {[], []}}
    end

    batch "with a non-empty queue" do
      prove FiFo.get({[1], []}) == {1, {[], []}}
      prove FiFo.get({[], [1]}) == {1, {[], []}}
      prove FiFo.get({[2], [1]}) == {1, {[2], []}}
      prove FiFo.get({[3, 2], [1]}) == {1, {[3], [2]}}
      prove FiFo.get({[3], [1, 2]}) == {1, {[3], [2]}}
      prove FiFo.get({[4, 3], [1, 2]}) == {1, {[4, 3], [2]}}
    end

    batch "with a malformed queue" do
      prove FiFo.get({[], [1, 2]}) == {1, {[2], []}}
      prove FiFo.get({[2, 1], []}) == {1, {[2], []}}
    end
  end

  describe "get_reverse/1" do
    batch "with an empty queue" do
      prove FiFo.get_reverse({[], []}) == {nil, {[], []}}
      prove FiFo.get_reverse({[], []}, :empty) == {:empty, {[], []}}
    end

    batch "with a non-empty queue" do
      prove FiFo.get_reverse({[1], []}) == {1, {[], []}}
      prove FiFo.get_reverse({[], [1]}) == {1, {[], []}}
      prove FiFo.get_reverse({[2], [1]}) == {2, {[1], []}}
      prove FiFo.get_reverse({[3, 2], [1]}) == {3, {[2], [1]}}
      prove FiFo.get_reverse({[3], [1, 2]}) == {3, {[2], [1]}}
      prove FiFo.get_reverse({[4, 3], [1, 2]}) == {4, {[3], [1, 2]}}
    end

    batch "with a malformed queue" do
      prove FiFo.get_reverse({[], [1, 2]}) == {2, {[], [1]}}
      prove FiFo.get_reverse({[2, 1], []}) == {2, {[1], []}}
    end
  end

  describe "map/2" do
    batch "maps the queue" do
      prove FiFo.map({[4, 3], [1, 2]}, fn value -> value + 1 end) == {[5, 4], [2, 3]}
    end
  end

  describe "member?/2" do
    batch "returns true if the given value is member of the queue" do
      prove FiFo.member?({[4, 3], [1, 2]}, 2) == true
      prove FiFo.member?({[4, 3], [1, 2]}, 666) == false
    end
  end

  describe "push/2" do
    batch "with an empty queue" do
      prove FiFo.push({[], []}, [1, 2, 3]) == {[3, 2], [1]}
    end

    batch "with a non-empty queue" do
      prove FiFo.push({[1], []}, [2, 3]) == {[3], [1, 2]}
      prove FiFo.push({[], [1]}, [2, 3]) == {[3, 2], [1]}
      prove FiFo.push({[2], [1]}, [3, 4]) == {[4, 3, 2], [1]}
      prove FiFo.push({[3, 2], [1]}, [4, 5]) == {[5, 4, 3, 2], [1]}
      prove FiFo.push({[4, 3], [1, 2]}, [5, 6, 7]) == {[7, 6, 5, 4, 3], [1, 2]}
    end

    batch "with a malformed queue" do
      prove FiFo.push({[], [1, 2]}, [3, 4]) == {[4, 3], [1, 2]}
      prove FiFo.push({[2, 1], []}, [3, 4]) == {[4, 3, 2], [1]}
    end
  end

  describe "push_reverse/2" do
    batch "with an empty queue" do
      prove FiFo.push_reverse({[], []}, [1, 2, 3]) == {[3, 2], [1]}
    end

    batch "with a non-empty queue" do
      prove FiFo.push_reverse({[3], []}, [1, 2]) == {[3], [1, 2]}
      prove FiFo.push_reverse({[], [3]}, [1, 2]) == {[3], [1, 2]}
      prove FiFo.push_reverse({[4], [3]}, [1, 2]) == {[4], [1, 2, 3]}
      prove FiFo.push_reverse({[5, 4], [3]}, [1, 2]) == {[5, 4], [1, 2, 3]}
    end

    batch "with a malformed queue" do
      prove FiFo.push_reverse({[], [3, 4]}, [1, 2]) == {[4], [1, 2, 3]}
      prove FiFo.push_reverse({[4, 3], []}, [1, 2]) == {[4, 3], [1, 2]}
    end
  end

  describe "reject/2" do
    batch "removes all elements from front" do
      prove FiFo.reject({[7, 6, 5, 4, 3], [1, 2]}, fn x -> x <= 2 end) == {[7, 6], [3, 4, 5]}
    end

    batch "removes all elements from rear" do
      prove FiFo.reject({[7, 6, 5, 4, 3], [1, 2]}, fn x -> x > 2 end) == {[2], [1]}
    end

    batch "removes all elements" do
      prove FiFo.reject({[3], [1, 2]}, fn x -> x < 20 end) == {[], []}
    end

    batch "with malformed queue" do
      prove FiFo.reject({[4, 3, 2, 1], []}, fn x -> rem(x, 2) != 0 end) == {[4], [2]}
      prove FiFo.reject({[], [1, 2, 3, 4]}, fn x -> rem(x, 2) != 0 end) == {[4], [2]}
    end
  end

  describe "put/2" do
    batch "puts a value to a queue" do
      prove FiFo.put({[], []}, 1) == {[1], []}
      prove FiFo.put({[1], []}, 2) == {[2], [1]}
      prove FiFo.put({[2], [1]}, 3) == {[3, 2], [1]}
      prove FiFo.put({[3, 2], [1]}, 4) == {[4, 3, 2], [1]}

      prove FiFo.put({[], [1, 2, 3]}, 4) == {[4], [1, 2, 3]}

      prove FiFo.put({[2, 1], []}, 3) == {[3, 2], [1]}
      prove FiFo.put({[3, 2, 1], []}, 4) == {[4, 3, 2], [1]}
    end
  end

  describe "put_reverse/2" do
    batch "puts a value to a queue" do
      prove FiFo.put_reverse({[], []}, 4) == {[], [4]}
      prove FiFo.put_reverse({[], [4]}, 3) == {[4], [3]}
      prove FiFo.put_reverse({[4], [3]}, 2) == {[4], [2, 3]}
      prove FiFo.put_reverse({[4], [2, 3]}, 1) == {[4], [1, 2, 3]}

      prove FiFo.put_reverse({[4, 3, 2], []}, 1) == {[4, 3, 2], [1]}

      prove FiFo.put_reverse({[], [2, 3]}, 1) == {[3], [1, 2]}
      prove FiFo.put_reverse({[], [2, 3, 4]}, 1) == {[4, 3], [1, 2]}
    end
  end

  describe "take/2" do
    batch "from an empty queue" do
      prove FiFo.take({[], []}, 0) == {[], {[], []}}
      prove FiFo.take({[], []}, 10) == {[], {[], []}}
    end

    batch "from a queue" do
      prove FiFo.take({[4, 3], [1, 2]}, 0) == {[], {[4, 3], [1, 2]}}
      prove FiFo.take({[4, 3], [1, 2]}, 1) == {[1], {[4, 3], [2]}}
      prove FiFo.take({[4, 3], [1, 2]}, 2) == {[1, 2], {[4], [3]}}
      prove FiFo.take({[4, 3], [1, 2]}, 3) == {[1, 2, 3], {[4], []}}
      prove FiFo.take({[4, 3], [1, 2]}, 4) == {[1, 2, 3, 4], {[], []}}
      prove FiFo.take({[4, 3], [1, 2]}, 5) == {[1, 2, 3, 4], {[], []}}
      prove FiFo.take({[4, 3], [1, 2]}, -1) == {[4], {[3], [1, 2]}}
      prove FiFo.take({[4, 3], [1, 2]}, -2) == {[4, 3], {[2], [1]}}
      prove FiFo.take({[4, 3], [1, 2]}, -3) == {[4, 3, 2], {[], [1]}}
      prove FiFo.take({[4, 3], [1, 2]}, -4) == {[4, 3, 2, 1], {[], []}}
      prove FiFo.take({[4, 3], [1, 2]}, -5) == {[4, 3, 2, 1], {[], []}}
    end

    batch "from a malformed queue" do
      prove FiFo.take({[4, 3, 2, 1], []}, 2) == {[1, 2], {[4], [3]}}
      prove FiFo.take({[4, 3, 2, 1], []}, -2) == {[4, 3], {[2], [1]}}
      prove FiFo.take({[], [1, 2, 3, 4]}, 2) == {[1, 2], {[4], [3]}}
      prove FiFo.take({[], [1, 2, 3, 4]}, -2) == {[4, 3], {[2], [1]}}

      prove FiFo.take({[], [1, 2, 3, 4]}, 4) == {[1, 2, 3, 4], {[], []}}
      prove FiFo.take({[4, 3, 2, 1], []}, -4) == {[4, 3, 2, 1], {[], []}}
    end
  end

  describe "peek/2" do
    batch "in an empty queue" do
      prove FiFo.peek({[], []}) == nil
      prove FiFo.peek({[], []}, :empty) == :empty
    end

    batch "in a queue" do
      prove FiFo.peek({[1], []}) == 1
      prove FiFo.peek({[], [1]}) == 1
      prove FiFo.peek({[3, 2], [1]}) == 1
    end

    batch "in a malformed queue" do
      prove FiFo.peek({[3, 2, 1], []}) == 1
      prove FiFo.peek({[], [1, 2, 3]}) == 1
    end
  end

  describe "peek_reverse/2" do
    batch "in an empty queue" do
      prove FiFo.peek_reverse({[], []}) == nil
      prove FiFo.peek_reverse({[], []}, :empty) == :empty
    end

    batch "in a queue" do
      prove FiFo.peek_reverse({[1], []}) == 1
      prove FiFo.peek_reverse({[], [1]}) == 1
      prove FiFo.peek_reverse({[4], [1, 2, 3]}) == 4
    end

    batch "in a malformed queue" do
      prove FiFo.peek_reverse({[3, 2, 1], []}) == 3
      prove FiFo.peek_reverse({[], [1, 2, 3]}) == 3
    end
  end

  describe "all?/2" do
    batch "in queue" do
      prove FiFo.all?({[], []}, fn x -> x > 0 end) == true
      prove FiFo.all?({[2, 1], []}, fn x -> x > 0 end) == true
      prove FiFo.all?({[], [1, 2]}, fn x -> x > 0 end) == true
      prove FiFo.all?({[4, 3], [1, 2]}, fn x -> x > 0 end) == true
      prove FiFo.all?({[4, -3], [1, 2]}, fn x -> x > 0 end) == false
    end
  end

  describe "any?/2" do
    batch "in queue" do
      prove FiFo.any?({[], []}, fn x -> x < 0 end) == false
      prove FiFo.any?({[2, 1], []}, fn x -> x < 0 end) == false
      prove FiFo.any?({[], [1, 2]}, fn x -> x < 0 end) == false
      prove FiFo.any?({[4, 3], [1, 2]}, fn x -> x < 0 end) == false
      prove FiFo.any?({[4, -3], [1, 2]}, fn x -> x < 0 end) == true
    end
  end
end
