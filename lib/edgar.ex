defmodule EDGAR do
  use Application

  @edgar_archives_url "https://www.sec.gov/Archives/edgar"
  @edgar_data_url "https://data.sec.gov"
  @edgar_files_url "https://www.sec.gov/files"

  def start(_type, _args) do
    children = [
      {SimpleRateLimiter, interval: 1_000, max: 10}
    ]

    opts = [strategy: :one_for_one, name: EDGAR.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Fetches the entity directory

  ## Required

  * `cik` - The CIK of the entity
  """
  def entity_directory(cik) do
    cik = String.pad_leading(cik, 10, "0")

    "#{@edgar_archives_url}/data/#{cik}/index.json"
    |> get_json()
  end

  @doc """
  Fetches the filing directory

  ## Required

  * `cik` - The CIK of the entity
  * `accession_number` - The accession number of the filing
  """
  def filing_directory(cik, accession_number) do
    accession_number = String.replace(accession_number, "-", "")

    "#{@edgar_archives_url}/data/#{cik}/#{accession_number}/index.json"
    |> get_json()
  end

  @doc """
  Fetches a list of company tickers
  """
  def company_tickers() do
    resp = get_json("#{@edgar_files_url}/company_tickers.json")

    case resp do
      {:ok, result} ->
        {:ok, Map.values(result)}

      _ ->
        resp
    end
  end

  @doc """
  Fetches a CIK for a given ticker

  ## Required

  * `ticker` - The ticker of the company
  """
  def cik_for_ticker(ticker) do
    ticker = String.upcase(ticker)

    case company_tickers() do
      {:ok, tickers} ->
        ticker_data = Enum.find(tickers, fn t -> t["ticker"] == ticker end)

        case ticker_data do
          nil ->
            {:error, :not_found}

          _ ->
            {:ok, Integer.to_string(ticker_data["cik_str"])}
        end

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Fetches submissions for a given CIK

  ## Required

  * `cik` - The CIK of the entity
  """
  def submissions(cik) do
    cik = String.pad_leading(cik, 10, "0")

    "#{@edgar_data_url}/submissions/CIK#{cik}.json"
    |> get_json()
  end

  @doc """
  Fetches company facts for a given CIK

  ## Required

  * `cik` - The CIK of the entity
  """
  def company_facts(cik) do
    cik = String.pad_leading(cik, 10, "0")

    "#{@edgar_data_url}/api/xbrl/companyfacts/CIK#{cik}.json"
    |> get_json()
  end

  @doc """
  Fetches company concepts for a given CIK and concept (taxonomy, tag)

  ## Required

  * `cik` - The CIK of the entity
  * `taxonomy` - The taxonomy of the concept
  * `tag` - The tag of the concept
  """
  def company_concept(cik, taxonomy, tag) do
    cik = String.pad_leading(cik, 10, "0")

    "#{@edgar_data_url}/api/xbrl/companyconcept/CIK#{cik}/#{taxonomy}/#{tag}.json"
    |> get_json()
  end

  @doc """
  Fetches frames for a given taxonomy, concept, unit, and period

  ## Required

  * `taxonomy` - The taxonomy of the concept
  * `tag` - The tag of the concept
  * `unit` - The unit of the concept
  * `period` - The period of the concept
  """
  def frames(taxonomy, tag, unit, period) do
    "#{@edgar_data_url}/api/xbrl/frames/#{taxonomy}/#{tag}/#{unit}/#{period}.json"
    |> get_json()
  end

  @doc """
  Fetches a list of filings from the submissions file

  ## Required

  * `cik` - The CIK of the entity
  """
  def filings(cik) do
    case submissions(cik) do
      {:ok, submissions} ->
        recent_filings = submissions["filings"]["recent"]

        formatted_recent_filings = format_filings(recent_filings)

        files = submissions["filings"]["files"]

        formatted_file_filings =
          Enum.flat_map(files, fn file ->
            file_name = file["name"]
            {:ok, file_data} = get_json("#{@edgar_data_url}/submissions/#{file_name}")
            format_filings(file_data)
          end)

        {:ok, formatted_recent_filings ++ formatted_file_filings}

      {:error, _} = error ->
        error
    end
  end

  @doc false
  defp format_filings(filings) do
    field_names = [
      "acceptanceDateTime",
      "accessionNumber",
      "act",
      "fileNumber",
      "form",
      "isInlineXBRL",
      "isXBRL",
      "items",
      "primaryDocDescription",
      "primaryDocument",
      "reportDate",
      "size"
    ]

    file_field_values = for name <- field_names, do: Map.get(filings, name)

    Enum.zip(file_field_values)
    |> Enum.map(fn tuple ->
      Map.new(Enum.zip(field_names, Tuple.to_list(tuple)))
    end)
  end

  @doc """
  Fetches a list of filings from the submissions file by form

  ## Required

  * `cik` - The CIK of the entity
  * `forms` - The forms to filter by
  """
  def filings_by_forms(cik, forms) do
    case filings(cik) do
      {:ok, filings} ->
        {:ok, Enum.filter(filings, fn filing -> filing["form"] in forms end)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Parses form 3 and 3/A filing types from a given CIK and accession number

  Based on the XML schema found here:
  - https://www.sec.gov/info/edgar/specifications/ownershipxmltechspec

  ## Required

  * `cik` - The CIK of the entity
  * `accession_number` - The accession number of the filing
  """
  def parse_form3_filing(cik, accession_number), do: parse_ownership_filing(cik, accession_number)

  @doc """
  Parses form 4 and 4/A filing types from a given CIK and accession number

  Based on the XML schema found here:
  - https://www.sec.gov/info/edgar/specifications/ownershipxmltechspec

  ## Required

  * `cik` - The CIK of the entity
  * `accession_number` - The accession number of the filing
  """
  def parse_form4_filing(cik, accession_number), do: parse_ownership_filing(cik, accession_number)

  @doc """
  Parses form 5 and 5/A filing types from a given CIK and accession number

  Based on the XML schema found here:
  - https://www.sec.gov/info/edgar/specifications/ownershipxmltechspec

  ## Required

  * `cik` - The CIK of the entity
  * `accession_number` - The accession number of the filing
  """
  def parse_form5_filing(cik, accession_number), do: parse_ownership_filing(cik, accession_number)

  @doc """
  Parses form 3, 3/A, 4, 4/A, 5, and 5/A ownership filing types from a given CIK and accession number

  Based on the XML schema found here:
  - https://www.sec.gov/info/edgar/specifications/ownershipxmltechspec

  ## Required

  * `cik` - The CIK of the entity
  * `accession_number` - The accession number of the filing
  """
  def parse_ownership_filing(cik, accession_number) do
    case filing_directory(cik, accession_number) do
      {:ok, dir} ->
        files = dir["directory"]["item"]

        case Enum.find(files, fn file -> String.ends_with?(file["name"], ".xml") end) do
          nil ->
            {:error, "No xml file found"}

          xml_file ->
            acc_no = String.replace(accession_number, "-", "")
            xml_file_url = "#{@edgar_archives_url}/data/#{cik}/#{acc_no}/#{xml_file["name"]}"

            parse_ownership_filing_from_url(xml_file_url)
        end

      error ->
        error
    end
  end

  @doc """
  Parses form 3 and 3/A ownership filing types from a given url

  ## Required

  * `url` - The url of the form 3 filing
  """
  def parse_form3_from_url(url), do: parse_ownership_filing_from_url(url)

  @doc """
  Parses form 4 and 4/A ownership filing types from a given url

  ## Required

  * `url` - The url of the form 3 filing
  """
  def parse_form4_from_url(url), do: parse_ownership_filing_from_url(url)

  @doc """
  Parses form 5 and 5/A ownership filing types from a given url

  ## Required

  * `url` - The url of the form 3 filing
  """
  def parse_form5_from_url(url), do: parse_ownership_filing_from_url(url)

  @doc """
  Parses form 3, 3/A, 4, 4/A, 5, and 5/A ownership filing types from a given url

  Based on the XML schema found here:
  - https://www.sec.gov/info/edgar/specifications/ownershipxmltechspec

  ## Required

  * `url` - The url of the form 4 filing
  """
  def parse_ownership_filing_from_url(url) do
    with {:ok, body} <- get(url),
         result <- parse_ownership_form(body) do
      result
    end
  end

  @doc """
  Parses form 3, 3/A, 4, 4/A, 5, and 5/A filing types.

  Based on the XML schema found here:
  - https://www.sec.gov/info/edgar/specifications/ownershipxmltechspec

  ## Required

  * `document` - The document xml to parse
  """
  def parse_ownership_form(document), do: EDGAR.Native.parse_ownership_form(document)

  @doc """

  Parses a form 13F filing for a given CIK and accession number

  ## Required

  * `cik` - The CIK of the entity
  * `accession_number` - The accession number of the filing
  """
  def parse_form13f_filing(cik, accession_number) do
    case filing_directory(cik, accession_number) do
      {:ok, dir} ->
        files = dir["directory"]["item"]

        primary_doc_file = Enum.find(files, fn file -> file["name"] == "primary_doc.xml" end)

        table_xml_file =
          Enum.find(files, fn file ->
            file["name"] != "primary_doc.xml" and String.ends_with?(file["name"], ".xml")
          end)

        if primary_doc_file && table_xml_file do
          acc_no = String.replace(accession_number, "-", "")

          primary_doc_url =
            "#{@edgar_archives_url}/data/#{cik}/#{acc_no}/#{primary_doc_file["name"]}"

          table_xml_url =
            "#{@edgar_archives_url}/data/#{cik}/#{acc_no}/#{table_xml_file["name"]}"

          with {:ok, document} <- parse_form13f_document_from_url(primary_doc_url),
               {:ok, table} <- parse_form13f_table_from_url(table_xml_url) do
            {:ok, %{document: document, table: table}}
          else
            error -> error
          end
        else
          {:error, "No primary_doc or table file found"}
        end

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Parses a form 13F filing from a given url

  ## Required

  * `url` - The url of the form 13F document filing

  """
  def parse_form13f_document_from_url(url) do
    with {:ok, body} <- get(url),
         result <- parse_13f_document(body) do
      result
    end
  end

  @doc """
  Parses a form 13F filing table from a given url

  ## Required

  * `url` - The url of the form 13F table filing
  """
  def parse_form13f_table_from_url(url) do
    with {:ok, body} <- get(url),
         result <- parse_13f_table(body) do
      result
    end
  end

  @doc """
  Parses a form 13F filing primary document

  ## Required

  * `xml` - The document xml to parse
  """
  def parse_13f_document(xml), do: EDGAR.Native.parse_13f_document(xml)

  @doc """

  Parses a form 13F filing table

  ## Required

  * `xml` - The table xml to parse
  """
  def parse_13f_table(xml), do: EDGAR.Native.parse_13f_table(xml)

  @doc """
  Parses a xbrl filing from a given url

  ## Required

  * `url` - The url of the xbrl filing
  """
  def parse_xbrl_from_url(url) do
    with {:ok, body} <- get(url),
         result <- parse_xbrl(body) do
      result
    end
  end

  @doc """
  Parses a XBRL file

  ## Required

  * `xml` - The XBRL xml to parse
  """
  def parse_xbrl(xml), do: EDGAR.Native.parse_xbrl(xml)

  @doc """
  Fetches the current feed for a given CIK

  ## Optional

  * `CIK` - The CIK of the entity
  * `type` - The type of filing to filter by
  * `company` - The company to filter by
  * `dateb` - The date to filter by
  * `owner` - The owner to filter by
  * `start` - The start index of the filings to return
  * `count` - The number of filings to return

  """
  def current_feed(opts \\ %{}) do
    opts = Map.merge(%{output: "atom"}, opts)
    url = "https://www.sec.gov/cgi-bin/browse-edgar?action=getcurrent&#{URI.encode_query(opts)}"

    with {:ok, body} <- get(url),
         result <- parse_current_feed(body) do
      result
    end
  end

  @doc """
  Parses the current feed

  ## Required

  * `xml` - The RSS feed xml to parse
  """
  def parse_current_feed(xml), do: EDGAR.Native.parse_current_feed(xml)

  @doc """
  Fetches the company feed for a given CIK

  ## Required

  * `cik` - The CIK of the entity

  ## Optional

  * `type` - The type of filing to filter by
  * `start` - The start index of the filings to return
  * `count` - The number of filings to return

  """
  def company_feed(cik, opts \\ %{}) do
    opts = Map.merge(%{output: "atom", CIK: cik}, opts)
    url = "https://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&#{URI.encode_query(opts)}"

    with {:ok, body} <- get(url),
         result <- parse_company_feed(body) do
      result
    end
  end

  @doc """
  Parses the company feed

  ## Required

  * `xml` - The RSS feed xml to parse
  """
  def parse_company_feed(xml), do: EDGAR.Native.parse_company_feed(xml)

  @doc """
  Fetches the press release feed
  """
  def press_release_feed do
    url = "https://www.sec.gov/news/pressreleases.rss"

    with {:ok, body} <- get(url),
         result <- parse_rss_feed(body) do
      result
    end
  end

  @doc """
  Fetches the speeches and statements feed
  """
  def speeches_and_statements_feed do
    url = "https://www.sec.gov/news/speeches-statements.rss"

    with {:ok, body} <- get(url),
         result <- parse_rss_feed(body) do
      result
    end
  end

  @doc """
  Fetches the speeches feed
  """
  def speeches_feed do
    url = "https://www.sec.gov/news/speeches.rss"

    with {:ok, body} <- get(url),
         result <- parse_rss_feed(body) do
      result
    end
  end

  @doc """
  Fetches the testimony feed
  """
  def testimony_feed do
    url = "https://www.sec.gov/news/testimony.rss"

    with {:ok, body} <- get(url),
         result <- parse_rss_feed(body) do
      result
    end
  end

  @doc """
  Fetches the statements feed
  """
  def statements_feed do
    url = "https://www.sec.gov/news/statements.rss"

    with {:ok, body} <- get(url),
         result <- parse_rss_feed(body) do
      result
    end
  end

  @doc """
  Fetches the litigation feed
  """
  def litigation_feed do
    url = "https://www.sec.gov/litigation/litreleases.rss"

    with {:ok, body} <- get(url),
         result <- parse_rss_feed(body) do
      result
    end
  end

  @doc """
  Fetches the administrative proceedings feed
  """
  def administrative_roceedings_feed do
    url = "https://www.sec.gov/rss/litigation/admin.xml"

    with {:ok, body} <- get(url),
         result <- parse_rss_feed(body) do
      result
    end
  end

  @doc """
  Fetches the trading suspensions feed
  """
  def trading_suspensions_feed do
    url = "https://www.sec.gov/rss/litigation/suspensions.xml"

    with {:ok, body} <- get(url),
         result <- parse_rss_feed(body) do
      result
    end
  end

  @doc """
  Fetches the division of corporation finance news feed
  """
  def division_of_corporation_finance_feed do
    url = "https://www.sec.gov/rss/divisions/corpfin/cfnew.xml"

    with {:ok, body} <- get(url),
         result <- parse_rss_feed(body) do
      result
    end
  end

  @doc """
  Fetches the division of investment management news feed
  """
  def division_of_investment_management_feed do
    url = "https://www.sec.gov/rss/divisions/investment/imnews.xml"

    with {:ok, body} <- get(url),
         result <- parse_rss_feed(body) do
      result
    end
  end

  @doc """
  Fetches the investor alerts feed
  """
  def investor_alerts_feed do
    url = "https://www.sec.gov/rss/investor/alerts"

    with {:ok, body} <- get(url),
         result <- parse_rss_feed(body) do
      result
    end
  end

  @doc """
  Parses the press release feed

  ## Required

  * `xml` - The RSS feed xml to parse
  """
  def parse_rss_feed(xml), do: EDGAR.Native.parse_rss_feed(xml)

  @doc false
  defp get_json(url) do
    SimpleRateLimiter.wait_and_proceed(fn ->
      case get(url) do
        {:ok, body} ->
          {:ok, Jason.decode!(body)}

        {:error, _} = error ->
          error
      end
    end)
  end

  @doc false
  defp get(url) do
    SimpleRateLimiter.wait_and_proceed(fn ->
      user_agent =
        Application.get_env(:edgar_client, :user_agent, "default <default@default.com>")

      resp =
        HTTPoison.get(url, [{"User-Agent", user_agent}], follow_redirect: true)

      case resp do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          {:ok, body}

        {:ok, %HTTPoison.Response{status_code: 404}} ->
          {:error, :not_found}

        {:ok, %HTTPoison.Response{status_code: code}} ->
          {:error, {:unexpected_status_code, code}}

        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, reason}
      end
    end)
  end
end
