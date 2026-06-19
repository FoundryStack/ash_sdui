defmodule SduiDemoWeb.Components.Layouts.DemoPageLayout do
  @moduledoc """
  Landing page layout with a blog-first hero, product highlights, and a tighter
  walkthrough of the generated UI flow.

  Note: This component is a pure Phoenix component, not SDUI-driven. It expects features
  to be passed as a direct assign, not through SDUI tree resolution.
  """

  use Phoenix.Component

  attr(:features, :list, default: [], doc: "List of %{icon, title, desc} feature maps")
  attr(:showcases, :list, default: [], doc: "List of %{title, path, api, desc} showcase maps")

  def render(assigns) do
    features = assigns.features
    showcases = assigns.showcases

    assigns = assign(assigns, features: features, showcases: showcases)

    ~H"""
    <div class="mx-auto flex max-w-6xl flex-col gap-16 px-4 py-10 sm:px-6 sm:py-14">
      <section class="grid items-stretch gap-6 lg:grid-cols-[minmax(0,1fr)_22rem]">
        <div class="flex flex-col justify-between rounded-box border border-base-300 bg-base-100 p-8 shadow-sm lg:p-10">
          <div class="max-w-3xl space-y-5">
            <p class="text-sm font-medium uppercase tracking-[0.22em] text-primary">AshSDUI Demo</p>
            <h1 class="text-4xl font-semibold leading-tight text-base-content lg:text-6xl">
              Server-driven UI for real Phoenix surfaces
            </h1>
            <p class="text-base leading-8 text-base-content/70 lg:text-lg">
              Generate the conventional flow from Ash, then bend the surface into a real blog with recipes, layout components, and targeted overrides.
            </p>
          </div>

          <div class="mt-8 flex flex-wrap gap-3">
            <a href="/posts" class="btn btn-primary btn-lg">Open the blog</a>
            <a href="/posts/generated" class="btn btn-outline btn-lg">Open generated index</a>
            <a href="/layouts/manage" class="btn btn-outline btn-lg">Open layout tour</a>
            <a href="/posts/new" class="btn btn-outline btn-lg">Create a post</a>
            <a href="/storybook" class="btn btn-ghost btn-lg">Browse Storybook</a>
          </div>
        </div>

        <aside class="rounded-box border border-base-300 bg-base-100 p-6 shadow-sm">
          <div class="space-y-5">
            <div class="space-y-1">
              <p class="text-sm font-medium uppercase tracking-[0.18em] text-base-content/55">
                Demo preview
              </p>
              <h2 class="text-2xl font-semibold text-base-content">AshSDUI Journal</h2>
            </div>
            <div class="space-y-4">
              <article class="rounded-box border border-base-300 bg-base-200/70 p-4">
                <div class="mb-2 flex items-center gap-2 text-sm text-base-content/60">
                  <span class="badge badge-success badge-outline">Published</span>
                  <span>Featured story</span>
                </div>
                <h3 class="text-lg font-semibold text-base-content">
                  A generated screen that still looks like a product page
                </h3>
                <p class="mt-2 text-sm leading-6 text-base-content/70">
                  The same resource metadata can drive index, show, create, and edit flows while the app keeps strong control over layout.
                </p>
              </article>
              <article class="rounded-box border border-base-300 bg-base-100 p-4">
                <p class="text-sm font-medium uppercase tracking-[0.16em] text-base-content/55">
                  Custom layer
                </p>
                <p class="mt-2 text-sm leading-6 text-base-content/70">
                  Editorial index recipe, custom post page layouts, and Storybook previews all sit on top of the same SDUI primitives.
                </p>
              </article>
              <article class="rounded-box border border-base-300 bg-base-100 p-4">
                <p class="text-sm font-medium uppercase tracking-[0.16em] text-base-content/55">
                  Layout layer
                </p>
                <p class="mt-2 text-sm leading-6 text-base-content/70">
                  The demo now separates raw trees, code layouts, persisted layouts, and ephemeral runtime layouts so each public entrypoint has a clear example.
                </p>
              </article>
            </div>
          </div>
        </aside>
      </section>

      <section class="space-y-5">
        <div class="max-w-2xl space-y-2">
          <h2 class="text-3xl font-semibold text-base-content">Highlights</h2>
          <p class="text-base-content/65">
            The demo now shows the library’s intended split: generated where it should be easy, customized where it should feel product-shaped.
          </p>
        </div>
        <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
          <%= for feature <- @features do %>
            <article class="rounded-box border border-base-300 bg-base-100 p-5 shadow-sm">
              <div class="space-y-3">
                <div class="badge badge-primary badge-outline">{feature.icon}</div>
                <div>
                  <h3 class="text-lg font-semibold text-base-content">{feature.title}</h3>
                  <p class="mt-2 text-sm leading-6 text-base-content/65">{feature.desc}</p>
                </div>
              </div>
            </article>
          <% end %>
        </div>
      </section>

      <section class="space-y-5">
        <div class="max-w-2xl space-y-2">
          <h2 class="text-3xl font-semibold text-base-content">Feature Tour</h2>
          <p class="text-base-content/65">
            Every promoted API path has a matching route, Storybook story, and regression test.
          </p>
        </div>
        <div class="grid gap-4 lg:grid-cols-2">
          <%= for showcase <- @showcases do %>
            <article class="rounded-box border border-base-300 bg-base-100 p-6 shadow-sm">
              <div class="space-y-4">
                <div class="space-y-2">
                  <span class="badge badge-primary badge-outline">{showcase.tag}</span>
                  <h3 class="text-2xl font-semibold text-base-content">{showcase.title}</h3>
                  <p class="text-sm leading-6 text-base-content/68">{showcase.desc}</p>
                </div>
                <div class="space-y-1 text-sm text-base-content/72">
                  <p class="font-medium text-base-content">API surface</p>
                  <p>{showcase.api}</p>
                </div>
                <div class="flex flex-wrap gap-3">
                  <a href={showcase.path} class="btn btn-primary btn-sm">{showcase.cta}</a>
                  <a href={showcase.secondary_path} class="btn btn-outline btn-sm">
                    {showcase.secondary_cta}
                  </a>
                </div>
              </div>
            </article>
          <% end %>
        </div>
      </section>

      <section class="rounded-box border border-base-300 bg-base-100 p-6 shadow-sm lg:p-8">
        <div class="space-y-6">
          <div class="max-w-2xl space-y-2">
            <h2 class="text-3xl font-semibold text-base-content">How it works</h2>
            <p class="text-base-content/65">
              The happy path stays small, but every layer still has a clear escape hatch.
            </p>
          </div>

          <div class="grid gap-4 lg:grid-cols-3">
            <article class="rounded-box border border-base-300 bg-base-200/60 p-5">
              <p class="text-sm font-medium uppercase tracking-[0.18em] text-primary">1</p>
              <h3 class="mt-3 text-xl font-semibold text-base-content">Describe the resource</h3>
              <p class="mt-2 text-sm leading-6 text-base-content/70">
                Ash models plus SDUI metadata define fields, actions, labels, and the default screen types.
              </p>
            </article>
            <article class="rounded-box border border-base-300 bg-base-200/60 p-5">
              <p class="text-sm font-medium uppercase tracking-[0.18em] text-primary">2</p>
              <h3 class="mt-3 text-xl font-semibold text-base-content">Resolve a view</h3>
              <p class="mt-2 text-sm leading-6 text-base-content/70">
                `AshSDUI.LiveResource` owns loading, form lifecycle, intent handling, and query state, then hands the view to a recipe.
              </p>
            </article>
            <article class="rounded-box border border-base-300 bg-base-200/60 p-5">
              <p class="text-sm font-medium uppercase tracking-[0.18em] text-primary">3</p>
              <h3 class="mt-3 text-xl font-semibold text-base-content">
                Render, persist, or override
              </h3>
              <p class="mt-2 text-sm leading-6 text-base-content/70">
                Stick with the generated surface, swap in a recipe, persist a layout, or go fully custom for pages like the post show layout.
              </p>
            </article>
          </div>
        </div>
      </section>
    </div>
    """
  end
end
