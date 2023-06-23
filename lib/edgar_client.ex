defmodule EDGARClient do
  use Application

  def start(_type, _args) do
    children = [
      {SimpleRateLimiter, interval: 1_000, max: 10}
    ]

    opts = [strategy: :one_for_one, name: EDGARClient.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Fetches submissions for a given CIK

    ## Examples

      iex> EDGARClient.get_submissions("0000320193")
      {:ok, submissions_data}
  """
  def get_submissions(cik) do
    "https://data.sec.gov/submissions/CIK#{cik}.json"
    |> EDGARClient.get()
  end

  @doc """
  Fetches company facts for a given CIK

    ## Examples

      iex> EDGARClient.get_company_facts("0000320193")
      {:ok, company_facts_data}
  """
  def get_company_facts(cik) do
    "https://data.sec.gov/api/xbrl/companyfacts/CIK#{cik}.json"
    |> EDGARClient.get()
  end

  @doc """
  Fetches company concepts for a given CIK and concept (taxonomy, tag)

    ## Examples

      iex> EDGARClient.get_company_concept("0000320193", "us-gaap", "AccountsPayableCurrent")
      {:ok, company_concept_data}
  """
  def get_company_concept(cik, taxonomy, tag) do
    "https://data.sec.gov/api/xbrl/companyconcept/CIK#{cik}/#{taxonomy}/#{tag}.json"
    |> EDGARClient.get()
  end

  @doc """
  Fetches frames for a given taxonomy, concept, unit, and period

    ## Examples

      iex> EDGARClient.get_frames("us-gaap", "AccountsPayableCurrent", "USD", "CY2019Q1I")
      {:ok, frames_data}
  """
  def get_frames(taxonomy, tag, unit, period) do
    "https://data.sec.gov/api/xbrl/frames/#{taxonomy}/#{tag}/#{unit}/#{period}.json"
    |> EDGARClient.get()
  end

  @doc """
  Makes a GET request to the specified URL, returns parsed JSON body if successful
  The request is rate limited to 10 requests per second to avoid hitting the SEC rate limit
  The User-Agent header is set to abide by the Internet Security Policy.

  ## Examples

    iex> EDGARClient.get("https://data.sec.gov/api/xbrl/companyfacts/CIK0000320193.json")
    {:ok, company_facts_data}
  """
  def get(url) do
    SimpleRateLimiter.wait_and_proceed(fn ->
      resp = HTTPoison.get(url, [{"User-Agent", "example <example@example.com>"}])
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
