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
  Parses a form 4 filing from a given CIK and accession number

  ## Required

  * `cik` - The CIK of the entity
  * `accession_number` - The accession number of the filing
  """
  def parse_form4_filing(cik, accession_number) do
    case filing_directory(cik, accession_number) do
      {:ok, dir} ->
        files = dir["directory"]["item"]

        case Enum.find(files, fn file -> String.ends_with?(file["name"], ".xml") end) do
          nil ->
            {:error, "No xml file found"}

          xml_file ->
            acc_no = String.replace(accession_number, "-", "")
            xml_file_url = "#{@edgar_archives_url}/data/#{cik}/#{acc_no}/#{xml_file["name"]}"

            parse_form4_from_url(xml_file_url)
        end

      error ->
        error
    end
  end

  @doc """
  Parses a form 4 filing from a given url

  ## Required

  * `url` - The url of the form 4 filing
  """
  def parse_form4_from_url(url) do
    with {:ok, body} <- get(url),
         result <- parse_form4(body) do
      result
    end
  end

  @doc """
  Parses a form 4 filing

  ## Required

  * `document` - The document xml to parse
  """
  def parse_form4(document), do: EDGAR.Native.parse_form4(document)

  @doc """

  Parses a 13F filing for a given CIK and accession number

  ## Required

  * `cik` - The CIK of the entity
  * `accession_number` - The accession number of the filing
  """
  def parse_13f_filing(cik, accession_number) do
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

          with {:ok, document} <- parse_13f_document_from_url(primary_doc_url),
               {:ok, table} <- parse_13f_table_from_url(table_xml_url) do
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
  Parses a 13F filing from a given url

  ## Required

  * `url` - The url of the 13F document filing

  """
  def parse_13f_document_from_url(url) do
    with {:ok, body} <- get(url),
         result <- parse_13f_document(body) do
      result
    end
  end

  @doc """
  Parses a 13F filing table from a given url

  ## Required

  * `url` - The url of the 13F table filing
  """
  def parse_13f_table_from_url(url) do
    with {:ok, body} <- get(url),
         result <- parse_13f_table(body) do
      result
    end
  end

  @doc """
  Parses a 13F filing primary document

  ## Required

  * `document` - The document xml to parse
  """
  def parse_13f_document(document), do: EDGAR.Native.parse_13f_document(document)

  @doc """

  Parses a 13F filing table

  ## Required

  * `table` - The table xml to parse
  """
  def parse_13f_table(table), do: EDGAR.Native.parse_13f_table(table)

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
