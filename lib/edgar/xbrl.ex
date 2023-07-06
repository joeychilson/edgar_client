defmodule EDGAR.XBRL do
  defmodule Document do
    defstruct [:facts]
  end

  defmodule Fact do
    defstruct [:context, :concept, :value, :decimals, :unit]
  end

  defmodule Context do
    defstruct [:entity, :segments, :period]
  end

  defmodule Segment do
    defstruct [:dimension, :member]
  end

  defmodule Period do
    defstruct [:instant, :start_date, :end_date]
  end

  defmodule Unit do
    defstruct [:measure, :numerator, :denominator]
  end
end
