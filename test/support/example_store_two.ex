defmodule Mnesiac.Support.ExampleStoreTwo do
  @moduledoc false
  use Mnesiac.Store
  import Record, only: [defrecord: 3]

  defrecord(
    :exampletwo,
    ExampleStoreTwo,
    id: nil,
    topic_id: nil,
    event: nil
  )

  @type exampletwo ::
          record(
            :exampletwo,
            id: String.t(),
            topic_id: String.t(),
            event: String.t()
          )

  @impl true
  def store_options,
    do: [
      record_name: ExampleStoreTwo,
      attributes: exampletwo() |> exampletwo() |> Keyword.keys(),
      index: [:topic_id],
      disc_copies: [node()]
    ]
end
