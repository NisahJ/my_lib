defmodule Mylib.LibraryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Mylib.Library` context.
  """

  @doc """
  Generate a book.
  """
  def book_fixture(attrs \\ %{}) do
    {:ok, book} =
      attrs
      |> Enum.into(%{
        author: "some author",
        isbn: "some isbn",
        published_at: 42,
        title: "some title"
      })
      |> Mylib.Library.create_book()

    book
  end

  @doc """
  Generate a loan.
  """
  def loan_fixture(attrs \\ %{}) do
    {:ok, loan} =
      attrs
      |> Enum.into(%{
        borrowed_at: ~N[2025-07-20 01:48:00],
        due_at: ~N[2025-07-20 01:48:00],
        returned_at: ~N[2025-07-20 01:48:00]
      })
      |> Mylib.Library.create_loan()

    loan
  end
end
