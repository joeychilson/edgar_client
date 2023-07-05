defmodule EDGAR.Form4 do
  defmodule Document do
    defstruct [
      :document_type,
      :period_of_report,
      :issuer,
      :reporting_owner,
      :non_derivative_table,
      :derivative_table,
      :remarks,
      :owner_signature
    ]
  end

  defmodule Issuer do
    defstruct [
      :cik,
      :name,
      :trading_symbol
    ]
  end

  defmodule ReportingOwner do
    defstruct [
      :id,
      :address,
      :relationship
    ]
  end

  defmodule ReportingOwnerID do
    defstruct [
      :cik,
      :name
    ]
  end

  defmodule ReportingOwnerAddress do
    defstruct [
      :street_1,
      :street_2,
      :city,
      :state,
      :zip_code,
      :state_description
    ]
  end

  defmodule ReportingOwnerRelationship do
    defstruct [
      :is_director,
      :is_officer,
      :is_ten_percent_owner,
      :is_other,
      :officer_title,
      :other_text
    ]
  end

  defmodule NonDerivativeTable do
    defstruct [
      :transactions,
      :holdings
    ]
  end

  defmodule DerivativeTable do
    defstruct [
      :transactions,
      :holdings
    ]
  end

  defmodule Transaction do
    defstruct [
      :security_title,
      :conversion_or_exercise_price,
      :date,
      :deemed_execution_date,
      :coding,
      :amounts,
      :exercise_date,
      :expiration_date,
      :underlying_security,
      :post_transaction_amounts,
      :ownership_nature
    ]
  end

  defmodule Holding do
    defstruct [
      :security_title,
      :conversion_or_exercise_price,
      :exercise_date,
      :expiration_date,
      :underlying_security,
      :post_transaction_amounts,
      :ownership_nature
    ]
  end

  defmodule StringValue do
    defstruct [
      :value
    ]
  end

  defmodule IntValue do
    defstruct [
      :value
    ]
  end

  defmodule FloatValue do
    defstruct [
      :value
    ]
  end

  defmodule TransactionCoding do
    defstruct [
      :form_type,
      :code,
      :equity_swap_involved
    ]
  end

  defmodule TransactionAmounts do
    defstruct [
      :shares,
      :price_per_share,
      :acquired_disposed_code
    ]
  end

  defmodule UnderlyingSecurity do
    defstruct [
      :title,
      :shares
    ]
  end

  defmodule PostTransactionAmounts do
    defstruct [
      :shares_owned_following_transaction
    ]
  end

  defmodule OwnershipNature do
    defstruct [
      :direct_or_indirect_ownership,
      :nature_of_ownership
    ]
  end

  defmodule Footnote do
    defstruct [
      :id,
      :text
    ]
  end

  defmodule FootnoteAttributes do
    defstruct [
      :id
    ]
  end

  defmodule OwnerSignature do
    defstruct [
      :name,
      :date
    ]
  end
end
