---
name: progressive-enhancement
description: Enforce this repository's no-JavaScript baseline and progressively enhanced Hotwire frontend. Use for ERB views, layouts, helpers, forms, links, navigation, Turbo Frames, Turbo Streams, Stimulus controllers, browser behavior, accessibility, and system tests. Every feature must complete through normal HTTP and semantic HTML with JavaScript disabled; JavaScript may improve UX but may not be the only working path.
metadata:
  project: pkp
  version: "1.0.0"
---

# Progressive enhancement

Every feature must work without JavaScript. Treat HTML and HTTP as the product; Turbo and Stimulus improve the experience after the baseline works.

## Non-negotiable contract

- A user can discover, start, complete, and recover from the feature with JavaScript disabled.
- Every navigation has a real URL. Every state change reaches a Rails route through a real form submission.
- The server owns authorization, validation, business rules, persistence, and the final response.
- JavaScript can make an action faster or smoother. It cannot be required for correctness.
- If a third-party integration appears to require JavaScript, stop and design a server or hosted fallback. Do not create an exception without explicit user approval.

## Build in this order

1. Implement the route, controller action, model behavior, and full-page HTML response.
2. Use semantic links, buttons, forms, labels, status messages, and native controls.
3. Verify success, validation errors, back navigation, refresh, and repeated submission through normal HTTP.
4. Add Turbo Drive or Frames while preserving the same URLs and useful full-page responses.
5. Add Turbo Streams as an additional response format, not the only success path.
6. Add a small Stimulus controller only for behavior that HTML and Turbo cannot provide.
7. Verify both the baseline and enhanced paths.

## HTML and Rails rules

- Use `link_to` for safe GET navigation.
- Use `button_to` or a real form for POST, PATCH, PUT, and DELETE. A link that depends on `data-turbo-method` does not work without JavaScript.
- Use server-side validation and render actionable errors next to the relevant fields and in an accessible summary when appropriate.
- Keep submit buttons usable before controllers connect. Do not rely on JavaScript to enable the only submit control.
- Render essential content in the initial response. Do not make users depend on a lazy frame or client fetch to see it.
- Use redirects after successful mutations when a normal browser submission needs one.
- Give destructive or consequential confirmation a server-rendered path when confirmation is part of the requirement. `window.confirm` alone is only an enhancement.
- Prefer native HTML such as links, forms, `details`, labels, and input constraints when their baseline behavior is sufficient.

## Turbo rules

- A frame URL must also produce a coherent full page when visited directly.
- A frame must have meaningful fallback content or a normal link if loading it is optional. Do not lazy-load required content.
- Frame IDs and stream targets must be stable and come from server-rendered DOM IDs where possible.
- Controllers should respond to ordinary HTML. Add `turbo_stream` only where partial updates materially improve the interaction.
- Do not encode domain decisions in stream templates. They render decisions already made by the server.

## Stimulus rules

- Attach behavior to HTML that is already complete and usable.
- Use actions, targets, values, and classes instead of global selectors or hidden shared state.
- Keep controllers small and scoped to one element or interaction.
- Do not build core content, canonical state, navigation, validation, or submission exclusively in a controller.
- Make `connect` and repeated Turbo visits safe. Remove manually registered listeners in `disconnect`, or use Stimulus actions.
- Prefer CSS that enhances elements only after Stimulus connects when hiding content would otherwise break the no-JavaScript view.

## Verification gate

Do not call browser-facing work complete until all answers are yes:

- Can the flow complete with JavaScript disabled?
- Are all meaningful actions links or forms with server routes?
- Are server errors visible and actionable without JavaScript?
- Do direct visits and refreshes render useful pages?
- Does Turbo reuse the baseline response rather than replace it with a second application?
- Is every Stimulus behavior optional for task completion?
- Do specs cover the HTTP behavior and the important enhanced behavior?

Read `references/patterns.md` for concrete implementation patterns, failure modes, and test examples.
