defmodule EDGARTest do
  use ExUnit.Case
  doctest EDGAR

  test "parsing form4" do
    {:ok, file} = File.read("test/test_data/form4.xml")

    {:ok, parsed} = EDGAR.Native.parse_form4(file)

    IO.inspect(parsed)
  end

  test "parsing xbrl" do
    {:ok, file} = File.read("test/test_data/msft.xml")

    {:ok, parsed} = EDGAR.Native.parse_xbrl(file)

    IO.inspect(parsed)
  end
end
