defmodule ArrayTest do
  use ExUnit.Case

  # doctest Dict
  doctest Enum

  doctest Access
  doctest Collectable
  doctest Enumerable

  defp dict_impl, do: Array
end
