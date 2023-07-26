defmodule EDGARTest do
  use ExUnit.Case
  doctest EDGAR

  test "company_tickers/0 returns a list of tickers" do
    {:ok, tickers} = EDGAR.company_tickers()
    assert is_list(tickers)
    assert length(tickers) > 0
  end

  test "company_tickers_with_exchange/0 returns a list of tickers" do
    {:ok, tickers} = EDGAR.company_tickers_with_exchange()
    assert is_list(tickers)
    assert length(tickers) > 0
  end

  test "mutual_fund_tickers/0 returns a list of tickers" do
    {:ok, tickers} = EDGAR.mutual_fund_tickers()
    assert is_list(tickers)
    assert length(tickers) > 0
  end

  test "company_cik/1 returns a cik" do
    {:ok, cik} = EDGAR.company_cik("AAPL")
    assert is_integer(cik)
    assert cik == 320_193
  end

  test "company_cik/1 returns an error when the ticker not found" do
    {:error, error} = EDGAR.company_cik("INVALID")
    assert error == "ticker not found"
  end

  test "mutual_fund_cik/1 returns a cik" do
    {:ok, cik} = EDGAR.mutual_fund_cik("LACAX")
    assert is_integer(cik)
    assert cik == 2110
  end

  test "mutual_fund_cik/1 returns an error when the ticker not found" do
    {:error, error} = EDGAR.mutual_fund_cik("INVALID")
    assert error == "ticker not found"
  end

  test "entity_directory/1 returns a directory" do
    {:ok, result} = EDGAR.entity_directory("320193")
    assert is_list(result["directory"]["item"])
    assert length(result["directory"]["item"]) > 0
  end

  test "entity_directory/1 returns an error when the directory not found" do
    {:error, error} = EDGAR.entity_directory("INVALID")
    assert error == "resource not found"
  end

  test "filing_directory/2 returns a directory" do
    {:ok, result} = EDGAR.filing_directory("320193", "0001140361-23-023909")
    assert is_list(result["directory"]["item"])
    assert length(result["directory"]["item"]) > 0
  end

  test "filing_directory/2 returns an error when the directory not found" do
    {:error, error} = EDGAR.filing_directory("INVALID", "INVALID")
    assert error == "resource not found"
  end

  test "daily_index/0 returns a directory" do
    {:ok, result} = EDGAR.daily_index()
    assert is_list(result["directory"]["item"])
    assert length(result["directory"]["item"]) > 0
  end

  test "daily_index/1 returns a directory" do
    {:ok, result} = EDGAR.daily_index(2021)
    assert is_list(result["directory"]["item"])
    assert length(result["directory"]["item"]) > 0
  end

  test "daily_index/2 returns a directory" do
    {:ok, result} = EDGAR.daily_index(2021, 1)
    assert is_list(result["directory"]["item"])
    assert length(result["directory"]["item"]) > 0
  end

  test "daily_index/1 returns an error if year is less than 1994" do
    {:error, error} = EDGAR.daily_index(1993)
    assert error == "year must be 1994 or greater"
  end

  test "daily_index/2 returns an error if quarter is not 1-4" do
    {:error, error} = EDGAR.daily_index(1994, 20)
    assert error == "quarter must be between 1 and 4"
  end

  test "full_index/0 returns a directory" do
    {:ok, result} = EDGAR.full_index()
    assert is_list(result["directory"]["item"])
    assert length(result["directory"]["item"]) > 0
  end

  test "full_index/1 returns a directory" do
    {:ok, result} = EDGAR.full_index(2021)
    assert is_list(result["directory"]["item"])
    assert length(result["directory"]["item"]) > 0
  end

  test "full_index/2 returns a directory" do
    {:ok, result} = EDGAR.full_index(2021, 1)
    assert is_list(result["directory"]["item"])
    assert length(result["directory"]["item"]) > 0
  end

  test "full_index/1 returns an error if year is less than 1994" do
    {:error, error} = EDGAR.full_index(1993)
    assert error == "year must be 1994 or greater"
  end

  test "full_index/2 returns an error if quarter is not 1-4" do
    {:error, error} = EDGAR.full_index(1994, 20)
    assert error == "quarter must be between 1 and 4"
  end

  test "company_index_from_url/1 returns a list of filings" do
    {:ok, filings} =
      EDGAR.company_index_from_url(
        "https://www.sec.gov/Archives/edgar/full-index/2023/QTR1/company.idx"
      )

    assert is_list(filings)
    assert length(filings) > 0
  end

  test "company_index_from_url/1 returns an error with invalid url" do
    {:error, error} = EDGAR.company_index_from_url("https://sec.gov/invalid")
    assert error == "resource not found"
  end

  test "company_index_from_file/1 returns a list of filings" do
    {:ok, filings} = EDGAR.company_index_from_file("test/test_data/company.idx")
    assert is_list(filings)
    assert length(filings) > 0
  end

  test "company_index_from_file/1 returns an error if no file" do
    {:error, error} = EDGAR.company_index_from_file("test/test_data/invalid.idx")
    assert error == :enoent
  end

  test "crawler_index_from_url/1 returns a list of filings" do
    {:ok, filings} =
      EDGAR.crawler_index_from_url(
        "https://www.sec.gov/Archives/edgar/full-index/2023/QTR1/crawler.idx"
      )

    assert is_list(filings)
    assert length(filings) > 0
  end

  test "crawler_index_from_url/1 returns an error with invalid url" do
    {:error, error} = EDGAR.crawler_index_from_url("https://sec.gov/invalid")
    assert error == "resource not found"
  end

  test "crawler_index_from_file/1 returns a list of filings" do
    {:ok, filings} = EDGAR.crawler_index_from_file("test/test_data/crawler.idx")
    assert is_list(filings)
    assert length(filings) > 0
  end

  test "crawler_index_from_file/1 returns an error if no file" do
    {:error, error} = EDGAR.crawler_index_from_file("test/test_data/invalid.idx")
    assert error == :enoent
  end

  test "form_index_from_url/1 returns a list of filings" do
    {:ok, filings} =
      EDGAR.form_index_from_url(
        "https://www.sec.gov/Archives/edgar/full-index/2023/QTR1/form.idx"
      )

    assert is_list(filings)
    assert length(filings) > 0
  end

  test "form_index_from_url/1 returns an error with invalid url" do
    {:error, error} = EDGAR.form_index_from_url("https://sec.gov/invalid")
    assert error == "resource not found"
  end

  test "form_index_from_file/1 returns a list of filings" do
    {:ok, filings} = EDGAR.form_index_from_file("test/test_data/form.idx")
    assert is_list(filings)
    assert length(filings) > 0
  end

  test "form_index_from_file/1 returns an error if no file" do
    {:error, error} = EDGAR.form_index_from_file("test/test_data/invalid.idx")
    assert error == :enoent
  end

  test "xbrl_index_from_url/1 returns a list of filings" do
    {:ok, filings} =
      EDGAR.xbrl_index_from_url(
        "https://www.sec.gov/Archives/edgar/full-index/2023/QTR1/xbrl.idx"
      )

    assert is_list(filings)
    assert length(filings) > 0
  end

  test "xbrl_index_from_url/1 returns an error with invalid url" do
    {:error, error} = EDGAR.xbrl_index_from_url("https://sec.gov/invalid")
    assert error == "resource not found"
  end

  test "xbrl_index_from_file/1 returns a list of filings" do
    {:ok, filings} = EDGAR.xbrl_index_from_file("test/test_data/xbrl.idx")
    assert is_list(filings)
    assert length(filings) > 0
  end

  test "xbrl_index_from_file/1 returns an error if no file" do
    {:error, error} = EDGAR.xbrl_index_from_file("test/test_data/invalid.idx")
    assert error == :enoent
  end

  test "master_index_from_url/1 returns a list of filings" do
    {:ok, filings} =
      EDGAR.master_index_from_url(
        "https://www.sec.gov/Archives/edgar/full-index/2023/QTR1/master.idx"
      )

    assert is_list(filings)
    assert length(filings) > 0
  end

  test "master_index_from_url/1 returns an error with invalid url" do
    {:error, error} = EDGAR.master_index_from_url("https://sec.gov/invalid")
    assert error == "resource not found"
  end

  test "master_index_from_file/1 returns a list of filings" do
    {:ok, filings} = EDGAR.master_index_from_file("test/test_data/master.idx")
    assert is_list(filings)
    assert length(filings) > 0
  end

  test "master_index_from_file/1 returns an error if no file" do
    {:error, error} = EDGAR.master_index_from_file("test/test_data/invalid.idx")
    assert error == :enoent
  end

  test "submissions/1 returns a submissions map" do
    {:ok, submissions} = EDGAR.submissions("320193")
    assert is_map(submissions)
    assert submissions["name"] == "Apple Inc."
  end

  test "submissions/1 returns an error if no submissions" do
    {:error, error} = EDGAR.submissions("0")
    assert error == "resource not found"
  end

  test "company_facts/1 returns a company_facts map" do
    {:ok, company_facts} = EDGAR.company_facts("320193")
    assert is_map(company_facts)
    assert company_facts["entityName"] == "Apple Inc."
  end

  test "company_facts/1 returns an error if no company_facts" do
    {:error, error} = EDGAR.company_facts("0")
    assert error == "resource not found"
  end

  test "company_concept/3 returns a company_concept map" do
    {:ok, company_concept} =
      EDGAR.company_concept("320193", "dei", "EntityCommonStockSharesOutstanding")

    assert is_map(company_concept)
    assert company_concept["taxonomy"] == "dei"
    assert company_concept["tag"] == "EntityCommonStockSharesOutstanding"
  end

  test "company_concept/3 returns an error if no company_concept" do
    {:error, error} = EDGAR.company_concept("0", "dei", "EntityCommonStockSharesOutstanding")
    assert error == "resource not found"
  end

  test "frames/4 returns a frames map" do
    {:ok, frames} = EDGAR.frames("us-gaap", "AccountsPayableCurrent", "USD", "CY2019Q1I")

    assert is_map(frames)
    assert frames["taxonomy"] == "us-gaap"
    assert frames["tag"] == "AccountsPayableCurrent"
    assert frames["uom"] == "USD"
    assert frames["ccp"] == "CY2019Q1I"
  end

  test "frames/4 returns an error if no frames" do
    {:error, error} = EDGAR.frames("us", "AccountsPayableCurrent", "USD", "CY2019Q1I")
    assert error == "resource not found"
  end

  test "filings/1 returns a filings list" do
    {:ok, filings} = EDGAR.filings("320193")
    assert is_list(filings)
    assert length(filings) > 0
  end

  test "filings/2 returns 10-K filings" do
    {:ok, filings} = EDGAR.filings("320193", %{form_type: "10-K"})
    assert hd(filings)["form"] == "10-K"
  end

  test "filings/2 returns limited filings" do
    {:ok, filings} = EDGAR.filings("320193", %{limit: 1})
    assert length(filings) == 1
  end

  test "filings/2 returns offset filings" do
    {:ok, filings} = EDGAR.filings("320193", %{offset: 1})
    {:ok, filings2} = EDGAR.filings("320193", %{offset: 2})
    assert length(filings) == length(filings2) + 1
  end

  test "filings/1 returns an error if no filings" do
    {:error, error} = EDGAR.filings("0")
    assert error == "resource not found"
  end

  test "form3_from_filing/2 returns a parsed form 3 filing" do
    {:ok, filing} = EDGAR.form3_from_filing("320193", "0001127602-13-014623")
    assert is_map(filing)
    assert filing.document_type == "3"
  end

  test "form3_from_filing/2 returns an error if no filing" do
    {:error, error} = EDGAR.form3_from_filing("0", "0001127602-13-014623")
    assert error == "resource not found"
  end

  test "form3_from_file/1 returns a parsed form 3 filing" do
    {:ok, filing} = EDGAR.form3_from_file("test/test_data/doc3.xml")

    assert is_map(filing)
    assert filing.document_type == "3"
  end

  test "form3_from_file/1 returns an error if no file" do
    {:error, error} = EDGAR.form3_from_file("invalid")
    assert error == :enoent
  end

  test "form3_from_file/1 returns a parsed form 3/A filing" do
    {:ok, filing} = EDGAR.form3_from_file("test/test_data/doc3a.xml")

    assert is_map(filing)
    assert filing.document_type == "3/A"
  end

  test "form3_from_url/1 returns a parsed form 3 filing" do
    {:ok, filing} =
      EDGAR.form3_from_url(
        "https://www.sec.gov/Archives/edgar/data/320193/000112760213014623/form3.xml"
      )

    assert is_map(filing)
    assert filing.document_type == "3"
  end

  test "form3_from_url/1 returns an error if no filing" do
    {:error, error} = EDGAR.form3_from_url("https://sec.gov/invalid")
    assert error == "resource not found"
  end

  test "form4_from_filing/2 returns a parsed form 4 filing" do
    {:ok, filing} = EDGAR.form4_from_filing("320193", "0001127602-13-014625")
    assert is_map(filing)
    assert filing.document_type == "4"
  end

  test "form4_from_filing/2 returns an error if no filing" do
    {:error, error} = EDGAR.form4_from_filing("0", "0001127602-13-014625")
    assert error == "resource not found"
  end

  test "form4_from_file/1 returns a parsed form 4 filing" do
    {:ok, filing} = EDGAR.form4_from_file("test/test_data/doc4.xml")

    assert is_map(filing)
    assert filing.document_type == "4"
  end

  test "form4_from_file/1 returns an error if no file" do
    {:error, error} = EDGAR.form4_from_file("invalid")
    assert error == :enoent
  end

  test "form4_from_file/1 returns a parsed form 4/A filing" do
    {:ok, filing} = EDGAR.form4_from_file("test/test_data/doc4a.xml")

    assert is_map(filing)
    assert filing.document_type == "4/A"
  end

  test "form4_from_url/1 returns a parsed form 4 filing" do
    {:ok, filing} =
      EDGAR.form4_from_url(
        "https://www.sec.gov/Archives/edgar/data/320193/000112760213014625/form4.xml"
      )

    assert is_map(filing)
    assert filing.document_type == "4"
  end

  test "form4_from_url/1 returns an error if no filing" do
    {:error, error} = EDGAR.form4_from_url("https://sec.gov/invalid")
    assert error == "resource not found"
  end

  test "form5_from_filing/2 returns a parsed form 5 filing" do
    {:ok, filing} = EDGAR.form5_from_filing("1833903", "0001225208-23-007647")
    assert is_map(filing)
    assert filing.document_type == "5"
  end

  test "form5_from_filing/2 returns an error if no filing" do
    {:error, error} = EDGAR.form5_from_filing("0", "0001225208-23-007647")
    assert error == "resource not found"
  end

  test "form5_from_file/1 returns a parsed form 5 filing" do
    {:ok, filing} = EDGAR.form5_from_file("test/test_data/doc5.xml")

    assert is_map(filing)
    assert filing.document_type == "5"
  end

  test "form5_from_file/1 returns an error if no file" do
    {:error, error} = EDGAR.form5_from_file("invalid")
    assert error == :enoent
  end

  test "form5_from_file/1 returns a parsed form 5/A filing" do
    {:ok, filing} = EDGAR.form5_from_file("test/test_data/doc5a.xml")

    assert is_map(filing)
    assert filing.document_type == "5/A"
  end

  test "form5_from_url/1 returns a parsed form 5 filing" do
    {:ok, filing} =
      EDGAR.form5_from_url(
        "https://www.sec.gov/Archives/edgar/data/1383312/000122520823007647/doc5.xml"
      )

    assert is_map(filing)
    assert filing.document_type == "5"
  end

  test "form5_from_url/1 returns an error if no filing" do
    {:error, error} = EDGAR.form5_from_url("https://sec.gov/invalid")
    assert error == "resource not found"
  end

  test "form13f_from_filing/1 returns a parsed form 13F-HR filing" do
    {:ok, filing} = EDGAR.form13f_from_filing("1067983", "0000950123-23-005270")

    assert is_map(filing)
    assert filing.document.header_data.submission_type == "13F-HR"
  end

  test "form13f_document_from_file/1 returns a parsed form 13F-CTR document" do
    {:ok, document} = EDGAR.form13f_document_from_file("test/test_data/doc13f_ctr.xml")

    assert is_map(document)
    assert document.header_data.submission_type == "13F-CTR"
  end

  test "form13f_document_from_file/1 returns a parsed form 13F-CTR/A document" do
    {:ok, document} = EDGAR.form13f_document_from_file("test/test_data/doc13f_ctra.xml")

    assert is_map(document)
    assert document.header_data.submission_type == "13F-CTR/A"
  end

  test "form13f_document_from_file/1 returns a parsed form 13F-HR document" do
    {:ok, document} = EDGAR.form13f_document_from_file("test/test_data/doc13f_hr.xml")

    assert is_map(document)
    assert document.header_data.submission_type == "13F-HR"
  end

  test "form13f_document_from_file/1 returns a parsed form 13F-HR/A document" do
    {:ok, document} = EDGAR.form13f_document_from_file("test/test_data/doc13f_hra.xml")

    assert is_map(document)
    assert document.header_data.submission_type == "13F-HR/A"
  end

  test "form13f_document_from_file/1 returns a parsed form 13F-NT document" do
    {:ok, document} = EDGAR.form13f_document_from_file("test/test_data/doc13f_nt.xml")

    assert is_map(document)
    assert document.header_data.submission_type == "13F-NT"
  end

  test "form13f_document_from_file/1 returns a parsed form 13F-NT/A document" do
    {:ok, document} = EDGAR.form13f_document_from_file("test/test_data/doc13f_nta.xml")

    assert is_map(document)
    assert document.header_data.submission_type == "13F-NT/A"
  end

  test "form13f_document_from_url/1 returns a parsed form 13F document" do
    {:ok, document} =
      EDGAR.form13f_document_from_url(
        "https://www.sec.gov/Archives/edgar/data/1067983/000095012323005270/primary_doc.xml"
      )

    assert is_map(document)
    assert document.header_data.submission_type == "13F-HR"
  end

  test "form13f_table_from_file/1 returns a parsed form 13F table" do
    {:ok, table} = EDGAR.form13f_table_from_file("test/test_data/doc13f_table.xml")

    assert is_map(table)
    assert length(table.entries) > 0
  end

  test "form13f_table_from_file/1 returns an error if no file" do
    {:error, error} = EDGAR.form13f_table_from_file("test/test_data/invalid.xml")
    assert error == :enoent
  end

  test "xbrl_from_file/1 returns a parsed xbrl filing" do
    {:ok, xbrl} = EDGAR.xbrl_from_file("test/test_data/xbrl.xml")

    assert is_map(xbrl)
    assert length(xbrl.facts) > 0
  end

  test "xbrl_from_file/1 returns an error if no file" do
    {:error, error} = EDGAR.form13f_table_from_file("test/test_data/invalid.xml")
    assert error == :enoent
  end

  test "xbrl_from_url/1 returns a parsed xbrl filing" do
    {:ok, xbrl} =
      EDGAR.xbrl_from_url(
        "https://www.sec.gov/Archives/edgar/data/1067983/000119312523140854/d501487d8k_htm.xml"
      )

    assert is_map(xbrl)
    assert length(xbrl.facts) > 0
  end

  test "current_feed/0 returns a parsed current feed" do
    {:ok, feed} = EDGAR.current_feed()

    assert is_map(feed)
    assert length(feed.links) > 0
  end

  test "company_feed/1 returns a parsed company feed" do
    {:ok, feed} = EDGAR.company_feed("320193")

    assert is_map(feed)
    assert length(feed.links) > 0
  end

  test "press_release_feed/0 returns a parsed press release feed" do
    {:ok, feed} = EDGAR.press_release_feed()

    assert is_map(feed)
    assert length(feed.items) > 0
  end

  test "speeches_and_statements_feed/0 returns a parsed speeches and statements feed" do
    {:ok, feed} = EDGAR.speeches_and_statements_feed()

    assert is_map(feed)
    assert length(feed.items) > 0
  end

  test "speeches_feed/0 returns a parsed speeches feed" do
    {:ok, feed} = EDGAR.speeches_feed()

    assert is_map(feed)
    assert length(feed.items) > 0
  end

  test "statements_feed/0 returns a parsed statements feed" do
    {:ok, feed} = EDGAR.statements_feed()

    assert is_map(feed)
    assert length(feed.items) > 0
  end

  test "testimony_feed/0 returns a parsed testimony feed" do
    {:ok, feed} = EDGAR.testimony_feed()

    assert is_map(feed)
    assert length(feed.items) > 0
  end

  test "litigation_feed/0 returns a parsed litigation feed" do
    {:ok, feed} = EDGAR.litigation_feed()

    assert is_map(feed)
    assert length(feed.items) > 0
  end

  test "administrative_proceedings_feed/0 returns a parsed administrative proceedings feed" do
    {:ok, feed} = EDGAR.administrative_proceedings_feed()

    assert is_map(feed)
    assert length(feed.items) > 0
  end

  test "trading_suspensions_feed/0 returns a parsed trading suspension feed" do
    {:ok, feed} = EDGAR.trading_suspensions_feed()

    assert is_map(feed)
    assert length(feed.items) > 0
  end

  test "division_of_corporation_finance_feed/0 returns a parsed division of corporation finance feed" do
    {:ok, feed} = EDGAR.division_of_corporation_finance_feed()

    assert is_map(feed)
    assert length(feed.items) > 0
  end

  test "investor_alerts_feed/0 returns a parsed investor alerts feed" do
    {:ok, feed} = EDGAR.investor_alerts_feed()

    assert is_map(feed)
    assert length(feed.items) > 0
  end

  test "filings_feed/0 returns a parsed filings feed" do
    {:ok, feed} = EDGAR.filings_feed()

    assert is_map(feed)
    assert length(feed.items) > 0
  end

  test "mutual_funds_feed/0 returns a parsed mutual funds feed" do
    {:ok, feed} = EDGAR.mutual_funds_feed()

    assert is_map(feed)
    assert length(feed.items) > 0
  end

  test "xbrl_feed/0 returns a parsed xbrl feed" do
    {:ok, feed} = EDGAR.xbrl_feed()

    assert is_map(feed)
    assert length(feed.items) > 0
  end

  test "inline_xbrl_feed/0 returns a parsed inline xbrl feed" do
    {:ok, feed} = EDGAR.inline_xbrl_feed()

    assert is_map(feed)
    assert length(feed.items) > 0
  end

  test "historical_xbrl_feed/2 returns a historical xbrl feed" do
    {:ok, feed} = EDGAR.historical_xbrl_feed(2021, 1)
    assert is_map(feed)
    assert length(feed.items) > 0
  end

  test "historical_xbrl_feed/2 returns an error if year is less than 2005" do
    {:error, error} = EDGAR.historical_xbrl_feed(1993, 2)
    assert error == "year must be 2005 or later"
  end

  test "historical_xbrl_feed/2 returns an error if month is below 1" do
    {:error, error} = EDGAR.historical_xbrl_feed(2006, 0)
    assert error == "month must be between 1 and 12"
  end

  test "historical_xbrl_feed/2 returns an error if month is above 12" do
    {:error, error} = EDGAR.historical_xbrl_feed(2006, 20)
    assert error == "month must be between 1 and 12"
  end
end
