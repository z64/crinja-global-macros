# Global macro library issues

What we would like to establish is having a base library of macros that are available globally across all templates.
We've explored a couple different ways of setting that up; included is the scaffolding for showing a few of these and the issues we ran into.

## Context

I will describe generally how we need to structure our templates. We have:

- A base layout template for the root document, with blocks (`layout.html.2`)
- A canonical "page" template (e.g. Search, Images, ...) (`search.html.j2`)
- Template(s) for rendering series of results (`results.html.j2`)

The *page template* needs to be operable in two ways:

- Given some results, render the entire page in a single shot
  - Use case: Cached pages, full no-JS SSR rendering
- Without results, just render the "shell" without results
  - Later, we invoke the **same** results template on its own, and send the content as a progressive update

The goal is to seamlessly support both no-JS rendering and JS-enabled progressive updates, with minimal dev overhead.

## Solutions

### `import` attempts

The first thing we tried was the canonical macro interface of `{% import "macros" %}`.

`search.html.j2`
```jinja
{% extends "layout.html.j2" %}
{% import "macros.html.j2" %}

{% block body %}
  <div class="results">
    {% include "results.html.j2" %}
  </div>
{% endblock %}
```

`results.html.j2`
```jinja
{% for result in results %}
  <div class="result">
    <h3 class="title">
      {{link_extern(result.url, result.title)}}
    </h3>
    {{link_extern(result.url, result.url)}}
    <div>
      {{result.snippet}}
    </div>
  </div>
{% endfor %}
```

Here, `link_extern` is a macro from our base library.
(Note that in practice `search.html.j2` will make use of some of these macros as well)

This works fine for the "single shot" use case, however, we cannot render `results.html.j2` on its own.
If we include the macros in that template as well:

`results.html.j2`
```diff
+ {% import "macros.html.j2" %}
{% for result in results %}
  <div class="result">
    <h3 class="title">
      {{link_extern(result.url, result.title)}}
    </h3>
    ...
{% endfor %}
```

This works for the "results only" render. But now the "single shot" case is broken due to the macros being imported in both stacks:

```
Unhandled exception: Tag cycle detected: import "_macros.html.j2"
template: templates/results.html.j2:1:1 .. 2:0

  1 | {% import "_macros.html.j2" %}
  X | ^
  2 | {% for result in results %}
  3 |   <div class="result">
  4 |     <h3 class="title">
 (Crinja::Context::TagCycleException)
```

So this strategy is at a dead end currently.

### `env.register_macro` approach

The other approach that seems to work is the following:

```crystal
env = Crinja.new
env.loader = Crinja::Loader::FileSystemLoader.new("templates")

# load a special template file that just has our macros
macros_template = env.get_template("_macros.html.j2")

# call `render` to populate `macros`, as the template appears to be lazily processed
macros_template.render

# load them all onto the root context
macros_template.macros.each do |name, m|
  env.context.register_macro(m)
end

```

This works for all use cases. (`import` not used at all)
