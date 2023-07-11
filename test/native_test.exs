defmodule EDGARTest.Native do
  use ExUnit.Case
  doctest EDGAR

  test "parsing form13f doc native" do
    {:ok, file} = File.read("test/test_data/form13f_doc.xml")
    {:ok, filing} = EDGAR.Native.parse_13f_document(file)
    assert filing.header_data.submission_type == "13F-HR"
  end

  test "parsing form13f table native" do
    {:ok, file} = File.read("test/test_data/form13f_table.xml")
    {:ok, filing} = EDGAR.Native.parse_13f_table(file)
    assert filing.entries > 0
  end

  test "parsing form3 native" do
    {:ok, file} = File.read("test/test_data/form3.xml")
    {:ok, filing} = EDGAR.Native.parse_ownership_form(file)
    assert filing.document_type == "3"
  end

  test "parsing form4 native" do
    {:ok, file} = File.read("test/test_data/form4.xml")
    {:ok, filing} = EDGAR.Native.parse_ownership_form(file)
    assert filing.document_type == "4"
  end

  test "parsing form4a native" do
    {:ok, file} = File.read("test/test_data/form4a.xml")
    {:ok, filing} = EDGAR.Native.parse_ownership_form(file)
    assert filing.document_type == "4/A"
  end
end
