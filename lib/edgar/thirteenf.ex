defmodule EDGAR.ThirteenF do
  defmodule SignatureBlock do
    defstruct [:name, :title, :phone, :signature, :city, :state_or_country, :signature_date]
  end

  defmodule SummaryPage do
    defstruct [:other_included_managers_count, :table_entry_total, :table_value_total]
  end

  defmodule Address do
    defstruct [:street1, :street2, :city, :state_or_country, :zip_code]
  end

  defmodule FilingManager do
    defstruct [:name, :address]
  end

  defmodule CoverPage do
    defstruct [
      :report_calendar_or_quarter,
      :is_amendment,
      :filing_manager,
      :report_type,
      :form13f_file_number,
      :crd_number,
      :sec_file_number,
      :provide_info_for_instruction5,
      :additional_information
    ]
  end

  defmodule Form do
    defstruct [:cover_page, :signature_block, :summary_page]
  end

  defmodule Credentials do
    defstruct [:cik, :ccc]
  end

  defmodule Filer do
    defstruct [:credentials]
  end

  defmodule Flags do
    defstruct [:confirming_copy_flag, :return_copy_flag, :override_internet_flag]
  end

  defmodule FilerInfo do
    defstruct [:live_test_flag, :flags, :filer, :period_of_report]
  end

  defmodule Header do
    defstruct [:submission_type, :filer_info]
  end

  defmodule Document do
    defstruct [:schema_version, :header, :form]
  end

  defmodule VotingAuthority do
    defstruct [:sole, :shared, :none]
  end

  defmodule SharesOrPrintAmount do
    defstruct [:shares_or_print_amount, :shares_or_print_type]
  end

  defmodule Holding do
    defstruct [
      :name_of_issuer,
      :title_of_class,
      :cusip,
      :value,
      :shares_or_print_amount,
      :investment_discretion,
      :other_manager,
      :voting_authority
    ]
  end

  defmodule Table do
    defstruct [:holdings]
  end
end
