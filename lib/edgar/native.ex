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
    targets:
      Enum.uniq(["aarch64-unknown-linux-musl" | RustlerPrecompiled.Config.default_targets()]),
    mode: mode,
    force_build: System.get_env("EDGAR_CLIENT_BUILD") in ["1", "true"]

  def parse_13f_document(_xml), do: :erlang.nif_error(:nif_not_loaded)
  def parse_13f_table(_xml), do: :erlang.nif_error(:nif_not_loaded)
end
