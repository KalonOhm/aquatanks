# Tutorial: move "New" from the header to My Tanks

**Goal:** take the **New** link out of the site header and put a **New Tank** button on the My Tanks page, visible only to the person whose page it is. Along the way, make sure guests can't reach the new-tank form by typing its URL.

**Files you'll touch:**

| File | What changes |
|---|---|
| `app/views/shared/_nav.html.erb` | Remove the New link (twice) |
| `app/views/users/show.html.erb` | Add the New Tank button, plus an empty-tank message |
| `app/views/aquariums/new.html.erb` | Point the Back link at My Tanks |
| `app/controllers/aquariums_controller.rb` | Require login for `new` and `create` |

Each section has a **Try it** prompt. Attempt it yourself first; the answer is in a collapsed **Solution** block under it.

Before you start, have the app running so you can check as you go (two terminals):

```powershell
ruby bin/rails server
ruby bin/rails tailwindcss:watch
```

Use `watch`, not `build`, for this tutorial. See section 2 for why.

---

## 1. Remove "New" from the header

### Where it lives

Every page renders the header from one shared file. In `app/views/layouts/application.html.erb` you'll see:

```erb
<%= render "shared/nav" %>
```

`render "shared/nav"` means "insert `app/views/shared/_nav.html.erb` here". The leading underscore in the filename marks it as a **partial**: a reusable fragment of a page, not a page of its own. So one edit to `_nav.html.erb` changes the header everywhere.

### Why it's there twice

Open `_nav.html.erb`. The menu is written out **two times**:

- **Desktop menu:** inside `<nav class="hidden ... md:block" aria-label="main">`. `hidden md:block` is Tailwind for "hide this, except at medium screen widths and up".
- **Mobile menu:** inside `<section id="mobile-menu" ...>`, near the bottom. It starts hidden, and the hamburger button's JavaScript (`app/javascript/application.js`) toggles it on small screens.

Removing only one would leave the link showing on either phones or desktops.

### Try it

Delete the line containing `link_to 'New', new_aquarium_path` in **both** menus. Each sits inside an `<% if logged_in? %>` block, next to the My Tanks link.

<details>
<summary>Solution</summary>

In the desktop menu, delete:

```erb
          <span class="hover:opacity-90"><%= link_to 'New', new_aquarium_path %></span>
```

In the mobile menu, delete:

```erb
        <p class="w-full py-6 text-center hover:opacity-90"><%= link_to 'New', new_aquarium_path %></p>
```

</details>

**Check:** reload any page. **New** is gone from the header. Make the browser window narrow, open the hamburger menu, and check it's gone there too.

---

## 2. Add a New Tank button to My Tanks

### Which file is "My Tanks"?

The header's My Tanks link is `link_to 'My Tanks', user_path(current_user)`. To find which code handles a path, check the routes:

- `config/routes.rb` has `resources :users`, which creates the route `GET /users/:id` → `users#show`.
- `users#show` means the `show` method in `UsersController`, which renders `app/views/users/show.html.erb`.

That's the Rails convention: **controller name + action name → view file**. You can list every route with `ruby bin/rails routes`.

Look at `UsersController#show`:

```ruby
def show
  @user = User.find(params[:id])
  @user_aquariums = @user.aquariums
end
```

Instance variables (the ones starting with `@`) set in a controller action are available in its view. That's how `show.html.erb` gets `@user` and `@user_aquariums`.

### Who should see the button?

`/users/:id` isn't private: anyone can visit `/users/2` and see user 2's tanks. A New Tank button on someone else's page would be confusing. Clicking it would create a tank for *you*, not for them. So show the button only when the logged-in user is the user whose page this is.

Two things to compare:

- `current_user`: defined in `app/helpers/application_helper.rb`. Helpers are available in every view, so you can call it directly. It returns `nil` when nobody is logged in.
- `@user`: the user whose page you're viewing, set by the controller.

`current_user == @user` is true only when they're the same record. Active Record compares records by class and id. If nobody is logged in, `nil == @user` is false, so guests are covered too.

### How to write the button

Rails builds the URL for you. `resources :aquariums` creates a helper called `new_aquarium_path`, which returns `/aquariums/new`. Use it rather than typing the URL, so the link keeps working if routes ever change.

For styling, reuse the button classes the rest of the app uses (listed in `CLAUDE.md` under "Styling conventions"):

```
text-xs inline-block rounded bg-teal-700 dark:bg-teal-500 px-3 pt-2 pb-1.5 mt-1.5 self-end
```

> **A note on the existing pattern.** Elsewhere in the app, links are wrapped in `<button type="button">…</button>`. Putting a link inside a button is technically invalid HTML (browsers tolerate it, but keyboard users and screen readers can get confused). The classes already make the link *look* like a button, so the wrapper isn't needed. This tutorial uses a plain `link_to`; you can decide later whether to clean up the other pages the same way.

### Try it

In `app/views/users/show.html.erb`, between the `<h1>` and the `<div id="aquariums" …>` grid:

1. Open an `<% if %>` that checks whether `current_user` is `@user`.
2. Inside it, add a `link_to` with the text "New Tank", the path helper for the new-aquarium page, and the button classes.
3. Wrap it in a `<div>` with Tailwind classes that center it and add space below. Hint: `text-center` and `mb-6`.
4. Close the `if` with `<% end %>`.

Remember the two ERB tags:

- `<%= %>` **outputs** its result into the page. Use it for `link_to`.
- `<% %>` **runs** code without printing anything. Use it for `if` and `end`.

<details>
<summary>Solution</summary>

```erb
<h1 class="text-center underline underline-offset-4 text-3xl font-medium mb-4"><%=@user.name%>'s Aquariums</h1>

<% if current_user == @user %>
  <div class="text-center mb-6">
    <%= link_to "New Tank", new_aquarium_path, class: "text-xs inline-block rounded bg-teal-700 dark:bg-teal-500 px-3 pt-2 pb-1.5 mt-1.5 self-end" %>
  </div>
<% end %>

<div id="aquariums" class="grid lg:grid-cols-3 md:grid-cols-2 gap-y-4 ml-10">
```

</details>

### Why `tailwindcss:watch` matters here

Tailwind doesn't ship every possible class. It scans your view files and generates CSS only for the class names it finds (the files it scans are listed under `content:` in `config/tailwind.config.js`).

If you add a class no view used before, it has no CSS until Tailwind rescans. The `watch` command rescans every time you save a file; `build` only runs once.

So if a new class seems to do nothing, check that the watcher is running, then hard-refresh the browser (Ctrl+Shift+R).

**Check:**

- Go to My Tanks. The button appears and opens the new-tank form.
- Note your user id from the address bar, e.g. `/users/1`. Log out, sign up a second account, then visit `/users/1`. You should see the first user's tanks but **no** New Tank button.

---

## 3. Show a message when there are no tanks (optional, recommended)

### Why

A brand-new user's My Tanks page is a heading, a button and a blank grid. A short message makes it clear the page isn't broken.

### How

`@user_aquariums` is a collection of records, and `.empty?` asks whether it has none. Show a paragraph when it's empty.

Tailwind's `text-center` centers text. A softer colour such as `text-gray-500` makes it read as a hint. Adding `dark:text-gray-400` keeps it readable in dark mode, because every view in this app supports dark mode.

### Try it

Below the button block and above the grid, add an `if` that shows a short message when the user has no tanks. Bonus: word it differently for the page's owner ("You don't have any tanks yet") and for visitors ("No tanks yet"). You already know how to tell them apart.

<details>
<summary>Solution</summary>

```erb
<% if @user_aquariums.empty? %>
  <p class="text-center text-gray-500 dark:text-gray-400">
    <%= current_user == @user ? "You don't have any tanks yet. Create your first one above!" : "No tanks yet." %>
  </p>
<% end %>
```

`condition ? a : b` is Ruby's one-line if/else (the "ternary" operator).

</details>

**Check:** a new account shows the owner's message. Visiting another tankless user shows "No tanks yet." Once you create a tank, the message disappears.

---

## 4. Send "Back" to My Tanks

### Why

Open `app/views/aquariums/new.html.erb`. Its back link goes to `aquariums_path`, the list of *everyone's* tanks.

Now that people reach this form from My Tanks, "back" should return them there. Otherwise cancelling drops them on a different page from the one they came from.

### How

The My Tanks URL is built in the header as `user_path(current_user)`. Path helpers for a single record take that record as an argument and use its id, so this builds `/users/<your id>`.

### Try it

Change the link's text to "Back to My Tanks" and its path to the current user's page.

<details>
<summary>Solution</summary>

```erb
<%= link_to "Back to My Tanks", user_path(current_user), {:class => "text-xs inline-block rounded bg-teal-700 dark:bg-teal-500 px-3 pt-2 pb-1.5 mt-1.5 self-end  "} %>
```

</details>

This relies on someone being logged in: `user_path(nil)` raises an error. Section 5 makes sure only logged-in users can reach this page.

---

## 5. Require login for creating tanks

### Why this matters now

Hiding a link doesn't stop anyone visiting its URL. Right now a logged-out visitor can type `/aquariums/new` and get the form. Submitting it crashes, because `AquariumsController#create` does:

```ruby
@aquarium = helpers.current_user.aquariums.new(aquarium_params)
```

and `current_user` is `nil` for guests. Calling `.aquariums` on `nil` raises `NoMethodError`. After section 4, the form page itself would crash too.

**The rule of thumb: views decide what to show; controllers decide what's allowed.** Every hidden-button check in a view should have a matching check in the controller.

### How

The app already has a guard for this. In `app/controllers/application_controller.rb`:

```ruby
def require_user
  if guest?
    flash[:notice] = "You must log in to access this page"
    redirect_to login_path
  end
end
```

It's defined but never used. Controllers run it with a **`before_action`**: a method Rails calls before the action itself. If the before_action redirects, the action never runs. `only:` limits it to particular actions.

`AquariumsController` already has one:

```ruby
before_action :set_aquarium, only: %i[ show edit update destroy ]
```

`%i[ a b ]` is Ruby shorthand for the symbol array `[:a, :b]`. `SessionsController` shows the opposite form: `before_action :is_signed_in?, except: [:destroy]`.

### Try it

Add a second `before_action` to `AquariumsController` that runs `require_user` for the `new` and `create` actions only. Put it **above** the existing line, so the login check happens first.

<details>
<summary>Solution</summary>

```ruby
class AquariumsController < ApplicationController
  before_action :require_user, only: %i[ new create ]
  before_action :set_aquarium, only: %i[ show edit update destroy ]
```

</details>

**Why not protect everything?** Browsing tanks (`index`, `show`) is meant to be public. Edit, update and delete need more than login: they need *ownership*, and that's a bigger change for another day. It's listed in `DESIGN.md` under planned work.

**Check:**

- Log out, then type `localhost:3000/aquariums/new` into the address bar. You should land on the login page.
- You won't see the "You must log in" message, because the layout doesn't display flash messages yet (another known gap in `CLAUDE.md`). Adding flash display to `app/views/layouts/application.html.erb` would make a good next exercise.
- Log in, go to My Tanks, click New Tank, create a tank. It should save and show the tank's page.

---

## 6. Commit

Look over your changes in GitHub Desktop. You should see four files. Commit with a message that says what changed and why, for example:

```
Move New Tank button from header to My Tanks

- Remove New from desktop and mobile nav
- Show New Tank on My Tanks only to the page's owner, plus an empty-state message
- Back link on the new-tank form returns to My Tanks
- Require login for aquariums#new/create (guests previously crashed on create)
```

---

## Concepts used

| Concept | Where you used it |
|---|---|
| Partials (`_name.html.erb`, `render`) | Header lives in `shared/_nav` |
| Routes → controller → view convention | Finding the My Tanks file |
| Path helpers (`new_aquarium_path`, `user_path(user)`) | New Tank button, Back link |
| Instance variables passed from controller to view | `@user`, `@user_aquariums` |
| View helpers (`current_user`) | Owner check |
| `<%= %>` vs `<% %>` | Every ERB edit |
| Tailwind only builds classes it finds | Why to run `tailwindcss:watch` |
| `before_action` with `only:` | Protecting `new`/`create` |
| Hide in the view, enforce in the controller | Sections 2 and 5 |
