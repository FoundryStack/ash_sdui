defmodule AshSDUI.Resource.UiAction do
  @moduledoc false
  defstruct [:name, :intent, :label, :label_key, :icon, :component_override, :__spark_metadata__]

  @type t :: %__MODULE__{
          name: atom,
          intent: :primary | :secondary | :destructive | :info,
          label: String.t() | nil,
          label_key: String.t() | nil,
          icon: String.t() | nil,
          component_override: String.t() | nil,
          __spark_metadata__: any
        }
end

defmodule AshSDUI.Resource.UiAttribute do
  @moduledoc false
  defstruct [:name, :label, :label_key, :icon, :hidden, :order, :__spark_metadata__]

  @type t :: %__MODULE__{
          name: atom,
          label: String.t() | nil,
          label_key: String.t() | nil,
          icon: String.t() | nil,
          hidden: boolean,
          order: non_neg_integer,
          __spark_metadata__: any
        }
end
