require "crinja"

env = Crinja.new
env.loader = Crinja::Loader::FileSystemLoader.new("templates")

macros_template = env.get_template("_macros.html.j2")
macros_template.render

macros_template.macros.each do |name, m|
  env.context.register_macro(m)
end

search_template = env.get_template("search.html.j2")
results_template = env.get_template("results.html.j2")

results = [
  {url: "http://a.com", title: "Title 1", snippet: "Snippet 1"},
  {url: "http://b.com", title: "Title 2", snippet: "Snippet 2"},
  {url: "http://c.com", title: "Title 3", snippet: "Snippet 3"},
]

puts(search_template.render({results: results}))
puts(results_template.render({results: results}))
