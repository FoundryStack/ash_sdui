defmodule SduiDemo.UI.DemoLayouts do
  @moduledoc false

  alias AshSDUI.Layout
  alias AshSDUI.Layout.Builder

  @code_layout_name "demo-code-layout"
  @persisted_layout_name "demo-persisted-layout"

  def code_layout_name, do: @code_layout_name
  def persisted_layout_name, do: @persisted_layout_name

  def register_code_layout do
    Layout.register(@code_layout_name, code_root())
    @code_layout_name
  end

  def save_persisted_layout do
    Layout.save(@persisted_layout_name, persisted_root(), status: :draft)
  end

  def publish_persisted_layout do
    with {:ok, _records} <- save_persisted_layout() do
      Layout.publish(@persisted_layout_name)
    end
  end

  def raw_tree do
    raw_root()
    |> Builder.to_tree()
  end

  def code_root do
    Builder.node("Layouts.TwoColumnLayout@v1",
      id: "demo-code-layout-root",
      children: [
        Builder.resource(SduiDemo.UI.Resources.UserUI,
          id: "demo-code-layout-user",
          region: :sidebar,
          subject_id: "first"
        ),
        Builder.resource(SduiDemo.UI.Resources.PostUI,
          id: "demo-code-layout-post",
          region: :main,
          subject_id: "first",
          children: [
            Builder.resource(SduiDemo.UI.Resources.CommentUI,
              id: "demo-code-layout-comment-1",
              region: :comments,
              subject_id: "first"
            ),
            Builder.resource(SduiDemo.UI.Resources.CommentUI,
              id: "demo-code-layout-comment-2",
              region: :comments,
              order: 1,
              subject_id: "second"
            )
          ]
        )
      ]
    )
  end

  def persisted_root do
    Builder.node("Layouts.TwoColumnLayout@v1",
      id: "demo-persisted-layout-root",
      static_props: %{variant: "persisted"},
      children: [
        Builder.resource(SduiDemo.UI.Resources.UserUI,
          id: "demo-persisted-layout-user",
          region: :sidebar,
          subject_id: "first"
        ),
        Builder.resource(SduiDemo.UI.Resources.PostUI,
          id: "demo-persisted-layout-post",
          region: :main,
          subject_id: "first"
        )
      ]
    )
  end

  def status_snapshot do
    code_layout = Layout.fetch(@code_layout_name, source: :registered)
    persisted_layout = Layout.fetch(@persisted_layout_name, source: :stored, status: :any)
    persisted_nodes = Layout.load_nodes(@persisted_layout_name, status: :any)

    %{
      code_registered?: match?({:ok, _}, code_layout),
      code_component: root_component(code_layout),
      persisted_available?: match?({:ok, _}, persisted_layout),
      persisted_component: root_component(persisted_layout),
      persisted_statuses: persisted_statuses(persisted_nodes),
      persisted_node_count: persisted_node_count(persisted_nodes)
    }
  end

  defp raw_root do
    Builder.node("Layouts.TwoColumnLayout@v1",
      id: "demo-raw-tree-root",
      children: [
        Builder.resource(SduiDemo.UI.Resources.UserUI,
          id: "demo-raw-tree-user",
          region: :sidebar,
          subject_id: "first"
        ),
        Builder.resource(SduiDemo.UI.Resources.PostUI,
          id: "demo-raw-tree-post",
          region: :main,
          subject_id: "first"
        )
      ]
    )
  end

  defp root_component({:ok, %{root: root}}), do: root.component
  defp root_component(_), do: nil

  defp persisted_statuses({:ok, nodes}) do
    nodes
    |> Enum.map(& &1.status)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp persisted_statuses(_), do: []

  defp persisted_node_count({:ok, nodes}), do: length(nodes)
  defp persisted_node_count(_), do: 0
end
