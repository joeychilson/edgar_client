defmodule EDGARClientTest do
  use ExUnit.Case
  doctest EDGARClient

  test "entity directory found" do
    entity_directory = EDGARClient.get_entity_directory("320193")
    assert {:ok, entity_directory} = entity_directory
    assert entity_directory.directory.name == "/Archives/edgar/data/320193"
  end

  test "entity directory not found" do
    entity_directory = EDGARClient.get_entity_directory("1")
    assert {:error, :not_found} = entity_directory
  end

  test "filing directory found" do
    filing_directory = EDGARClient.get_filing_directory("320193", "000032019320000010")
    assert {:ok, filing_directory} = filing_directory
    assert filing_directory.directory.name == "/Archives/edgar/data/320193/000032019320000010"
  end

  test "filing directory not found" do
    filing_directory = EDGARClient.get_filing_directory("1", "1")
    assert {:error, :not_found} = filing_directory
  end

  test "company tickers found" do
    company_tickers = EDGARClient.get_company_tickers()
    assert {:ok, company_tickers} = company_tickers
    assert Enum.count(company_tickers) > 0
  end

  test "submissions found" do
    submissions = EDGARClient.get_submissions("320193")
    assert {:ok, submissions} = submissions
    assert submissions.cik == "320193"
  end

  test "submissions not found" do
    submissions = EDGARClient.get_submissions("1")
    assert {:error, :not_found} = submissions
  end

  test "company facts found" do
    company_facts = EDGARClient.get_company_facts("320193")
    assert {:ok, company_facts} = company_facts
    assert company_facts.cik == 320193
  end

  test "company facts not found" do
    company_facts = EDGARClient.get_company_facts("1")
    assert {:error, :not_found} = company_facts
  end

  test "company concept found" do
    company_concept = EDGARClient.get_company_concept("320193", "us-gaap", "AccountsPayableCurrent")
    assert {:ok, company_concept} = company_concept
    assert company_concept.cik == 320193
  end

  test "company concept not found" do
    company_concept = EDGARClient.get_company_concept("1", "us-gaap", "AccountsPayableCurrent")
    assert {:error, :not_found} = company_concept
  end

  test "frames found" do
    frames = EDGARClient.get_frames("us-gaap", "AccountsPayableCurrent", "USD", "CY2019Q1I")
    assert {:ok, frames} = frames
    assert frames.tag == "AccountsPayableCurrent"
  end

  test "frames not found" do
    frames = EDGARClient.get_frames("us-gaap", "AccountsPayableCurrent", "USD", "CY2019Q1")
    assert {:error, :not_found} = frames
  end
end
