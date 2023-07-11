defmodule EDGARTest.Parser do
  use ExUnit.Case
  doctest EDGAR

  test "parsing doc13f_ctr" do
    {:ok, file} = File.read("test/test_data/doc13f_ctr.xml")
    {:ok, filing} = EDGAR.Native.parse_13f_document(file)
    assert filing.header_data.submission_type == "13F-CTR"
  end

  test "parsing form13f_ctra" do
    {:ok, file} = File.read("test/test_data/doc13f_ctra.xml")
    {:ok, filing} = EDGAR.Native.parse_13f_document(file)
    assert filing.header_data.submission_type == "13F-CTR/A"
  end

  test "parsing form13f_hr" do
    {:ok, file} = File.read("test/test_data/doc13f_hr.xml")
    {:ok, filing} = EDGAR.Native.parse_13f_document(file)
    assert filing.header_data.submission_type == "13F-HR"
  end

  test "parsing form13f_hra" do
    {:ok, file} = File.read("test/test_data/doc13f_hra.xml")
    {:ok, filing} = EDGAR.Native.parse_13f_document(file)
    assert filing.header_data.submission_type == "13F-HR/A"
  end

  test "parsing form13f_nt" do
    {:ok, file} = File.read("test/test_data/doc13f_nt.xml")
    {:ok, filing} = EDGAR.Native.parse_13f_document(file)
    assert filing.header_data.submission_type == "13F-NT"
  end

  test "parsing form13f_nta" do
    {:ok, file} = File.read("test/test_data/doc13f_nta.xml")
    {:ok, filing} = EDGAR.Native.parse_13f_document(file)
    assert filing.header_data.submission_type == "13F-NT/A"
  end

  test "parsing doc13f_table" do
    {:ok, file} = File.read("test/test_data/doc13f_table.xml")
    {:ok, filing} = EDGAR.Native.parse_13f_table(file)
    assert filing.entries > 0
  end

  test "parsing doc3" do
    {:ok, file} = File.read("test/test_data/doc3.xml")
    {:ok, filing} = EDGAR.Native.parse_ownership_form(file)
    assert filing.document_type == "3"
  end

  test "parsing doc3a" do
    {:ok, file} = File.read("test/test_data/doc3a.xml")
    {:ok, filing} = EDGAR.Native.parse_ownership_form(file)
    assert filing.document_type == "3/A"
  end

  test "parsing doc4" do
    {:ok, file} = File.read("test/test_data/doc4.xml")
    {:ok, filing} = EDGAR.Native.parse_ownership_form(file)
    assert filing.document_type == "4"
  end

  test "parsing doc4a" do
    {:ok, file} = File.read("test/test_data/doc4a.xml")
    {:ok, filing} = EDGAR.Native.parse_ownership_form(file)
    assert filing.document_type == "4/A"
  end

  test "parsing doc5" do
    {:ok, file} = File.read("test/test_data/doc5.xml")
    {:ok, filing} = EDGAR.Native.parse_ownership_form(file)
    assert filing.document_type == "5"
  end

  test "parsing doc5a" do
    {:ok, file} = File.read("test/test_data/doc5a.xml")
    {:ok, filing} = EDGAR.Native.parse_ownership_form(file)
    assert filing.document_type == "5/A"
  end
end
