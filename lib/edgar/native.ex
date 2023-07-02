defmodule EDGAR.Native do
  mix_config = Mix.Project.config()
  version = mix_config[:version]
  github_url = mix_config[:package][:links]["GitHub"]

  mode = if Mix.env() in [:dev, :test], do: :debug, else: :release

  use RustlerPrecompiled,
    otp_app: :edgar_client,
    crate: "edgar",
    version: version,
    base_url: "#{github_url}/releases/download/v#{version}",
    targets: ~w(
      aarch64-apple-darwin
      aarch64-unknown-linux-gnu
      aarch64-unknown-linux-musl
      riscv64gc-unknown-linux-gnu
      x86_64-apple-darwin
      x86_64-pc-windows-msvc
      x86_64-pc-windows-gnu
      x86_64-unknown-linux-gnu
      x86_64-unknown-linux-musl
      x86_64-unknown-freebsd
    ),
    mode: mode,
    force_build: System.get_env("EDGAR_CLIENT_BUILD") in ["1", "true"]

  def parse_13f_document(_xml), do: :erlang.nif_error(:nif_not_loaded)
  def parse_13f_table(_xml), do: :erlang.nif_error(:nif_not_loaded)
end
