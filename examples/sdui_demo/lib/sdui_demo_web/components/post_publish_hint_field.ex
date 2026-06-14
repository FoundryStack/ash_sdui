defmodule SduiDemoWeb.Components.PostPublishHintField do
  use Phoenix.Component

  def render(assigns) do
    ~H"""
    <div class="rounded-box border border-base-300 bg-base-200/60 px-4 py-4">
      <div class="text-sm font-medium uppercase tracking-[0.18em] text-base-content/60">Content</div>
      <div class="mt-2 text-sm leading-6 text-base-content/70">
        This field is rendered by a custom component, but still participates in the same Ash form.
      </div>
      <textarea
        name={@form[@field.name].name}
        class={[
          "textarea textarea-bordered mt-4 h-56 w-full text-base leading-7",
          Map.get(@field, :class),
          @errors != [] && "textarea-error"
        ]}
        phx-debounce="300"
      ><%= @value %></textarea>
      <%= for error <- @errors do %>
        <p class="label text-error text-xs">{translate_error(error)}</p>
      <% end %>
    </div>
    """
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
