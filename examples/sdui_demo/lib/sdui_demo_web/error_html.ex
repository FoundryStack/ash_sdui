defmodule SduiDemoWeb.ErrorHTML do
  use Phoenix.Component

  def render("500.html", assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-base-200">
      <div class="text-center">
        <h1 class="text-5xl font-bold mb-4">500</h1>
        <p class="text-base-content/60 mb-6">Internal Server Error</p>
        <a href="/" class="btn btn-primary">Back Home</a>
      </div>
    </div>
    """
  end

  def render("404.html", assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-base-200">
      <div class="text-center">
        <h1 class="text-5xl font-bold mb-4">404</h1>
        <p class="text-base-content/60 mb-6">Page Not Found</p>
        <a href="/" class="btn btn-primary">Back Home</a>
      </div>
    </div>
    """
  end

  def render(template, assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-base-200">
      <div class="text-center">
        <h1 class="text-3xl font-bold mb-4">Error</h1>
        <p class="text-base-content/60 mb-6"><%= template %></p>
        <a href="/" class="btn btn-primary">Back Home</a>
      </div>
    </div>
    """
  end
end
