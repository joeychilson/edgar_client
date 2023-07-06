defmodule EDGAR.CurrentFeed do
  defmodule Feed do
    defstruct [:id, :title, :updated, :author, :entries, :links]
  end

  defmodule Author do
    defstruct [:email, :name]
  end

  defmodule Entry do
    defstruct [:id, :updated, :title, :category, :summary]
  end

  defmodule Category do
    defstruct [:label, :scheme, :term]
  end

  defmodule Link do
    defstruct [:href, :rel, :link_type]
  end

  defmodule Summary do
    defstruct [:summary_type, :value]
  end
end
