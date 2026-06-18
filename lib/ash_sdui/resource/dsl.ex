defmodule AshSDUI.Resource.UiIntent do
  @moduledoc false
  defstruct [
    :name,
    :style,
    :label,
    :label_key,
    :icon,
    :component_override,
    :target,
    :confirm,
    :placement,
    :requires_actor?,
    :visible_when,
    :enabled_when,
    :loading_when,
    :refreshes,
    :__spark_metadata__
  ]

  @type t :: %__MODULE__{
          name: atom,
          style: atom | nil,
          label: String.t() | nil,
          label_key: String.t() | nil,
          icon: String.t() | nil,
          component_override: String.t() | nil,
          target: term,
          confirm: boolean | String.t() | nil,
          placement: atom | nil,
          requires_actor?: boolean,
          visible_when: atom | nil,
          enabled_when: term,
          loading_when: term,
          refreshes: [atom] | nil,
          __spark_metadata__: any
        }
end

defmodule AshSDUI.Resource.View do
  @moduledoc false
  defstruct [
    :name,
    :recipe,
    :action,
    :read_action,
    :layout,
    :title,
    :empty_state,
    :query,
    :refresh,
    :workflow,
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
          query: atom | nil,
          refresh: term,
          workflow: term,
          __spark_metadata__: any
        }
end

defmodule AshSDUI.Resource.UiField do
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
    :binding,
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
          binding: atom | nil,
          __spark_metadata__: any
        }
end

defmodule AshSDUI.Resource.UiBinding do
  @moduledoc false
  defstruct [
    :name,
    :source,
    :many?,
    :query,
    :default,
    :refresh,
    :update,
    :__spark_metadata__
  ]

  @type t :: %__MODULE__{
          name: atom,
          source: term,
          many?: boolean | nil,
          query: atom | nil,
          default: term,
          refresh: term,
          update: term,
          __spark_metadata__: any
        }
end

defmodule AshSDUI.Resource.UiQuery do
  @moduledoc false
  defstruct [
    :name,
    :search,
    :sort,
    :filters,
    :default_sort,
    :default_limit,
    :__spark_metadata__
  ]

  @type t :: %__MODULE__{
          name: atom,
          search: [atom] | nil,
          sort: [atom] | nil,
          filters: [atom] | nil,
          default_sort: atom | [atom | {atom, atom}] | nil,
          default_limit: pos_integer | nil,
          __spark_metadata__: any
        }
end
