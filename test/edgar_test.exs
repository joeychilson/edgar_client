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
    assert {:error, "resource not found"} = entity_directory
  end

  test "filing directory found" do
    filing_directory = EDGAR.filing_directory("320193", "000032019320000010")
    assert {:ok, filing_directory} = filing_directory

    assert filing_directory["directory"]["name"] ==
             "/Archives/edgar/data/320193/000032019320000010"
  end

  test "filing directory not found" do
    filing_directory = EDGAR.filing_directory("1", "1")
    assert {:error, "resource not found"} = filing_directory
  end

  test "company tickers found" do
    company_tickers = EDGAR.company_tickers()
    assert {:ok, company_tickers} = company_tickers
    assert Enum.count(company_tickers) > 0
  end

  test "cik for ticker found" do
    cik = EDGAR.company_cik("AAPL")
    assert {:ok, cik} = cik
    assert cik == "320193"
  end

  test "cik for ticker not found" do
    cik = EDGAR.company_cik("1")
    assert {:error, "ticker not found"} = cik
  end

  test "submissions found" do
    submissions = EDGAR.submissions("320193")
    assert {:ok, submissions} = submissions
    assert submissions["cik"] == "320193"
  end

  test "submissions not found" do
    submissions = EDGAR.submissions("1")
    assert {:error, "resource not found"} = submissions
  end

  test "company facts found" do
    company_facts = EDGAR.company_facts("320193")
    assert {:ok, company_facts} = company_facts
    assert company_facts["cik"] == 320_193
  end

  test "company facts not found" do
    company_facts = EDGAR.company_facts("1")
    assert {:error, "resource not found"} = company_facts
  end

  test "company concept found" do
    company_concept = EDGAR.company_concept("320193", "us-gaap", "AccountsPayableCurrent")
    assert {:ok, company_concept} = company_concept
    assert company_concept["cik"] == 320_193
  end

  test "company concept not found" do
    company_concept = EDGAR.company_concept("1", "us-gaap", "AccountsPayableCurrent")
    assert {:error, "resource not found"} = company_concept
  end

  test "frames found" do
    frames = EDGAR.frames("us-gaap", "AccountsPayableCurrent", "USD", "CY2019Q1I")
    assert {:ok, frames} = frames
    assert frames["tag"] == "AccountsPayableCurrent"
  end

  test "frames not found" do
    frames = EDGAR.frames("us-gaap", "AccountsPayableCurrent", "USD", "CY2019Q1")
    assert {:error, "resource not found"} = frames
  end

  test "parsing 13f filing" do
    form13 = EDGAR.form13f_from_filing("1067983", "000095012323005270")
    assert {:ok, form13} = form13
    assert form13.document.header_data.submission_type == "13F-HR"
  end

  test "parsing ownership filing" do
    form4 = EDGAR.ownership_from_filing("1295032", "000120919122003153")
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

  test "parsing press release feed" do
    press_release_feed = EDGAR.press_release_feed()
    assert {:ok, press_release_feed} = press_release_feed
    assert press_release_feed.title == "Press Releases"
  end

  test "parsing speeches and statements feed" do
    speeches_and_statements_feed = EDGAR.speeches_and_statements_feed()
    assert {:ok, speeches_and_statements_feed} = speeches_and_statements_feed
    assert speeches_and_statements_feed.title == "Speeches and Statements"
  end

  test "parsing xbrl" do
    xbrl =
      EDGAR.xbrl_from_url(
        "https://www.sec.gov/Archives/edgar/data/789019/000156459022026876/msft-10k_20220630_htm.xml"
      )

    assert {:ok, xbrl} = xbrl
    assert hd(xbrl.facts).context.entity == "0000789019"
  end
end
