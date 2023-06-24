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

  ## Examples

      iex> {:ok, entity_directory} = EDGAR.get_entity_directory("320193")
      iex> entity_directory.directory.name
      "/Archives/edgar/data/320193"
  """
  def get_entity_directory(cik) do
    cik = String.pad_leading(cik, 10, "0")

    "#{@edgar_archives_url}/data/#{cik}/index.json"
    |> get()
  end

  @doc """
  Fetches the filing directory

  ## Examples

      iex> {:ok, filing_directory} = EDGAR.get_filing_directory("320193", "000032019320000010")
      iex> filing_directory.directory.name
      "/Archives/edgar/data/320193/000032019320000010"
  """
  def get_filing_directory(cik, accession_number) do
    accession_number = String.replace(accession_number, "-", "")

    "#{@edgar_archives_url}/data/#{cik}/#{accession_number}/index.json"
    |> get()
  end

  @doc """
  Fetches a list of company tickers

  ## Examples

      iex> {:ok, company_tickers} = EDGAR.get_company_tickers()
      iex> Enum.count(company_tickers) > 0
      true
  """
  def get_company_tickers() do
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

  ## Examples

      iex> {:ok, cik} = EDGAR.get_cik_for_ticker("AAPL")
      iex> cik
      "320193"
  """
  def get_cik_for_ticker(ticker) do
    ticker = String.upcase(ticker)

    case get_company_tickers() do
      {:ok, tickers} ->
        ticker_data = Enum.find(tickers, fn t -> t[:ticker] == ticker end)

        case ticker_data do
          nil ->
            {:error, :not_found}

          _ ->
            {:ok, Integer.to_string(ticker_data[:cik_str])}
        end

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Fetches submissions for a given CIK

  ## Examples

      iex> {:ok, submissions} = EDGAR.get_submissions("320193")
      iex> submissions.cik
      "320193"
  """
  def get_submissions(cik) do
    cik = String.pad_leading(cik, 10, "0")

    "#{@edgar_data_url}/submissions/CIK#{cik}.json"
    |> get()
  end

  @doc """
  Fetches company facts for a given CIK

  ## Examples

      iex> {:ok, company_facts} = EDGAR.get_company_facts("320193")
      iex> company_facts.cik
      320193
  """
  def get_company_facts(cik) do
    cik = String.pad_leading(cik, 10, "0")

    "#{@edgar_data_url}/api/xbrl/companyfacts/CIK#{cik}.json"
    |> get()
  end

  @doc """
  Fetches company concepts for a given CIK and concept (taxonomy, tag)

  ## Examples

      iex> {:ok, company_concept} = EDGAR.get_company_concept("320193", "us-gaap", "AccountsPayableCurrent")
      iex> company_concept.cik
      320193
  """
  def get_company_concept(cik, taxonomy, tag) do
    cik = String.pad_leading(cik, 10, "0")

    "#{@edgar_data_url}/api/xbrl/companyconcept/CIK#{cik}/#{taxonomy}/#{tag}.json"
    |> get()
  end

  @doc """
  Fetches frames for a given taxonomy, concept, unit, and period

  ## Examples

      iex> {:ok, frames} = EDGAR.get_frames("us-gaap", "AccountsPayableCurrent", "USD", "CY2019Q1I")
      iex> frames.tag
      "AccountsPayableCurrent"
  """
  def get_frames(taxonomy, tag, unit, period) do
    "#{@edgar_data_url}/api/xbrl/frames/#{taxonomy}/#{tag}/#{unit}/#{period}.json"
    |> get()
  end

  @doc false
  def get(url) do
    SimpleRateLimiter.wait_and_proceed(fn ->
      user_agent =
        Application.get_env(:edgar_client, :user_agent, "default <default@default.com>")

      resp =
        HTTPoison.get(url, [{"User-Agent", user_agent}], follow_redirect: true)

      case resp do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          {:ok, Jason.decode!(body, keys: :atoms)}

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
