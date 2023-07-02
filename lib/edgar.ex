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

  ## Examples

    iex> {:ok, entity_directory} = EDGAR.entity_directory("320193")
    iex> entity_directory["directory"]["name"]
    "/Archives/edgar/data/320193"
  """
  def entity_directory(cik) do
    cik = String.pad_leading(cik, 10, "0")

    "#{@edgar_archives_url}/data/#{cik}/index.json"
    |> get()
  end

  @doc """
  Fetches the filing directory

  ## Required

  * `cik` - The CIK of the entity
  * `accession_number` - The accession number of the filing

  ## Examples

    iex> {:ok, filing_directory} = EDGAR.filing_directory("320193", "000032019320000010")
    iex> filing_directory["directory"]["name"]
    "/Archives/edgar/data/320193/000032019320000010"
  """
  def filing_directory(cik, accession_number) do
    accession_number = String.replace(accession_number, "-", "")

    "#{@edgar_archives_url}/data/#{cik}/#{accession_number}/index.json"
    |> get()
  end

  @doc """
  Fetches a list of company tickers

  ## Examples

    iex> {:ok, company_tickers} = EDGAR.company_tickers()
    iex> Enum.count(company_tickers) > 0
    true
  """
  def company_tickers() do
    resp = get("#{@edgar_files_url}/company_tickers.json")

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

  ## Examples

    iex> {:ok, cik} = EDGAR.cik_for_ticker("AAPL")
    iex> cik
    "320193"
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

  ## Examples

    iex> {:ok, submissions} = EDGAR.submissions("320193")
    iex> submissions["cik"]
    "320193"
  """
  def submissions(cik) do
    cik = String.pad_leading(cik, 10, "0")

    "#{@edgar_data_url}/submissions/CIK#{cik}.json"
    |> get()
  end

  @doc """
  Fetches company facts for a given CIK

  ## Required

  * `cik` - The CIK of the entity

  ## Examples

    iex> {:ok, company_facts} = EDGAR.company_facts("320193")
    iex> company_facts["cik"]
    320193
  """
  def company_facts(cik) do
    cik = String.pad_leading(cik, 10, "0")

    "#{@edgar_data_url}/api/xbrl/companyfacts/CIK#{cik}.json"
    |> get()
  end

  @doc """
  Fetches company concepts for a given CIK and concept (taxonomy, tag)

  ## Required

  * `cik` - The CIK of the entity
  * `taxonomy` - The taxonomy of the concept
  * `tag` - The tag of the concept

  ## Examples

    iex> {:ok, company_concept} = EDGAR.company_concept("320193", "us-gaap", "AccountsPayableCurrent")
    iex> company_concept["cik"]
    320193
  """
  def company_concept(cik, taxonomy, tag) do
    cik = String.pad_leading(cik, 10, "0")

    "#{@edgar_data_url}/api/xbrl/companyconcept/CIK#{cik}/#{taxonomy}/#{tag}.json"
    |> get()
  end

  @doc """
  Fetches frames for a given taxonomy, concept, unit, and period

  ## Required

  * `taxonomy` - The taxonomy of the concept
  * `tag` - The tag of the concept
  * `unit` - The unit of the concept
  * `period` - The period of the concept

  ## Examples

    iex> {:ok, frames} = EDGAR.frames("us-gaap", "AccountsPayableCurrent", "USD", "CY2019Q1I")
    iex> frames["tag"]
    "AccountsPayableCurrent"
  """
  def frames(taxonomy, tag, unit, period) do
    "#{@edgar_data_url}/api/xbrl/frames/#{taxonomy}/#{tag}/#{unit}/#{period}.json"
    |> get()
  end

  @doc """
  Fetches a list of filings from the submissions file

  ## Required

  * `cik` - The CIK of the entity

  ## Examples

    iex> {:ok, filings} = EDGAR.filings("320193")
    iex> Enum.count(filings) > 0
    true
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
            {:ok, file_data} = get("#{@edgar_data_url}/submissions/#{file_name}")
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

  ## Examples

    iex> {:ok, filings} = EDGAR.filings_by_forms("320193", ["10-K", "10-Q"])
    iex> Enum.count(filings) > 0
    true
  """
  def filings_by_forms(cik, forms) do
    case filings(cik) do
      {:ok, filings} ->
        {:ok, Enum.filter(filings, fn filing -> filing["form"] in forms end)}

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
          {:ok, Jason.decode!(body)}

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
