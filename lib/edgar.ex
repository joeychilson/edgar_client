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
  Fetches a list of company tickers
  """
  @spec company_tickers :: success_type(list()) | error_type()
  def company_tickers() do
    case get("#{@edgar_files_url}/company_tickers.json") do
      {:ok, result} ->
        {:ok, Map.values(result)}

      error ->
        error
    end
  end

  @doc """
  Fetches a list of company tickers with exchange
  """
  @spec company_tickers_with_exchange :: success_type(list()) | error_type()
  def company_tickers_with_exchange do
    case get("#{@edgar_files_url}/company_tickers_exchange.json") do
      {:ok, %{"data" => data, "fields" => fields}} ->
        result = for row <- data, into: [], do: Enum.zip(fields, row) |> Enum.into(%{})
        {:ok, result}

      error ->
        error
    end
  end

  @doc """
  Fetches a list of mutual fund tickers
  """
  @spec mutual_fund_tickers :: success_type(list()) | error_type()
  def mutual_fund_tickers do
    case get("#{@edgar_files_url}/company_tickers_mf.json") do
      {:ok, %{"data" => data, "fields" => fields}} ->
        result = for row <- data, into: [], do: Enum.zip(fields, row) |> Enum.into(%{})
        {:ok, result}

      error ->
        error
    end
  end

  @doc """
  Fetches a CIK for a given company ticker

  ## Required

  * `ticker` - The ticker of the company
  """
  @spec company_cik(ticker :: String.t()) :: success_type(String.t()) | error_type()
  def company_cik(ticker) do
    upcase_ticker = String.upcase(ticker)

    case company_tickers() do
      {:ok, tickers} ->
        ticker_data = Enum.find(tickers, fn t -> t["ticker"] == upcase_ticker end)

        case ticker_data do
          nil ->
            {:error, "ticker not found"}

          _ ->
            {:ok, ticker_data["cik_str"]}
        end

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Fetches a CIK for a given mutual fund ticker

  ## Required

  * `ticker` - The ticker of the mutual fund
  """
  @spec mutual_fund_cik(ticker :: String.t()) :: success_type(String.t()) | error_type()
  def mutual_fund_cik(ticker) do
    upcase_ticker = String.upcase(ticker)

    case mutual_fund_tickers() do
      {:ok, tickers} ->
        ticker_data = Enum.find(tickers, fn t -> t["symbol"] == upcase_ticker end)

        case ticker_data do
          nil ->
            {:error, "ticker not found"}

          _ ->
            {:ok, ticker_data["cik"]}
        end

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Fetches the entity directory

  ## Required

  * `cik` - The CIK of the entity
  """
  @spec entity_directory(cik :: String.t()) :: success_type(map()) | error_type()
  def entity_directory(cik) do
    padded_cik = String.pad_leading(cik, 10, "0")

    case get("#{@edgar_archives_url}/data/#{padded_cik}/index.json") do
      {:ok, resp} ->
        Jason.decode(resp)

      error ->
        error
    end
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
    formatted_acc_no = String.replace(accession_number, "-", "")

    case get("#{@edgar_archives_url}/data/#{cik}/#{formatted_acc_no}/index.json") do
      {:ok, resp} ->
        Jason.decode(resp)

      error ->
        error
    end
  end

  @doc """
  Fetches the daily index

  ## Optional

  * `year` - The year of the daily index (must be 1994 or greater)
  * `quarter` - The quarter of the daily index
  """
  @spec daily_index(year :: nil | integer(), quarter :: nil | integer()) ::
          success_type(map()) | error_type()
  def daily_index(year \\ nil, quarter \\ nil) do
    case {year, quarter} do
      {nil, nil} ->
        get("#{@edgar_archives_url}/daily-index/index.json")

      {year, _} when year < 1994 ->
        {:error, "year must be 1994 or greater"}

      {year, nil} ->
        get("#{@edgar_archives_url}/daily-index/#{Integer.to_string(year)}/index.json")

      {_, quarter} when quarter < 1 or quarter > 4 ->
        {:error, "quarter must be between 1 and 4"}

      {year, quarter} ->
        year_str = Integer.to_string(year)
        quarter_str = Integer.to_string(quarter)
        get("#{@edgar_archives_url}/daily-index/#{year_str}/QTR#{quarter_str}/index.json")
    end
  end

  @doc """
  Fetches the full index

  ## Optional

  * `year` - The year of the full index (must be 1994 or greater)
  * `quarter` - The quarter of the full index
  """
  @spec full_index(year :: nil | integer(), quarter :: nil | integer()) ::
          success_type(map()) | error_type()
  def full_index(year \\ nil, quarter \\ nil) do
    case {year, quarter} do
      {nil, nil} ->
        get("#{@edgar_archives_url}/full-index/index.json")

      {year, _} when year < 1994 ->
        {:error, "year must be 1994 or greater"}

      {year, nil} ->
        get("#{@edgar_archives_url}/full-index/#{Integer.to_string(year)}/index.json")

      {_, quarter} when quarter < 1 or quarter > 4 ->
        {:error, "quarter must be between 1 and 4"}

      {year, quarter} ->
        year_str = Integer.to_string(year)
        quarter_str = Integer.to_string(quarter)
        get("#{@edgar_archives_url}/full-index/#{year_str}/QTR#{quarter_str}/index.json")
    end
  end

  @doc """
  Parses a company index file from url

  ## Required

  * `url` - The url to the company index file to parse
  """
  @spec company_index_from_url(url :: String.t()) :: success_type(list(map())) | error_type()
  def company_index_from_url(url) do
    with {:ok, file} <- get(url), do: company_index_from_string(file)
  end

  @doc """
  Parses a company index file from file

  ## Required

  * `file_path` - The path to the company index file to parse
  """
  @spec company_index_from_file(file_path :: String.t()) ::
          success_type(list(map())) | error_type()
  def company_index_from_file(file_path) do
    with {:ok, file_content} <- File.read(file_path), do: company_index_from_string(file_content)
  end

  @doc """
  Parses a company index file from string

  ## Required

  * `file_content` - The content of the company index file to parse
  """
  @spec company_index_from_string(file_content :: String.t()) ::
          success_type(list(map())) | error_type()
  def company_index_from_string(file_content) do
    file_content
    |> String.split("\n")
    |> Enum.drop_while(&(!String.match?(&1, ~r/^-+$/)))
    |> Enum.drop(1)
    |> Stream.map(fn line ->
      case Regex.scan(~r/(.{60})(.{10})(.{12})(.{14})(.+)/, String.trim(line)) do
        [match] ->
          [_, company_name, form_type, cik, date_filed, file_name] =
            Enum.map(match, &String.trim/1)

          %{
            "company_name" => company_name,
            "form_type" => form_type,
            "cik" => cik,
            "date_filed" => date_filed,
            "file_name" => file_name
          }

        _ ->
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> (&{:ok, &1}).()
  end

  @doc """
  Parses a crawler index file from url

  ## Required

  * `url` - The url to the crawler index file to parse
  """
  @spec crawler_index_from_url(url :: String.t()) :: success_type(list(map())) | error_type()
  def crawler_index_from_url(url) do
    with {:ok, file} <- get(url), do: crawler_index_from_string(file)
  end

  @doc """
  Parses a crawler index file from file

  ## Required

  * `file_path` - The path to the crawler index file to parse
  """
  @spec crawler_index_from_file(file_path :: String.t()) ::
          success_type(list(map())) | error_type()
  def crawler_index_from_file(file_path) do
    with {:ok, file_content} <- File.read(file_path), do: crawler_index_from_string(file_content)
  end

  @doc """
  Parses a crawler index file from a string

  ## Required

  * `file_content` - The content of the crawler index file to parse
  """
  def crawler_index_from_string(file_content) do
    file_content
    |> String.split("\n")
    |> Enum.drop_while(&(!String.match?(&1, ~r/^-+$/)))
    |> Enum.drop(1)
    |> Stream.map(fn line ->
      case Regex.scan(~r/(.{60})(.{10})(.{12})(.{12})(.+)/, String.trim(line)) do
        [match] ->
          [_, company_name, form_type, cik, date_filed, url] =
            Enum.map(match, &String.trim/1)

          %{
            "company_name" => company_name,
            "form_type" => form_type,
            "cik" => cik,
            "date_filed" => date_filed,
            "url" => url
          }

        _ ->
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> (&{:ok, &1}).()
  end

  @doc """
  Parses a form index file from url

  ## Required

  * `url` - The url to the form index file to parse
  """
  @spec form_index_from_url(url :: String.t()) :: success_type(list(map())) | error_type()
  def form_index_from_url(url) do
    with {:ok, file} <- get(url), do: form_index_from_string(file)
  end

  @doc """
  Parses a form index file from file

  ## Required

  * `file_path` - The path to the form index file to parse
  """
  @spec form_index_from_file(file_path :: String.t()) ::
          success_type(list(map())) | error_type()
  def form_index_from_file(file_path) do
    with {:ok, file_content} <- File.read(file_path), do: form_index_from_string(file_content)
  end

  @doc """
  Parses a form index file from a string

  ## Required

  * `file_content` - The content of the form index file to parse
  """
  def form_index_from_string(file_content) do
    file_content
    |> String.split("\n")
    |> Enum.drop_while(&(!String.match?(&1, ~r/^-+$/)))
    |> Enum.drop(1)
    |> Stream.map(fn line ->
      case Regex.scan(~r/(.{10})(.{60})(.{12})(.{12})(.+)/, String.trim(line)) do
        [match] ->
          [_, form_type, company_name, cik, date_filed, file_name] =
            Enum.map(match, &String.trim/1)

          %{
            "form_type" => form_type,
            "company_name" => company_name,
            "cik" => cik,
            "date_filed" => date_filed,
            "file_name" => file_name
          }

        _ ->
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> (&{:ok, &1}).()
  end

  @doc """
  Parses a xbrl index file from url

  ## Required

  * `url` - The url to the xbrl file to parse
  """
  @spec xbrl_index_from_url(url :: String.t()) :: success_type(list(map())) | error_type()
  def xbrl_index_from_url(url) do
    with {:ok, file} <- get(url), do: xbrl_index_from_string(file)
  end

  @doc """
  Parses a xbrl index file from file

  ## Required

  * `file_path` - The path to the xbrl file to parse
  """
  @spec xbrl_index_from_file(file_path :: String.t()) ::
          success_type(list(map())) | error_type()
  def xbrl_index_from_file(file_path) do
    with {:ok, file_content} <- File.read(file_path), do: xbrl_index_from_string(file_content)
  end

  @doc """
  Parses a xbrl index file from a string

  ## Required

  * `file_content` - The content of the xbrl index file to parse
  """
  def xbrl_index_from_string(file_content) do
    file_content
    |> String.split("\n")
    |> Enum.drop_while(&(!String.match?(&1, ~r/^-+$/)))
    |> Enum.drop(1)
    |> Stream.map(fn line ->
      case Regex.scan(~r/^(.*?)\|(.*?)\|(.*?)\|(.*?)\|(.*?)$/, String.trim(line)) do
        [match] ->
          [_, cik, company_name, form_type, date_filed, file_name] =
            Enum.map(match, &String.trim/1)

          %{
            "form_type" => form_type,
            "company_name" => company_name,
            "cik" => cik,
            "date_filed" => date_filed,
            "file_name" => file_name
          }

        _ ->
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> (&{:ok, &1}).()
  end

  @doc """
  Parses a master index file from url

  ## Required

  * `url` - The url to the master file to parse
  """
  @spec master_index_from_url(url :: String.t()) :: success_type(list(map())) | error_type()
  def master_index_from_url(url) do
    with {:ok, file} <- get(url), do: master_index_from_string(file)
  end

  @doc """
  Parses a master index file from file

  ## Required

  * `file_path` - The path to the master file to parse
  """
  @spec master_index_from_file(file_path :: String.t()) ::
          success_type(list(map())) | error_type()
  def master_index_from_file(file_path) do
    with {:ok, file_content} <- File.read(file_path), do: master_index_from_string(file_content)
  end

  @doc """
  Parses a master index file from a string

  ## Required

  * `file_content` - The content of the master index file to parse
  """
  def master_index_from_string(file_content) do
    file_content
    |> String.split("\n")
    |> Enum.drop_while(&(!String.match?(&1, ~r/^-+$/)))
    |> Enum.drop(1)
    |> Stream.map(fn line ->
      case Regex.scan(~r/^(.*?)\|(.*?)\|(.*?)\|(.*?)\|(.*?)$/, String.trim(line)) do
        [match] ->
          [_, cik, company_name, form_type, date_filed, file_name] =
            Enum.map(match, &String.trim/1)

          %{
            "form_type" => form_type,
            "company_name" => company_name,
            "cik" => cik,
            "date_filed" => date_filed,
            "file_name" => file_name
          }

        _ ->
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> (&{:ok, &1}).()
  end

  @doc """
  Fetches submissions for a given CIK

  ## Required

  * `cik` - The CIK of the entity
  """
  @spec submissions(cik :: String.t()) :: success_type(map()) | error_type()
  def submissions(cik) do
    padded_cik = String.pad_leading(cik, 10, "0")

    "#{@edgar_data_url}/submissions/CIK#{padded_cik}.json"
    |> get()
  end

  @doc """
  Fetches company facts for a given CIK

  ## Required

  * `cik` - The CIK of the entity
  """
  @spec company_facts(cik :: String.t()) :: success_type(map()) | error_type()
  def company_facts(cik) do
    padded_cik = String.pad_leading(cik, 10, "0")

    "#{@edgar_data_url}/api/xbrl/companyfacts/CIK#{padded_cik}.json"
    |> get()
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
    padded_cik = String.pad_leading(cik, 10, "0")

    "#{@edgar_data_url}/api/xbrl/companyconcept/CIK#{padded_cik}/#{taxonomy}/#{tag}.json"
    |> get()
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
    |> get()
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
  @spec filings(cik :: String.t(), opt :: map()) :: success_type(list()) | error_type()
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
        {:ok, file_data} = get("#{@edgar_data_url}/submissions/#{file["name"]}")
        format_filings(file_data)
      end)

    filings ++ formatted_file_filings
  end

  defp form_type(filings, form_type) when is_nil(form_type), do: filings

  defp form_type(filings, form_type),
    do: Enum.filter(filings, fn filing -> filing["form"] == form_type end)

  defp offset(filings, offset) when is_nil(offset), do: filings
  defp offset(filings, offset), do: Enum.drop(filings, offset)

  defp limit(filings, limit) when is_nil(limit), do: filings
  defp limit(filings, limit), do: Enum.take(filings, limit)

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
    |> Enum.map(fn tuple -> Map.new(Enum.zip(field_names, Tuple.to_list(tuple))) end)
  end

  @doc """
  Parses form 3 and 3/A filing types from a given CIK and accession number

  ## Required

  * `cik` - The CIK of the entity
  * `accession_number` - The accession number of the filing
  """
  @spec form3_from_filing(cik :: String.t(), accession_number :: String.t()) ::
          success_type(map()) | error_type()
  def form3_from_filing(cik, accession_number), do: ownership_from_filing(cik, accession_number)

  @doc """
  Parses form 3 and 3/A ownership filing types from a given file path

  ## Required

  * `file_path` - The path of the form 3 filing to parse
  """
  @spec form3_from_file(file_path :: String.t()) :: success_type(map()) | error_type()
  def form3_from_file(file_path), do: ownership_form_from_file(file_path)

  @doc """
  Parses form 3 and 3/A ownership filing types from a given url

  ## Required

  * `url` - The url of the form 3 filing
  """
  @spec form3_from_url(url :: String.t()) :: success_type(map()) | error_type()
  def form3_from_url(url), do: ownership_form_from_url(url)

  @doc """
  Parses form 3 and 3/A ownership filing types from a given string

  ## Required

  * `xml_str` - The xml string of the form 3 filing to parse
  """
  @spec form3_from_string(xml_str :: String.t()) :: success_type(map()) | error_type()
  def form3_from_string(xml_str), do: ownership_form_from_string(xml_str)

  @doc """
  Parses form 4 and 4/A filing types from a given CIK and accession number

  ## Required

  * `cik` - The CIK of the entity
  * `accession_number` - The accession number of the filing
  """
  @spec form4_from_filing(cik :: String.t(), accession_number :: String.t()) ::
          success_type(map()) | error_type()
  def form4_from_filing(cik, accession_number), do: ownership_from_filing(cik, accession_number)

  @doc """
  Parses form 4 and 4/A ownership filing types from a given file path

  ## Required

  * `file_path` - The path of the form 4 filing to parse
  """
  @spec form4_from_file(file_path :: String.t()) :: success_type(map()) | error_type()
  def form4_from_file(file_path), do: ownership_form_from_file(file_path)

  @doc """
  Parses form 4 and 4/A ownership filing types from a given url

  ## Required

  * `url` - The url of the form 3 filing
  """
  @spec form4_from_url(url :: String.t()) :: success_type(map()) | error_type()
  def form4_from_url(url), do: ownership_form_from_url(url)

  @doc """
  Parses form 4 and 4/A ownership filing types from a given string

  ## Required

  * `xml_str` - The xml string of the form 4 filing to parse
  """
  @spec form4_from_string(xml_str :: String.t()) :: success_type(map()) | error_type()
  def form4_from_string(xml_str), do: ownership_form_from_string(xml_str)

  @doc """
  Parses form 5 and 5/A filing types from a given CIK and accession number

  ## Required

  * `cik` - The CIK of the entity
  * `accession_number` - The accession number of the filing
  """
  @spec form5_from_filing(cik :: String.t(), accession_number :: String.t()) ::
          success_type(map()) | error_type()
  def form5_from_filing(cik, accession_number), do: ownership_from_filing(cik, accession_number)

  @doc """
  Parses form 5 and 5/A ownership filing types from a given file path

  ## Required

  * `file_path` - The path of the form 5 filing to parse
  """
  @spec form5_from_file(file_path :: String.t()) :: success_type(map()) | error_type()
  def form5_from_file(file_path), do: ownership_form_from_file(file_path)

  @doc """
  Parses form 5 and 5/A ownership filing types from a given url

  ## Required

  * `url` - The url of the form 3 filing
  """
  @spec form5_from_url(url :: String.t()) :: success_type(map()) | error_type()
  def form5_from_url(url), do: ownership_form_from_url(url)

  @doc """
  Parses form 5 and 5/A ownership filing types from a given string

  ## Required

  * `xml_str` - The xml string of the form 5 filing to parse
  """
  @spec form5_from_string(xml_str :: String.t()) :: success_type(map()) | error_type()
  def form5_from_string(xml_str), do: ownership_form_from_string(xml_str)

  @doc """
  Parses form 3, 3/A, 4, 4/A, 5, and 5/A ownership filing types from a given CIK and accession number

  ## Required

  * `cik` - The CIK of the entity
  * `accession_number` - The accession number of the filing
  """
  @spec ownership_from_filing(cik :: String.t(), accession_number :: String.t()) ::
          success_type(map()) | error_type()
  def ownership_from_filing(cik, accession_number) do
    case filing_directory(cik, accession_number) do
      {:ok, dir} ->
        files = dir["directory"]["item"]

        case Enum.find(files, fn file -> String.ends_with?(file["name"], ".xml") end) do
          nil ->
            {:error, "No xml file found"}

          xml_file ->
            acc_no = String.replace(accession_number, "-", "")
            xml_file_url = "#{@edgar_archives_url}/data/#{cik}/#{acc_no}/#{xml_file["name"]}"

            ownership_form_from_url(xml_file_url)
        end

      error ->
        error
    end
  end

  @doc """
  Parses form 3, 3/A, 4, 4/A, 5, and 5/A ownership filing types from a file

  ## Required

  * `file_path` - The path to the file
  """
  @spec ownership_form_from_file(file_path :: String.t()) :: success_type(map()) | error_type()
  def ownership_form_from_file(file_path) do
    with {:ok, body} <- File.read(file_path), do: ownership_form_from_string(body)
  end

  @doc """
  Parses form 3, 3/A, 4, 4/A, 5, and 5/A ownership filing types from a given url

  ## Required

  * `url` - The url of the form 4 to parse
  """
  @spec ownership_form_from_url(url :: String.t()) :: success_type(map()) | error_type()
  def ownership_form_from_url(url) do
    with {:ok, body} <- get(url), do: ownership_form_from_string(body)
  end

  @doc """
  Parses form 3, 3/A, 4, 4/A, 5, and 5/A filing types from a string

  ## Required

  * `form_str` - The document string to parse
  """
  @spec ownership_form_from_string(form_str :: String.t()) :: success_type(map()) | error_type()
  def ownership_form_from_string(form_str), do: EDGAR.Native.parse_ownership_form(form_str)

  @doc """

  Parses a form 13F filing for a given CIK and accession number

  ## Required

  * `cik` - The CIK of the entity
  * `accession_number` - The accession number of the filing
  """
  @spec form13f_from_filing(cik :: String.t(), accession_number :: String.t()) ::
          success_type(map()) | error_type()
  def form13f_from_filing(cik, accession_number) do
    case filing_directory(cik, accession_number) do
      {:ok, dir} ->
        files = dir["directory"]["item"]

        primary_doc_file = Enum.find(files, fn file -> file["name"] == "primary_doc.xml" end)

        table_xml_file =
          Enum.find(files, fn file ->
            file["name"] != "primary_doc.xml" and String.ends_with?(file["name"], ".xml")
          end)

        if primary_doc_file && table_xml_file do
          formatted_acc_no = String.replace(accession_number, "-", "")

          primary_doc_url =
            "#{@edgar_archives_url}/data/#{cik}/#{formatted_acc_no}/#{primary_doc_file["name"]}"

          table_xml_url =
            "#{@edgar_archives_url}/data/#{cik}/#{formatted_acc_no}/#{table_xml_file["name"]}"

          with {:ok, document} <- form13f_document_from_url(primary_doc_url),
               {:ok, table} <- form13f_table_from_url(table_xml_url) do
            {:ok, %{document: document, table: table}}
          else
            error -> error
          end
        else
          {:error, "No primary_doc or table file found"}
        end

      error ->
        error
    end
  end

  @doc """
  Parses a form 13F document from a given file path

  ## Required

  * `file_path` - The path to the 13F document to parse
  """
  @spec form13f_document_from_file(file_path :: String.t()) :: success_type(map()) | error_type()
  def form13f_document_from_file(file_path) do
    with {:ok, body} <- File.read(file_path), do: form13f_document_from_string(body)
  end

  @doc """
  Parses a form 13F filing from a given url

  ## Required

  * `url` - The url of the form 13F document to parse
  """
  @spec form13f_document_from_url(url :: String.t()) :: success_type(map()) | error_type()
  def form13f_document_from_url(url) do
    with {:ok, body} <- get(url), do: form13f_document_from_string(body)
  end

  @doc """
  Parses a form 13F filing primary document from a string

  ## Required

  * `xml_str` - The document xml string to parse
  """
  @spec form13f_document_from_string(xml_str :: String.t()) :: success_type(map()) | error_type()
  def form13f_document_from_string(xml_str), do: EDGAR.Native.parse_form13f_document(xml_str)

  @doc """
  Parses a form 13F filing table from a file

  ## Required

  * `file_path` - The path to the 13F table file to parse
  """
  @spec form13f_table_from_file(file_path :: String.t()) :: success_type(map()) | error_type()
  def form13f_table_from_file(file_path) do
    with {:ok, body} <- File.read(file_path), do: form13f_table_from_string(body)
  end

  @doc """
  Parses a form 13F filing table from a given url

  ## Required

  * `url` - The url of the 13F table file to parse
  """
  @spec form13f_table_from_url(url :: String.t()) :: success_type(map()) | error_type()
  def form13f_table_from_url(url) do
    with {:ok, body} <- get(url), do: form13f_table_from_string(body)
  end

  @doc """
  Parses a form 13F filing table from a string

  ## Required

  * `xml_str` - The table xml string to parse
  """
  @spec form13f_table_from_string(xml_str :: String.t()) :: success_type(map()) | error_type()
  def form13f_table_from_string(xml_str), do: EDGAR.Native.parse_form13f_table(xml_str)

  @doc """
  Parses a xbrl filing file from a given file path

  ## Required

  * `file_path` - The path of the xbrl filing to parse
  """
  @spec xbrl_from_file(file_path :: String.t()) :: success_type(map()) | error_type()
  def xbrl_from_file(file_path) do
    with {:ok, file_content} <- File.read(file_path), do: xbrl_from_string(file_content)
  end

  @doc """
  Parses a xbrl filing from a given url

  ## Required

  * `url` - The url of the xbrl filing to parse
  """
  @spec xbrl_from_url(url :: String.t()) :: success_type(map()) | error_type()
  def xbrl_from_url(url) do
    with {:ok, body} <- get(url), do: xbrl_from_string(body)
  end

  @doc """
  Parses a XBRL file

  ## Required

  * `xbrl_str` - The XBRL xml string to parse
  """
  @spec xbrl_from_string(xbrl_str :: String.t()) :: success_type(map()) | error_type()
  def xbrl_from_string(xbrl_str), do: EDGAR.Native.parse_xbrl(xbrl_str)

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
  @spec current_feed(opts :: map()) :: success_type(map()) | error_type()
  def current_feed(opts \\ %{}) do
    opts = Map.merge(%{output: "atom"}, opts)
    url = "https://www.sec.gov/cgi-bin/browse-edgar?action=getcurrent&#{URI.encode_query(opts)}"
    with {:ok, body} <- get(url), do: current_feed_from_string(body)
  end

  @doc """
  Parses the current feed

  ## Required

  * `xml_str` - The RSS feed xml to parse
  """
  @spec current_feed_from_string(xml_str :: String.t()) :: success_type(map()) | error_type()
  def current_feed_from_string(xml_str), do: EDGAR.Native.parse_current_feed(xml_str)

  @doc """
  Fetches the company feed for a given CIK

  ## Required

  * `cik` - The CIK of the entity

  ## Optional

  * `type` - The type of filing to filter by
  * `start` - The start index of the filings to return
  * `count` - The number of filings to return
  """
  @spec company_feed(cik :: String.t(), opts :: map()) :: success_type(map()) | error_type()
  def company_feed(cik, opts \\ %{}) do
    opts = Map.merge(%{output: "atom", CIK: cik}, opts)
    url = "https://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&#{URI.encode_query(opts)}"
    with {:ok, body} <- get(url), do: company_feed_from_string(body)
  end

  @doc """
  Parses the company feed

  ## Required

  * `xml_str` - The RSS feed xml string to parse
  """
  @spec company_feed_from_string(xml_str :: String.t()) :: success_type(map()) | error_type()
  def company_feed_from_string(xml_str), do: EDGAR.Native.parse_company_feed(xml_str)

  @doc """
  Fetches the press release feed
  """
  @spec press_release_feed :: success_type(map()) | error_type()
  def press_release_feed do
    url = "https://www.sec.gov/news/pressreleases.rss"
    with {:ok, body} <- get(url), do: rss_feed_from_string(body)
  end

  @doc """
  Fetches the speeches and statements feed
  """
  @spec speeches_and_statements_feed :: success_type(map()) | error_type()
  def speeches_and_statements_feed do
    url = "https://www.sec.gov/news/speeches-statements.rss"
    with {:ok, body} <- get(url), do: rss_feed_from_string(body)
  end

  @doc """
  Fetches the speeches feed
  """
  @spec speeches_feed :: success_type(map()) | error_type()
  def speeches_feed do
    url = "https://www.sec.gov/news/speeches.rss"
    with {:ok, body} <- get(url), do: rss_feed_from_string(body)
  end

  @doc """
  Fetches the statements feed
  """
  @spec statements_feed :: success_type(map()) | error_type()
  def statements_feed do
    url = "https://www.sec.gov/news/statements.rss"
    with {:ok, body} <- get(url), do: rss_feed_from_string(body)
  end

  @doc """
  Fetches the testimony feed
  """
  @spec testimony_feed :: success_type(map()) | error_type()
  def testimony_feed do
    url = "https://www.sec.gov/news/testimony.rss"
    with {:ok, body} <- get(url), do: rss_feed_from_string(body)
  end

  @doc """
  Fetches the litigation feed
  """
  @spec litigation_feed :: success_type(map()) | error_type()
  def litigation_feed do
    url = "https://www.sec.gov/rss/litigation/litreleases.xml"
    with {:ok, body} <- get(url), do: rss_feed_from_string(body)
  end

  @doc """
  Fetches the administrative proceedings feed
  """
  @spec administrative_proceedings_feed :: success_type(map()) | error_type()
  def administrative_proceedings_feed do
    url = "https://www.sec.gov/rss/litigation/admin.xml"
    with {:ok, body} <- get(url), do: rss_feed_from_string(body)
  end

  @doc """
  Fetches the trading suspensions feed
  """
  @spec trading_suspensions_feed :: success_type(map()) | error_type()
  def trading_suspensions_feed do
    url = "https://www.sec.gov/rss/litigation/suspensions.xml"
    with {:ok, body} <- get(url), do: rss_feed_from_string(body)
  end

  @doc """
  Fetches the division of corporation finance news feed
  """
  @spec division_of_corporation_finance_feed :: success_type(map()) | error_type()
  def division_of_corporation_finance_feed do
    url = "https://www.sec.gov/rss/divisions/corpfin/cfnew.xml"
    with {:ok, body} <- get(url), do: rss_feed_from_string(body)
  end

  @doc """
  Fetches the division of investment management news feed
  """
  @spec division_of_investment_management_feed :: success_type(map()) | error_type()
  def division_of_investment_management_feed do
    url = "https://www.sec.gov/rss/divisions/investment/imnews.xml"
    with {:ok, body} <- get(url), do: rss_feed_from_string(body)
  end

  @doc """
  Fetches the investor alerts feed
  """
  @spec investor_alerts_feed :: success_type(map()) | error_type()
  def investor_alerts_feed do
    url = "https://www.sec.gov/rss/investor/alerts"
    with {:ok, body} <- get(url), do: rss_feed_from_string(body)
  end

  @doc """
  Parses the press release feed from a string

  ## Required

  * `xml_str` - The RSS feed xml string to parse
  """
  @spec rss_feed_from_string(xml_str :: String.t()) :: success_type(map()) | error_type()
  def rss_feed_from_string(xml_str), do: EDGAR.Native.parse_rss_feed(xml_str)

  @doc """
  Fetches the recent filings rss feed
  """
  @spec filings_feed :: success_type(map()) | error_type()
  def filings_feed do
    url = "https://www.sec.gov/Archives/edgar/usgaap.rss.xml"
    with {:ok, body} <- get(url), do: filing_feed_from_string(body)
  end

  @doc """
  Fetch the recent mutual funds filings rss feed
  """
  @spec mutual_funds_feed :: success_type(map()) | error_type()
  def mutual_funds_feed do
    url = "https://www.sec.gov/Archives/edgar/xbrl-rr.rss.xml"
    with {:ok, body} <- get(url), do: filing_feed_from_string(body)
  end

  @doc """
  Fetches the recent XBRL rss feed
  """
  @spec xbrl_feed :: success_type(map()) | error_type()
  def xbrl_feed do
    url = "https://www.sec.gov/Archives/edgar/xbrlrss.all.xml"
    with {:ok, body} <- get(url), do: filing_feed_from_string(body)
  end

  @doc """
  Fetches the recent inline XBRL rss feed
  """
  @spec inline_xbrl_feed :: success_type(map()) | error_type()
  def inline_xbrl_feed do
    url = "https://www.sec.gov/Archives/edgar/xbrl-inline.rss.xml"
    with {:ok, body} <- get(url), do: filing_feed_from_string(body)
  end

  @doc """
  Fetches the historical XBRL feed for the given year and month

  ## Required

  * `year` - The year to fetch the XBRL feed for (must be 2005 or later)
  * `month` - The month to fetch the XBRL feed for
  """
  @spec historical_xbrl_feed(year :: integer(), month :: integer()) ::
          success_type(map()) | error_type()
  def historical_xbrl_feed(year, month) do
    case {year, month} do
      {year, _} when year < 2005 ->
        {:error, "year must be 2005 or later"}

      {_, month} when month < 1 or month > 12 ->
        {:error, "month must be between 1 and 12"}

      {year, month} ->
        formatted_month =
          month
          |> Integer.to_string()
          |> String.pad_leading(2, "0")

        url = "https://www.sec.gov/Archives/edgar/monthly/xbrlrss-#{year}-#{formatted_month}.xml"
        with {:ok, body} <- get(url), do: filing_feed_from_string(body)
    end
  end

  @doc """
  Parses a filing feed from a string

  ## Required

  * `xml_str` - The XBRL feed xml string to parse
  """
  @spec filing_feed_from_string(xml_str :: String.t()) :: success_type(map()) | error_type()
  def filing_feed_from_string(xml_str), do: EDGAR.Native.parse_filing_feed(xml_str)

  defp get(url) do
    SimpleRateLimiter.wait_and_proceed(fn ->
      user_agent =
        Application.get_env(:edgar_client, :user_agent, "default <default@default.com>")

      case Req.get(url, headers: [{"User-Agent", user_agent}], redirect_log_level: false) do
        {:ok, %Req.Response{status: 200, body: body}} ->
          {:ok, body}

        {:ok, %Req.Response{status: 404}} ->
          {:error, "resource not found"}

        {:ok, %Req.Response{status: code}} ->
          {:error, "unexpected status code: #{code}"}

        {:error, reason} ->
          {:error, reason}
      end
    end)
  end
end
