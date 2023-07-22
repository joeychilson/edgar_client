defmodule EDGAR do
  use Application

  @edgar_archives_url "https://www.sec.gov/Archives/edgar"
  @edgar_data_url "https://data.sec.gov"
  @edgar_files_url "https://www.sec.gov/files"

  @type success_type(inner) :: {:ok, inner}
  @type error_type :: {:error, String.t()}

  def start(_type, _args) do
    children = [
      {SimpleRateLimiter, interval: 1_000, max: 10}
    ]

    opts = [strategy: :one_for_one, name: EDGAR.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Fetches the daily index
  """
  @spec daily_index :: success_type(map()) | error_type()
  def daily_index, do: get_json("#{@edgar_archives_url}/daily-index/index.json")

  @doc """
  Fetches the daily index for a given year

  ## Required

  * `year` - The year of the daily index
  """
  @spec daily_index(year :: integer()) :: success_type(map()) | error_type()
  def daily_index(year) do
    if year < 1993 do
      {:error, "invalid year (must be greater than 1993)"}
    end

    year = Integer.to_string(year)
    get_json("#{@edgar_archives_url}/daily-index/#{year}/index.json")
  end

  @doc """
  Fetches the daily index for a given year and quarter

  ## Required

  * `year` - The year of the daily index
  * `quarter` - The quarter of the daily index
  """
  @spec daily_index(year :: integer(), quarter :: integer()) ::
          success_type(map()) | error_type()
  def daily_index(year, quarter) do
    cond do
      year < 1994 ->
        {:error, "invalid year (must be 1994 or greater)"}

      quarter > 4 || quarter < 1 ->
        {:error, "invalid quarter (must be between 1 and 4)"}

      true ->
        year_str = Integer.to_string(year)
        quarter_str = Integer.to_string(quarter)
        get_json("#{@edgar_archives_url}/daily-index/#{year_str}/QTR#{quarter_str}/index.json")
    end
  end

  @doc """
  Fetches the full index
  """
  @spec full_index :: success_type(map()) | error_type()
  def full_index, do: get_json("#{@edgar_archives_url}/full-index/index.json")

  @doc """
  Fetches the full index for a given year

  ## Required

  * `year` - The year of the full index
  """
  @spec full_index(year :: integer()) :: success_type(map()) | error_type()
  def full_index(year) do
    if year < 1993 do
      {:error, "invalid year (must be greater than 1993)"}
    end

    year = Integer.to_string(year)
    get_json("#{@edgar_archives_url}/full-index/#{year}/index.json")
  end

  @doc """
  Fetches the full index for a given year and quarter

  ## Required

  * `year` - The year of the full index
  * `quarter` - The quarter of the full index
  """
  @spec full_index(year :: integer(), quarter :: integer()) ::
          success_type(map()) | error_type()
  def full_index(year, quarter) do
    cond do
      year < 1994 ->
        {:error, "invalid year (must be 1994 or greater)"}

      quarter > 4 || quarter < 1 ->
        {:error, "invalid quarter (must be between 1 and 4)"}

      true ->
        year_str = Integer.to_string(year)
        quarter_str = Integer.to_string(quarter)
        get_json("#{@edgar_archives_url}/full-index/#{year_str}/QTR#{quarter_str}/index.json")
    end
  end

  @doc """
  Fetches the entity directory

  ## Required

  * `cik` - The CIK of the entity
  """
  @spec entity_directory(cik :: String.t()) :: success_type(map()) | error_type()
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
  @spec filing_directory(cik :: String.t(), accession_number :: String.t()) ::
          success_type(map()) | error_type()
  def filing_directory(cik, accession_number) do
    accession_number = String.replace(accession_number, "-", "")

    "#{@edgar_archives_url}/data/#{cik}/#{accession_number}/index.json"
    |> get_json()
  end

  @doc """
  Fetches a list of company tickers
  """
  @spec company_tickers :: success_type(list()) | error_type()
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
  @spec cik_for_ticker(ticker :: String.t()) :: success_type(String.t()) | error_type()
  def cik_for_ticker(ticker) do
    ticker = String.upcase(ticker)

    case company_tickers() do
      {:ok, tickers} ->
        ticker_data = Enum.find(tickers, fn t -> t["ticker"] == ticker end)

        case ticker_data do
          nil ->
            {:error, "ticker not found"}

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
  @spec submissions(cik :: String.t()) :: success_type(map()) | error_type()
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
  @spec company_facts(cik :: String.t()) :: success_type(map()) | error_type()
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
  @spec company_concept(cik :: String.t(), taxonomy :: String.t(), tag :: String.t()) ::
          success_type(map()) | error_type()
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
  @spec frames(
          taxonomy :: String.t(),
          tag :: String.t(),
          unit :: String.t(),
          period :: String.t()
        ) ::
          success_type(map()) | error_type()
  def frames(taxonomy, tag, unit, period) do
    "#{@edgar_data_url}/api/xbrl/frames/#{taxonomy}/#{tag}/#{unit}/#{period}.json"
    |> get_json()
  end

  @doc """
  Fetches a list of filings from the submissions file

  ## Required

  * `cik` - The CIK of the entity

  ## Optional

  * `form_type` - The form type of the filing
  * `offset` - The offset of the filings
  * `limit` - The limit of the filings
  """
  @spec filings(cik :: String.t(), opt :: Map.t()) :: success_type(list()) | error_type()
  def filings(cik, opts \\ %{}) do
    case submissions(cik) do
      {:ok, submissions} ->
        filings =
          submissions
          |> get_recent_filings()
          |> append_file_filings(submissions["filings"]["files"])
          |> form_type(opts[:form_type])
          |> offset(opts[:offset])
          |> limit(opts[:limit])

        {:ok, filings}

      error ->
        error
    end
  end

  defp get_recent_filings(submissions) do
    submissions["filings"]["recent"] |> format_filings()
  end

  defp append_file_filings(filings, files) do
    formatted_file_filings =
      Enum.flat_map(files, fn file ->
        {:ok, file_data} = get_json("#{@edgar_data_url}/submissions/#{file["name"]}")
        format_filings(file_data)
      end)

    filings ++ formatted_file_filings
  end

  defp form_type(filings, form_type) when is_nil(form_type), do: filings

  defp form_type(filings, form_type) do
    Enum.filter(filings, fn filing -> filing["form"] == form_type end)
  end

  defp offset(filings, offset) when is_nil(offset), do: filings

  defp offset(filings, offset) do
    Enum.drop(filings, offset)
  end

  defp limit(filings, limit) when is_nil(limit), do: filings

  defp limit(filings, limit) do
    Enum.take(filings, limit)
  end

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

    Enum.zip(for name <- field_names, do: Map.get(filings, name))
    |> Enum.map(fn tuple ->
      Map.new(Enum.zip(field_names, Tuple.to_list(tuple)))
    end)
  end

  @doc """
  Parses form 3 and 3/A filing types from a given CIK and accession number

  Based on the XML schema found here:
  - https://www.sec.gov/info/edgar/specifications/ownershipxmltechspec

  ## Required

  * `cik` - The CIK of the entity
  * `accession_number` - The accession number of the filing
  """
  @spec form3_filing(cik :: String.t(), accession_number :: String.t()) ::
          success_type(map()) | error_type()
  def form3_filing(cik, accession_number), do: ownership_filing(cik, accession_number)

  @doc """
  Parses form 4 and 4/A filing types from a given CIK and accession number

  Based on the XML schema found here:
  - https://www.sec.gov/info/edgar/specifications/ownershipxmltechspec

  ## Required

  * `cik` - The CIK of the entity
  * `accession_number` - The accession number of the filing
  """
  @spec form4_filing(cik :: String.t(), accession_number :: String.t()) ::
          success_type(map()) | error_type()
  def form4_filing(cik, accession_number), do: ownership_filing(cik, accession_number)

  @doc """
  Parses form 5 and 5/A filing types from a given CIK and accession number

  Based on the XML schema found here:
  - https://www.sec.gov/info/edgar/specifications/ownershipxmltechspec

  ## Required

  * `cik` - The CIK of the entity
  * `accession_number` - The accession number of the filing
  """
  @spec form5_filing(cik :: String.t(), accession_number :: String.t()) ::
          success_type(map()) | error_type()
  def form5_filing(cik, accession_number), do: ownership_filing(cik, accession_number)

  @doc """
  Parses form 3, 3/A, 4, 4/A, 5, and 5/A ownership filing types from a given CIK and accession number

  Based on the XML schema found here:
  - https://www.sec.gov/info/edgar/specifications/ownershipxmltechspec

  ## Required

  * `cik` - The CIK of the entity
  * `accession_number` - The accession number of the filing
  """
  @spec ownership_filing(cik :: String.t(), accession_number :: String.t()) ::
          success_type(map()) | error_type()
  def ownership_filing(cik, accession_number) do
    case filing_directory(cik, accession_number) do
      {:ok, dir} ->
        files = dir["directory"]["item"]

        case Enum.find(files, fn file -> String.ends_with?(file["name"], ".xml") end) do
          nil ->
            {:error, "No xml file found"}

          xml_file ->
            acc_no = String.replace(accession_number, "-", "")
            xml_file_url = "#{@edgar_archives_url}/data/#{cik}/#{acc_no}/#{xml_file["name"]}"

            ownership_filing_from_url(xml_file_url)
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
  @spec form3_from_url(url :: String.t()) :: success_type(map()) | error_type()
  def form3_from_url(url), do: ownership_filing_from_url(url)

  @doc """
  Parses form 4 and 4/A ownership filing types from a given url

  ## Required

  * `url` - The url of the form 3 filing
  """
  @spec form4_from_url(url :: String.t()) :: success_type(map()) | error_type()
  def form4_from_url(url), do: ownership_filing_from_url(url)

  @doc """
  Parses form 5 and 5/A ownership filing types from a given url

  ## Required

  * `url` - The url of the form 3 filing
  """
  @spec form5_from_url(url :: String.t()) :: success_type(map()) | error_type()
  def form5_from_url(url), do: ownership_filing_from_url(url)

  @doc """
  Parses form 3, 3/A, 4, 4/A, 5, and 5/A ownership filing types from a given url

  Based on the XML schema found here:
  - https://www.sec.gov/info/edgar/specifications/ownershipxmltechspec

  ## Required

  * `url` - The url of the form 4 filing
  """
  @spec ownership_filing_from_url(url :: String.t()) :: success_type(map()) | error_type()
  def ownership_filing_from_url(url) do
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
  @spec parse_ownership_form(document :: String.t()) :: success_type(map()) | error_type()
  def parse_ownership_form(document), do: EDGAR.Native.parse_ownership_form(document)

  @doc """

  Parses a form 13F filing for a given CIK and accession number

  ## Required

  * `cik` - The CIK of the entity
  * `accession_number` - The accession number of the filing
  """
  @spec form13f_filing(cik :: String.t(), accession_number :: String.t()) ::
          success_type(map()) | error_type()
  def form13f_filing(cik, accession_number) do
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

          with {:ok, document} <- form13f_document_from_url(primary_doc_url),
               {:ok, table} <- form13f_table_from_url(table_xml_url) do
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
  @spec form13f_document_from_url(url :: String.t()) :: success_type(map()) | error_type()
  def form13f_document_from_url(url) do
    with {:ok, body} <- get(url),
         result <- parse_form13f_document(body) do
      result
    end
  end

  @doc """
  Parses a form 13F filing table from a given url

  ## Required

  * `url` - The url of the form 13F table filing
  """
  @spec form13f_table_from_url(url :: String.t()) :: success_type(map()) | error_type()
  def form13f_table_from_url(url) do
    with {:ok, body} <- get(url),
         result <- parse_form13f_table(body) do
      result
    end
  end

  @doc """
  Parses a form 13F filing primary document

  ## Required

  * `xml` - The document xml to parse
  """
  @spec parse_form13f_document(xml :: String.t()) :: success_type(map()) | error_type()
  def parse_form13f_document(xml), do: EDGAR.Native.parse_form13f_document(xml)

  @doc """
  Parses a form 13F filing table

  ## Required

  * `xml` - The table xml to parse
  """
  @spec parse_form13f_table(xml :: String.t()) :: success_type(map()) | error_type()
  def parse_form13f_table(xml), do: EDGAR.Native.parse_form13f_table(xml)

  @doc """
  Parses a xbrl filing from a given url

  ## Required

  * `url` - The url of the xbrl filing
  """
  @spec xbrl_from_url(url :: String.t()) :: success_type(map()) | error_type()
  def xbrl_from_url(url) do
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
  @spec parse_xbrl(xml :: String.t()) :: success_type(map()) | error_type()
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
  @spec current_feed(opts :: Map.t()) :: success_type(map()) | error_type()
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
  @spec parse_current_feed(xml :: String.t()) :: success_type(map()) | error_type()
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
  @spec company_feed(cik :: String.t(), opts :: Map.t()) :: success_type(map()) | error_type()
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
  @spec parse_company_feed(xml :: String.t()) :: success_type(map()) | error_type()
  def parse_company_feed(xml), do: EDGAR.Native.parse_company_feed(xml)

  @doc """
  Fetches the press release feed
  """
  @spec press_release_feed :: success_type(map()) | error_type()
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
  @spec speeches_and_statements_feed :: success_type(map()) | error_type()
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
  @spec speeches_feed :: success_type(map()) | error_type()
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
  @spec testimony_feed :: success_type(map()) | error_type()
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
  @spec statements_feed :: success_type(map()) | error_type()
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
  @spec litigation_feed :: success_type(map()) | error_type()
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
  @spec administrative_proceedings_feed :: success_type(map()) | error_type()
  def administrative_proceedings_feed do
    url = "https://www.sec.gov/rss/litigation/admin.xml"

    with {:ok, body} <- get(url),
         result <- parse_rss_feed(body) do
      result
    end
  end

  @doc """
  Fetches the trading suspensions feed
  """
  @spec trading_suspensions_feed :: success_type(map()) | error_type()
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
  @spec division_of_corporation_finance_feed :: success_type(map()) | error_type()
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
  @spec division_of_investment_management_feed :: success_type(map()) | error_type()
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
  @spec investor_alerts_feed :: success_type(map()) | error_type()
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
  @spec parse_rss_feed(xml :: String.t()) :: success_type(map()) | error_type()
  def parse_rss_feed(xml), do: EDGAR.Native.parse_rss_feed(xml)

  @doc false
  defp get_json(url) do
    case get(url) do
      {:ok, body} ->
        {:ok, Jason.decode!(body)}

      {:error, _} = error ->
        error
    end
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
          {:error, "resource not found"}

        {:ok, %HTTPoison.Response{status_code: code}} ->
          {:error, "unexpected status code: #{code}"}

        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, reason}
      end
    end)
  end
end
