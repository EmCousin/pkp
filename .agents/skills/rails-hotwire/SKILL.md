---
name: rails-hotwire
description: Apply this repository's vanilla Rails and Hotwire architecture. Use when changing Rails models, controllers, routes, jobs, mailers, migrations, ERB views, helpers, Turbo, Stimulus, or application structure. Prefer Rails defaults, server-rendered HTML, RESTful resources, cohesive domain models, and the integrated monolith. For any browser-facing change, also load the progressive-enhancement skill.
metadata:
  project: pkp
  version: "1.0.0"
---

# Rails and Hotwire

Build this application as an integrated Rails monolith. Use Rails conventions and the framework's full stack before inventing abstractions or adding dependencies.

## Required companion skill

For any browser-facing work, read `../progressive-enhancement/SKILL.md` before designing the change. Its no-JavaScript contract is mandatory.

## Priorities

Use this order when choices compete:

1. Correct domain behavior and data integrity.
2. A complete server-rendered HTTP flow.
3. Clear, conventional Rails code.
4. Progressive enhancement with Turbo, then Stimulus where needed.
5. Extraction or new dependencies only after repeated, concrete pressure.

## Work with Rails

- Start from the resource and its lifecycle. Prefer RESTful routes and standard controller actions over verb-named endpoints.
- Keep controllers responsible for HTTP concerns: authentication, authorization, parameter handling, invoking domain behavior, rendering, and redirecting.
- Put domain rules and state transitions on models or cohesive model concerns. Models may be substantial when the behavior belongs to the domain.
- Use plain Ruby objects or service objects for a real boundary, such as an external system or a multi-model workflow. Do not create one class per controller action by habit.
- Prefer Active Record associations, scopes, validations, callbacks used with care, transactions, and database constraints over parallel persistence layers.
- Use Active Job for slow or retryable work. Keep the durable state transition on the server and make jobs safe to retry.
- Render ERB on the server. Reuse partials and helpers before introducing a component framework.
- Use Rails form, URL, localization, mailer, attachment, and security helpers instead of hand-building equivalent infrastructure.
- Follow existing namespacing and nearby code style. Generate less structure, not more.

## Hotwire approach

- Return HTML from Rails. Do not add a JSON endpoint solely to feed this application's own browser UI.
- Let Turbo Drive accelerate ordinary links and forms without changing their server semantics.
- Use Turbo Frames for independently addressable page regions whose URLs also render useful full-page responses.
- Use Turbo Streams for server-rendered DOM updates. Keep ordinary HTML redirects or renders as the baseline response.
- Use Stimulus for small behavior attached to existing HTML: focus, disclosure polish, previews, keyboard behavior, and similar enhancements.
- Keep business rules, authorization, validation, and canonical state on the server. Do not mirror them in JavaScript.
- Prefer semantic HTML and browser behavior before adding a Stimulus controller.

## Avoid by default

- SPA frameworks, client-side routers, and client-owned application state.
- Repository layers around Active Record with no concrete boundary.
- Command, handler, operation, or interactor classes that only rename a model method.
- Generic base classes, metaprogramming, or concerns created for a single use.
- API-first designs for pages Rails can render directly.
- Custom JavaScript for navigation or form submission that Turbo and HTML already handle.
- New gems or npm packages for behavior already present in Rails, Hotwire, Ruby, or the browser.

## Implementation workflow

1. Inspect the nearest route, model, controller, view, and spec before choosing a shape.
2. Describe the feature as resources, state changes, and server responses.
3. Implement the complete HTML request cycle first.
4. Add Turbo behavior without changing the underlying URLs or form actions.
5. Add the smallest Stimulus enhancement only if HTML and Turbo are insufficient.
6. Test domain behavior and HTTP responses. Test important enhanced interactions separately.
7. Run the narrow specs first, then the relevant broader suite and RuboCop.

## Review questions

- Does this look like Rails, or like another architecture translated into Ruby?
- Could an existing Rails convention remove a class, configuration file, endpoint, or dependency?
- Is the domain rule in one authoritative server-side place?
- Does the same URL work as a normal full-page request?
- Does the feature still work with JavaScript disabled?

Read `references/doctrine.md` when evaluating an architectural tradeoff or introducing a new layer, dependency, or frontend pattern.
