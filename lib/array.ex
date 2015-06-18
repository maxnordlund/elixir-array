defmodule Array do
  use Dict

  @moduledoc """
  An array that implements Dict. Allows random access with O(1) time complexity.
  """

  @opaque t :: %Array{}
  @derive [Access, Collectable]
  defstruct []

  def new do
    %Array{}
  end

  def delete(array, index) do
    if has_key? array, index do
      case map_size(array) do
        1 -> %Array{}
        2 -> Dict.put %Array{}, 0, array[abs(index-1)] # index E {0,1}
        _ ->
          # Delete the value at index
          array = Dict.delete array, index
          # Copy down all values above the index
          array = do_slice array, array, index+1, index, map_size(array)
          # Delete the last index, sice it is a duplicate
          array = Dict.delete array, map_size(array)

          array
      end
    else
      array
    end
  end

  def drop(array, count) when is_integer(count) and count < 0 do
    take array, map_size(array)+count
  end
  def drop(array, count) when is_integer(count) do
    slice array, count, map_size(array)
  end

  def fetch(array, index) do
    if has_key? array, index do
      {:ok, array[index]}
    else
      :error
    end
  end

  def has_key?(array, index) do
    assert_valid_index(index)
    Dict.has_key?(array, index)
  end

  def put(array, index, value) do
    assert_valid_index(index)
    Dict.put(array, index, value)
  end

  def reduce(array, acc, fun), do: do_reduce(array, 0, acc, fun)

  defp do_reduce(_arr, _index, {:halt,    acc}, _fn), do: {:halted, acc}
  defp do_reduce(array, index, {:suspend, acc}, fun), do: {:suspended, acc, &do_reduce(array, index, &1, fun)}
  defp do_reduce(array, index, {:count,   acc}, _fn)  when index >= map_size(array), do: {:done, acc}
  defp do_reduce(array, index, {:count,   acc}, fun), do: do_reduce(array, index+1, fun.(array[index], acc), fun)

  def size(array), do: map_size(array)

  def slice(array, %Range{first: first, last: last}) do
    length = size(array)
    if first < 0 do
      first = length+first
    end
    if last < 0 do
      last = length+last
    end

    if first in 0..length and last > (first+1) do
      slice(array, first, last-first)
    else
      %Array{}
    end
  end

  def slice(array, start, count) do
    assert_valid_index(start)
    assert_valid_index(count)
    do_slice(array, %{}, start, 0, count)
  end

  defp do_slice(_arr, acc, _src, _dst, 0), do: acc
  defp do_slice(array, acc, src, _dst, _count) when src >= map_size(array), do: acc
  defp do_slice(array, acc, src, dst, count) do
    do_slice(array, Dict.put(acc, dst, array[src]), src+1, dst+1, count-1)
  end

  def take(array, count) when is_integer(count) and count < 0 do
    drop array, map_size(array)+count
  end
  def take(array, count) when is_integer(count) do
    slice array, 0, count
  end

  defp assert_valid_index(index) when is_integer(index) and index >= 0, do: :ok
  defp assert_valid_index(index) do
    raise ArgumentError, "index must be a non negative integer, got #{index}"
  end

  defimpl Enumerable, for: Array do
    def count(array),            do: {:ok, map_size(array)}
    def member?(_array, _value), do: {:error, __MODULE__}
    def reduce(array, acc, fun), do: Array.reduce(array, acc, fun)
  end
end
