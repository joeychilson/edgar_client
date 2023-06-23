defmodule EDGARClientTest do
  use ExUnit.Case
  doctest EDGARClient

  test "test submissions found" do
    submissions = EDGARClient.get_submissions("0000320193")
    assert {:ok, _} == submissions
  end

  test "test submissions not found" do
    submissions = EDGARClient.get_submissions("0000320")
    assert {:error, :not_found} == submissions
  end
end
