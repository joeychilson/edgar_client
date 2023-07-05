# EDGAR

`EDGAR` is an Elixir-based HTTP Client for SEC's EDGAR.

This library is a work in progress. The API is subject to change.

## Installation

`EDGAR` is available on Hex. Add it to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:edgar_client, "~> 0.5.0"}
  ]
end
```

## Features

- [x] Rate Limiting
- [x] company tickers
- [x] company information
- [x] company facts
- [x] company concepts
- [x] filings by CIK
- [x] filings by form Type
- [x] current filings feed 
- [x] company filings feed
- [x] form13 filings parsing
- [x] form4 filings parsing

## Configuration

```elixir
# A default user agent is provided, but you should change it to your own to prevent your requests from being blocked.
config :edgar_client, :user_agent, "name <email>"
```

## TODO

- [ ] Improve tests
- [ ] Add more tests
- [ ] XBRL parsing
