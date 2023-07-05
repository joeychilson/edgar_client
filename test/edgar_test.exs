defmodule EDGARTest do
  use ExUnit.Case
  doctest EDGAR

  test "entity directory found" do
    entity_directory = EDGAR.entity_directory("320193")
    assert {:ok, entity_directory} = entity_directory
    assert entity_directory["directory"]["name"] == "/Archives/edgar/data/320193"
  end

  test "entity directory not found" do
    entity_directory = EDGAR.entity_directory("1")
    assert {:error, :not_found} = entity_directory
  end

  test "filing directory found" do
    filing_directory = EDGAR.filing_directory("320193", "000032019320000010")
    assert {:ok, filing_directory} = filing_directory

    assert filing_directory["directory"]["name"] ==
             "/Archives/edgar/data/320193/000032019320000010"
  end

  test "filing directory not found" do
    filing_directory = EDGAR.filing_directory("1", "1")
    assert {:error, :not_found} = filing_directory
  end

  test "company tickers found" do
    company_tickers = EDGAR.company_tickers()
    assert {:ok, company_tickers} = company_tickers
    assert Enum.count(company_tickers) > 0
  end

  test "cik for ticker found" do
    cik = EDGAR.cik_for_ticker("AAPL")
    assert {:ok, cik} = cik
    assert cik == "320193"
  end

  test "cik for ticker not found" do
    cik = EDGAR.cik_for_ticker("1")
    assert {:error, :not_found} = cik
  end

  test "submissions found" do
    submissions = EDGAR.submissions("320193")
    assert {:ok, submissions} = submissions
    assert submissions["cik"] == "320193"
  end

  test "submissions not found" do
    submissions = EDGAR.submissions("1")
    assert {:error, :not_found} = submissions
  end

  test "company facts found" do
    company_facts = EDGAR.company_facts("320193")
    assert {:ok, company_facts} = company_facts
    assert company_facts["cik"] == 320_193
  end

  test "company facts not found" do
    company_facts = EDGAR.company_facts("1")
    assert {:error, :not_found} = company_facts
  end

  test "company concept found" do
    company_concept = EDGAR.company_concept("320193", "us-gaap", "AccountsPayableCurrent")
    assert {:ok, company_concept} = company_concept
    assert company_concept["cik"] == 320_193
  end

  test "company concept not found" do
    company_concept = EDGAR.company_concept("1", "us-gaap", "AccountsPayableCurrent")
    assert {:error, :not_found} = company_concept
  end

  test "frames found" do
    frames = EDGAR.frames("us-gaap", "AccountsPayableCurrent", "USD", "CY2019Q1I")
    assert {:ok, frames} = frames
    assert frames["tag"] == "AccountsPayableCurrent"
  end

  test "frames not found" do
    frames = EDGAR.frames("us-gaap", "AccountsPayableCurrent", "USD", "CY2019Q1")
    assert {:error, :not_found} = frames
  end

  test "parsing 13f" do
    form13 = EDGAR.form13_filing("1067983", "000095012323005270")
    assert {:ok, form13} = form13
    assert form13.document.header.submission_type == "13F-HR"
  end

  test "parsing form4" do
    form4 = EDGAR.form4_filing("1295032", "000120919122003153")
    assert {:ok, form4} = form4
    assert form4.document_type == "4"
  end

  test "parsing company feed" do
    company_feed = EDGAR.company_feed("0000002488")
    assert {:ok, company_feed} = company_feed
    assert company_feed.company_info.cik == "0000002488"
  end

  test "parsing current feed" do
    current_feed = EDGAR.current_feed()
    assert {:ok, current_feed} = current_feed
    assert current_feed.author.name == "Webmaster"
  end
end
