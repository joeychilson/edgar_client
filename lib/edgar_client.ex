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
  """
  def get_submissions(cik) do
    "https://data.sec.gov/submissions/CIK#{cik}.json"
    |> EDGARClient.get()
  end

  @doc """
  Makes a GET request to the specified URL, returns parsed JSON body if successful
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
