defmodule EDGAR.Native do
  mix_config = Mix.Project.config()
  version = mix_config[:version]
  github_url = mix_config[:package][:links]["GitHub"]

  mode = if Mix.env() in [:dev, :test], do: :debug, else: :release

  use RustlerPrecompiled,
    otp_app: :edgar_client,
    crate: "edgar_parser",
    version: version,
    base_url: "#{github_url}/releases/download/v#{version}",
    targets: ~w(
      aarch64-unknown-linux-gnu
      aarch64-unknown-linux-musl
      aarch64-apple-darwin
      riscv64gc-unknown-linux-gnu
      x86_64-apple-darwin
      x86_64-unknown-linux-gnu
      x86_64-unknown-linux-musl
      x86_64-pc-windows-msvc
      x86_64-pc-windows-gnu
    ),
    mode: mode,
    force_build: System.get_env("EDGAR_CLIENT_BUILD") in ["1", "true"]

  def parse_current_feed(_xml), do: :erlang.nif_error(:nif_not_loaded)
  def parse_company_feed(_xml), do: :erlang.nif_error(:nif_not_loaded)
  def parse_filing_feed(_xml), do: :erlang.nif_error(:nif_not_loaded)
  def parse_form13f_document(_xml), do: :erlang.nif_error(:nif_not_loaded)
  def parse_form13f_table(_xml), do: :erlang.nif_error(:nif_not_loaded)
  def parse_ownership_form(_xml), do: :erlang.nif_error(:nif_not_loaded)
  def parse_rss_feed(_xml), do: :erlang.nif_error(:nif_not_loaded)
  def parse_xbrl(_xml), do: :erlang.nif_error(:nif_not_loaded)
end
