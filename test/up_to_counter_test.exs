defmodule UpToCounterTest do
  use ExUnit.Case
  use ExUnitProperties

  property "m can't be more or equal to i with including? - false" do
    check all(m <- integer(), i <- integer()) do
      counter = UpToCounter.new(m: m, i: i, including?: false)

      %UpToCounter{m: m, i: i} = UpToCounter.increment(counter)

      refute i >= m
    end
  end

  property "m can't be more than i with including? - true" do
    check all(m <- integer(), i <- integer()) do
      counter = UpToCounter.new(m: m, i: i, including?: true)

      %UpToCounter{m: m, i: i} = UpToCounter.increment(counter)

      refute i > m
    end
  end
end
