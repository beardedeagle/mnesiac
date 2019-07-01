defmodule Mnesiac.Support.ExampleStore do
  @moduledoc false
  use Mnesiac.Store
  import Record, only: [defrecord: 3]

  defrecord(
    :example,
    ExampleStore,
    id: nil,
    topic_id: nil,
    event: nil
  )

  @type example ::
          record(
            :example,
            id: String.t(),
            topic_id: String.t(),
            event: String.t()
          )

  @impl true
  def store_options,
    do: [
      record_name: ExampleStore,
      attributes: example() |> example() |> Keyword.keys(),
      index: [:topic_id],
      disc_copies: [node()]
    ]
end
