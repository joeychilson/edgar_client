defmodule EDGARClientTest do
  use ExUnit.Case
  doctest EDGARClient

  test "submissions found" do
    submissions = EDGARClient.get_submissions("0000320193")
    assert {:ok, submissions_data} = submissions
    assert submissions_data.cik == "320193"
  end

  test "submissions not found" do
    submissions = EDGARClient.get_submissions("0000320")
    assert {:error, :not_found} = submissions
  end

  test "company facts found" do
    company_facts = EDGARClient.get_company_facts("0000320193")
    assert {:ok, company_facts_data} = company_facts
    assert company_facts_data.cik == 320193
  end

  test "company facts not found" do
    company_facts = EDGARClient.get_company_facts("0000320")
    assert {:error, :not_found} = company_facts
  end

  test "company concept found" do
    company_concept = EDGARClient.get_company_concept("0000320193", "us-gaap", "AccountsPayableCurrent")
    assert {:ok, company_concept_data} = company_concept
    assert company_concept_data.cik == 320193
  end

  test "company concept not found" do
    company_concept = EDGARClient.get_company_concept("0000320", "us-gaap", "AccountsPayableCurrent")
    assert {:error, :not_found} = company_concept
  end

  test "frames found" do
    frames = EDGARClient.get_frames("us-gaap", "AccountsPayableCurrent", "USD", "CY2019Q1I")
    assert {:ok, frames_data} = frames
    assert frames_data.tag == "AccountsPayableCurrent"
  end

  test "frames not found" do
    frames = EDGARClient.get_frames("us-gaap", "AccountsPayableCurrent", "USD", "CY2019Q1")
    assert {:error, :not_found} = frames
  end
end
