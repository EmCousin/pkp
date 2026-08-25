# Rails doctrine applied to this repository

Use this reference when an architectural choice is not settled by nearby code.

## Optimize for programmer happiness

Prefer expressive Ruby and Rails APIs that make the application's intent obvious. Remove ceremony that exists only to satisfy an imported architecture. Short code is useful when it is also clear; clever code that hides behavior is not.

## Convention over configuration

Use Rails naming, directories, routes, associations, callbacks, rendering, and autoloading conventions. Depart from them only for a concrete application need. A conventional solution gives future contributors shared context and lets Rails do more work.

## The menu is omakase

Prefer the integrated Rails stack already selected by the application: Active Record, Action Controller, Action View, Active Job, Turbo, Stimulus, and the existing test stack. Evaluate a replacement against the whole system, including maintenance and integration costs, rather than one isolated feature.

## No one paradigm

Choose the form that fits the layer. Models can be object-oriented, helpers can be procedural, scopes can be declarative, and transformations can be functional. Do not force every behavior into the same class pattern.

## Exalt beautiful code

Names should expose domain language. Public methods should read clearly at the call site. Prefer a small Rails API over plumbing and indirection. Beauty includes predictable control flow, explicit side effects, and code that fits its neighbors.

## Provide sharp knives

Rails trusts developers with callbacks, concerns, metaprogramming, and broad model APIs. Use those tools deliberately rather than banning them categorically. Keep behavior cohesive, observable, and tested.

## Value integrated systems

Keep rendering, domain behavior, persistence, jobs, and browser interactions in the monolith unless distribution is required by a real boundary. Avoid duplicating templates and rules across a Rails backend and a JavaScript application.

## Progress over stability

Use the current Rails approach and improve old patterns when touching them, within the scope of the task. Do not preserve accidental complexity solely because it already exists. Do preserve shipped contracts, persisted data, and external integrations deliberately.

## Push up a big tent

These are defaults for making decisions, not a purity test. The repository already has legitimate exceptions. Judge a deviation by the problem it solves, document why it is needed, and keep it contained.

## Hotwire interpretation

Hotwire extends the integrated-system principle into the browser:

- Send HTML instead of creating duplicate JSON-to-template pipelines.
- Keep permissions, domain logic, and rendering on the server.
- Treat Turbo as an acceleration layer over ordinary HTTP.
- Treat Stimulus as behavior for HTML the server already rendered.
- Make every enhanced interaction resilient enough to fall back to a normal navigation or form submission.

## Sources

- [The Rails Doctrine](https://rubyonrails.org/doctrine)
- [Hotwire: HTML Over The Wire](https://hotwired.dev/)
- [Turbo Handbook](https://turbo.hotwired.dev/handbook/introduction)
- [Stimulus Handbook](https://stimulus.hotwired.dev/handbook/introduction)
