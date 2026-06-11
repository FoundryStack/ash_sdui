defmodule SduiDemo.Blog do
  use Ash.Domain

  resources do
    resource SduiDemo.Blog.Post
    resource SduiDemo.Blog.Comment
  end
end
