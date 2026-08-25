# Progressive enhancement patterns

Use these patterns when designing or reviewing browser-facing changes.

## Mutating actions

Avoid links whose HTTP method exists only in Turbo data attributes:

```erb
<%# JavaScript is required to turn this GET link into DELETE. %>
<%= link_to "Remove", member_path(member), data: { turbo_method: :delete } %>
```

Use a form-backed button:

```erb
<%= button_to "Remove", member_path(member), method: :delete %>
```

Turbo can still submit the form asynchronously. Without JavaScript, the browser sends an ordinary form request.

## Form responses

The normal HTML path should be complete:

```ruby
def create
  @member = current_user.members.new(member_params)

  if @member.save
    redirect_to @member, notice: t("members.created")
  else
    render :new, status: :unprocessable_entity
  end
end
```

Add a Turbo Stream response only when it improves the page materially:

```ruby
def create
  @member = current_user.members.new(member_params)

  if @member.save
    respond_to do |format|
      format.html { redirect_to @member, notice: t("members.created") }
      format.turbo_stream
    end
  else
    render :new, status: :unprocessable_entity
  end
end
```

Do not omit `format.html` and assume Turbo will always be present.

## Filters and search

Start with a GET form that submits without JavaScript:

```erb
<%= form_with url: members_path, method: :get do |form| %>
  <%= form.label :query, "Search" %>
  <%= form.search_field :query, value: params[:query] %>
  <%= form.submit "Search" %>
<% end %>
```

A Stimulus controller may submit on change or debounce typing, but the visible submit button remains available.

## Disclosures and dialogs

Use `details` and `summary` when they fit. For workflows that need a modal dialog, provide a normal page or inline form as the baseline. Stimulus may move or present that content in a dialog after connection.

Do not render essential content hidden by default and depend on JavaScript to reveal it. Prefer one of these approaches:

- Render the content visible, then add an enhancement class in `connect` that enables hiding and toggling.
- Render a normal link to a dedicated page, then intercept it to open an enhanced dialog.
- Use `details` for a native disclosure that works without scripts.

## Confirmations

`data-turbo-confirm` and `window.confirm` require JavaScript. They are acceptable only when confirmation is optional polish. If the product requires confirmation before a destructive action, route the user through a server-rendered confirmation page containing the final form.

## Turbo Frames

A frame endpoint should preserve direct navigation:

```erb
<%= turbo_frame_tag dom_id(@member, :details) do %>
  <%= render "details", member: @member %>
<% end %>
```

The action serving this template must render a coherent layout when requested as a normal page. If an interaction can escape the frame, give its link a valid destination; use `_top` only as an enhancement hint.

Avoid lazy frames for required content. A `<turbo-frame src="...">` never requests its source without JavaScript. Render required content in the initial response or provide a visible fallback link.

## Stimulus state

Store durable state on the server. Store shareable navigation state in the URL. Use Stimulus values only for local presentation state that can disappear on refresh without changing the feature's meaning.

Good Stimulus responsibilities include:

- Moving focus after an update.
- Showing an image preview while the real file upload remains a form input.
- Auto-submitting a filter form that still has a submit button.
- Adding keyboard shortcuts to existing buttons.
- Enhancing a server-rendered confirmation or disclosure.

Bad Stimulus responsibilities include:

- Constructing the only copy of core page content.
- Holding unsaved multi-step workflow state with no server representation.
- Sending raw `fetch` requests when a form and Turbo can express the action.
- Enforcing permissions or business validation.
- Providing the only way to submit, navigate, delete, or recover from an error.

## Accessibility

Progressive enhancement and accessibility reinforce each other:

- Use the correct element before adding ARIA.
- Keep keyboard and focus behavior valid in both modes.
- Put validation errors in the server response.
- Use `aria-live` for enhanced asynchronous status, while keeping a visible server-rendered message after normal navigation.
- Do not remove link destinations or button semantics when adding Stimulus actions.

## Testing

Request specs should prove the baseline HTTP contract:

- The route accepts the intended method.
- Success persists the change and redirects or renders useful HTML.
- Invalid input returns `422` with visible errors.
- Authorization is enforced on the server.
- Direct GET requests for frame content return coherent HTML.

System specs should cover the meaningful user flow without relying only on JavaScript-enabled behavior. Use a non-JavaScript Capybara driver for the baseline when practical, and a JavaScript driver for the enhanced interaction.

When a bug exists only because JavaScript failed to load, add a baseline regression spec before adding another client-side workaround.
