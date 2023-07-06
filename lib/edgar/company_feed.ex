defmodule EDGAR.CompanyFeed do
  defmodule Feed do
    defstruct [:id, :title, :updated, :author, :company_info, :entries, :links]
  end

  defmodule Author do
    defstruct [:email, :name]
  end

  defmodule CompanyInfo do
    defstruct [
      :addresses,
      :assigned_sic,
      :assigned_sic_desc,
      :assigned_sic_href,
      :cik,
      :cik_href,
      :conformed_name,
      :fiscal_year_end,
      :office,
      :state_location,
      :state_location_href,
      :state_of_incorporation
    ]
  end

  defmodule Addresses do
    defstruct [:addresses]
  end

  defmodule Address do
    defstruct [:address_type, :city, :phone, :state, :street1, :street2, :zip]
  end

  defmodule Entry do
    defstruct [:id, :updated, :title, :category, :content, :summary, :link]
  end

  defmodule Category do
    defstruct [:label, :scheme, :term]
  end

  defmodule Content do
    defstruct [
      :content_type,
      :accession_number,
      :file_number,
      :file_number_href,
      :filing_date,
      :filing_href,
      :filing_type,
      :film_number,
      :form_name,
      :size,
      :xbrl_href
    ]
  end

  defmodule Link do
    defstruct [:href, :rel, :link_type]
  end

  defmodule Summary do
    defstruct [:summary_type, :value]
  end
end
