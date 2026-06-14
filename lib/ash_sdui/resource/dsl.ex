defmodule AshSDUI.Resource.UiAction do
  @moduledoc false
  defstruct [
    :name,
    :intent,
    :label,
    :label_key,
    :icon,
    :component_override,
    :kind,
    :to,
    :event,
    :confirm,
    :placement,
    :requires_actor?,
    :visible_when,
    :__spark_metadata__
  ]

  @type t :: %__MODULE__{
          name: atom,
          intent: :primary | :secondary | :destructive | :info,
          label: String.t() | nil,
          label_key: String.t() | nil,
          icon: String.t() | nil,
          component_override: String.t() | nil,
          kind: :link | :event | :submit | nil,
          to: String.t() | nil,
          event: String.t() | nil,
          confirm: boolean | String.t() | nil,
          placement: atom | nil,
          requires_actor?: boolean,
          visible_when: atom | nil,
          __spark_metadata__: any
        }
end

defmodule AshSDUI.Resource.Screen do
  @moduledoc false
  defstruct [
    :name,
    :recipe,
    :action,
    :read_action,
    :layout,
    :title,
    :empty_state,
    :__spark_metadata__
  ]

  @type t :: %__MODULE__{
          name: atom,
          recipe: atom | nil,
          action: atom | nil,
          read_action: atom | nil,
          layout: atom | nil,
          title: String.t() | nil,
          empty_state: String.t() | nil,
          __spark_metadata__: any
        }
end

defmodule AshSDUI.Resource.UiAttribute do
  @moduledoc false
  defstruct [
    :name,
    :label,
    :label_key,
    :icon,
    :hidden,
    :order,
    :widget,
    :field_component,
    :show?,
    :index?,
    :form?,
    :filter?,
    :sortable?,
    :format,
    :empty_state,
    :badge?,
    :__spark_metadata__
  ]

  @type t :: %__MODULE__{
          name: atom,
          label: String.t() | nil,
          label_key: String.t() | nil,
          icon: String.t() | nil,
          hidden: boolean,
          order: non_neg_integer,
          widget: :text_input | :textarea | :email | :checkbox | :datetime | nil,
          field_component: module | nil,
          show?: boolean,
          index?: boolean,
          form?: boolean,
          filter?: boolean,
          sortable?: boolean,
          format: atom | nil,
          empty_state: String.t() | nil,
          badge?: boolean,
          __spark_metadata__: any
        }
end
