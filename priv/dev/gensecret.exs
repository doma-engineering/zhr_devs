#!/usr/bin/env elixir

defmodule Gensecret do
  def main(_args) do
    # Secure secret token generator, just like in phoenix!
    length = 64
    :crypto.strong_rand_bytes(length) |> Base.encode64(padding: false) |> binary_part(0, length)
  end
end

Gensecret.main([]) |> IO.puts()
