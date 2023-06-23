defmodule EDGARClient do
  use Application

  def start(_type, _args) do
    children = [
      {SimpleRateLimiter, interval: 1_000, max: 10}
    ]

    opts = [strategy: :one_for_one, name: EDGARClient.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @edgar_archives_url "https://www.sec.gov/Archives/edgar"
  @edgar_data_url "https://data.sec.gov"
  @edgar_files_url "https://www.sec.gov/files"

  @doc """
  Fetches the entity directory

    ## Examples

      iex> {:ok, entity_directory} = EDGARClient.get_entity_directory("320193")
      iex> entity_directory.directory.name
      "/Archives/edgar/data/320193"
  """
  def get_entity_directory(cik) do
    cik = String.pad_leading(cik, 10, "0")

    "#{@edgar_archives_url}/data/#{cik}/index.json"
    |> EDGARClient.get()
  end

  @doc """
  Fetches the filing directory

    ## Examples

      iex> {:ok, filing_directory} = EDGARClient.get_filing_directory("320193", "000032019320000010")
      iex> filing_directory.directory.name
      "/Archives/edgar/data/320193/000032019320000010"
  """
  def get_filing_directory(cik, accession_number) do
    accession_number = String.replace(accession_number, "-", "")

    "#{@edgar_archives_url}/data/#{cik}/#{accession_number}/index.json"
    |> EDGARClient.get()
  end

  @doc """
  Fetches a list of company tickers

    ## Examples

      iex> {:ok, company_tickers} = EDGARClient.get_company_tickers()
      iex> Enum.count(company_tickers) > 0
      true
  """
  def get_company_tickers() do
    resp = EDGARClient.get("#{@edgar_files_url}/company_tickers.json")
    case resp do
      {:ok, result} ->
        {:ok, Map.values(result)}
      _ ->
        resp
    end
  end

  @doc """
  Fetches submissions for a given CIK

    ## Examples

      iex> {:ok, submissions} = EDGARClient.get_submissions("320193")
      iex> submissions.cik
      "320193"
  """
  def get_submissions(cik) do
    cik = String.pad_leading(cik, 10, "0")

    "#{@edgar_data_url}/submissions/CIK#{cik}.json"
    |> EDGARClient.get()
  end

  @doc """
  Fetches company facts for a given CIK

    ## Examples

      iex> {:ok, company_facts} = EDGARClient.get_company_facts("320193")
      iex> company_facts.cik
      320193
  """
  def get_company_facts(cik) do
    cik = String.pad_leading(cik, 10, "0")

    "#{@edgar_data_url}/api/xbrl/companyfacts/CIK#{cik}.json"
    |> EDGARClient.get()
  end

  @doc """
  Fetches company concepts for a given CIK and concept (taxonomy, tag)

    ## Examples

      iex> {:ok, company_concept} = EDGARClient.get_company_concept("320193", "us-gaap", "AccountsPayableCurrent")
      iex> company_concept.cik
      320193
  """
  def get_company_concept(cik, taxonomy, tag) do
    cik = String.pad_leading(cik, 10, "0")

    "#{@edgar_data_url}/api/xbrl/companyconcept/CIK#{cik}/#{taxonomy}/#{tag}.json"
    |> EDGARClient.get()
  end

  @doc """
  Fetches frames for a given taxonomy, concept, unit, and period

    ## Examples

      iex> {:ok, frames} = EDGARClient.get_frames("us-gaap", "AccountsPayableCurrent", "USD", "CY2019Q1I")
      iex> frames.tag
      "AccountsPayableCurrent"
  """
  def get_frames(taxonomy, tag, unit, period) do
    "#{@edgar_data_url}/api/xbrl/frames/#{taxonomy}/#{tag}/#{unit}/#{period}.json"
    |> EDGARClient.get()
  end

  @doc """
  Makes a GET request to the specified URL, returns parsed JSON body if successful
  The request is rate limited to 10 requests per second to avoid hitting the SEC rate limit
  The User-Agent header is set to abide by the Internet Security Policy.

  ## Examples

    iex> {:ok, company_facts} = EDGARClient.get("https://data.sec.gov/api/xbrl/companyfacts/CIK0000320193.json")
    iex> company_facts.cik
    320193
  """
  def get(url) do
    SimpleRateLimiter.wait_and_proceed(fn ->
      resp =
        HTTPoison.get(url, [{"User-Agent", "example <example@example.com>"}],
          follow_redirect: true
        )

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
