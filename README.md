# EDGAR

`EDGAR` is an Elixir-based HTTP Client for SEC's EDGAR.

## Installation

`EDGAR` is available on Hex. Add it to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:edgar_client, "~> 0.1.0"}
  ]
end
```

## Features

- [x] Rate Limiting

## Configuration

```elixir
# A default user agent is provided, but you should change it to your own to prevent your requests from being blocked.
config :edgar_client, :user_agent, "name <email>"
```