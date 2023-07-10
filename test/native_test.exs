defmodule EDGARTest do
  use ExUnit.Case
  doctest EDGAR

  test "check form3" do
    {:ok, file} = File.read("test/test_data/form3.xml")

    {:ok, filing} = EDGAR.Native.parse_ownership_form(file)

    assert filing.document_type == "3"
  end

  test "parsing form3" do
    {:ok, file} = File.read("test/test_data/form3.xml")

    {:ok, filing} = EDGAR.Native.parse_ownership_form(file)

    IO.inspect(filing)
  end

  test "check form4" do
    {:ok, file} = File.read("test/test_data/form4.xml")

    {:ok, filing} = EDGAR.Native.parse_ownership_form(file)

    assert filing.document_type == "4"
  end

  test "parsing form4" do
    {:ok, file} = File.read("test/test_data/form4.xml")

    {:ok, filing} = EDGAR.Native.parse_ownership_form(file)

    IO.inspect(filing)
  end
end
