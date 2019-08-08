defmodule Mnesiac.Support.ExampleStoreOne do
  @moduledoc false
  use Mnesiac.Store
  import Record, only: [defrecord: 3]

  defrecord(
    :exampleone,
    ExampleStoreOne,
    id: nil,
    topic_id: nil,
    event: nil
  )

  @type exampleone ::
          record(
            :exampleone,
            id: String.t(),
            topic_id: String.t(),
            event: String.t()
          )

  @impl true
  def store_options,
    do: [
      record_name: ExampleStoreOne,
      attributes: exampleone() |> exampleone() |> Keyword.keys(),
      index: [:topic_id],
      disc_copies: [node()]
    ]
end
