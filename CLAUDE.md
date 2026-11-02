# CLAUDE.md

Aquatanks is a Rails 8.1 app where users sign up, create aquariums (tanks), and stock them with species. The species catalog (~2200 fish, invertebrates, plants and amphibians) is scraped from Wikipedia at seed time. Project goals, planned work and the scraper's design are in [DESIGN.md](DESIGN.md); keep it updated when those change.

## Stack

- Ruby 4.0, Rails 8.1 (upgraded from 7.0 in Oct 2026; `config.load_defaults` is still 7.0), SQLite3 (`db/development.sqlite3`, gitignored)
- Hotwire (Turbo + Stimulus) via importmap — no Node/bundler for JS
- Tailwind **v3** via `tailwindcss-rails` 3.x, with `tailwindcss-ruby` pinned to `~> 3.4` (`config/tailwind.config.js`, `app/assets/stylesheets/application.tailwind.css`). Moving to v4 means migrating the config into CSS. `application.css` (Sprockets, no Sass) holds a few plain-CSS rules
- Auth: hand-rolled sessions with `has_secure_password` (bcrypt) — no Devise
- Tests: Minitest + Capybara/Selenium system tests (mostly scaffold-generated stubs)

## Commands

```sh
bundle install
bin/rails db:migrate
bin/rails db:seed        # scrapes Wikipedia — needs network
bin/dev                  # runs Procfile.dev: rails server on :3000 + tailwindcss:watch
bin/rails test           # unit/controller tests
bin/rails test:system    # browser tests (Selenium)
```

Run `bin/dev` (not just `rails s`) so Tailwind classes added in views get compiled into `app/assets/builds/`.

**Windows (PowerShell):** the `bin/` scripts have no extension, so Windows doesn't know to run them with Ruby. Prefix them with `ruby` (e.g. `ruby bin/rails db:seed`). `bin/dev` is a shell script and doesn't work in PowerShell; run `ruby bin/rails server` and `ruby bin/rails tailwindcss:watch` in two terminals instead. Ruby lives in `C:\Ruby40-x64` (RubyInstaller, with its compiler tools already installed).

## Domain model

```
User 1──* Aquarium *──* Species 1──* SpeciesAlias
            (through aquarium_species, with a `count` column)
```

- `User` — `name`, `email`, `password_digest`. Name and email are unique, 4–20 chars. Preferences (edited on the profile page, `users#edit`): `per_page` (`User::PER_PAGE_OPTIONS`), `units` (`us` / `metric`), `theme` (`system` / `light` / `dark`), `default_water` (nil = any), `scientific_names_first`, `strict_add_search`, `default_tank_public`.
- `Aquarium` — `size` (decimal, always US gallons; shown and entered in the user's units via `Units` / `UnitsHelper`), `water_type` (keys of `Aquarium::WATER_TYPES`, which maps them to species water values), `filter`, `plants` (boolean: live vs artificial/none), `substrate`, `public` (others can see it), `user_id`. Other select options live in [app/views/aquariums/_form.html.erb](app/views/aquariums/_form.html.erb). `Aquarium.visible_to(user)` = public tanks plus that user's own.
- `Species` — `common_name`, `taxonomic_name`, `category` (`fish` / `invertebrate` / `plant` / `amphibian`), `image_url`, `size`, `other_remarks`, `preferred_water` (`freshwater` / `brackish_water` / `saltwater`). Only a name (common or scientific) is required; views show only the fields that are filled in. `Species.search(term)` requires every word of the term to appear (as a substring, any order) in the common name, scientific name or an alias, so "cory panda" finds "Panda corydoras". Was `Fish` until Nov 2026.
- `SpeciesAlias` — extra common names for a species (`name`), e.g. "skirt tetra" for Black tetra. Edited on the species form as comma-separated `alias_list`.
- `AquariumSpecies` — join model (table `aquarium_species`); validates `count >= 0`. A count of 0 means the species died out but the entry is kept (shown greyed out) so the owner can restock.

Deletes cascade through the models: User → its aquariums → their `aquarium_species`, and Species → its `aquarium_species` and aliases (all `dependent: :destroy`). Foreign keys on `aquarium_species` and `aquariums.user_id` back this up in the database, so a raw SQL delete of a referenced row fails instead of leaving orphans.

"species" is uncountable, so `resources :species` gives `species_index_path` for the list page and `species_path(s)` for one species. [config/initializers/inflections.rb](config/initializers/inflections.rb) also has a rule so `aquarium_species` singularizes correctly (Rails would otherwise make it `aquarium_specy`), plus `aquarium → aquariums` (why the aquarium fixture file is `aquaria.yml`).

Species pictures go through `species_image_tag` ([app/helpers/species_helper.rb](app/helpers/species_helper.rb)): a blank `image_url`, or one that fails to load, shows the local `fishbowl-clipart-acquarium-15.png`. The broken-image swap is an inline `onerror`, which would need allowing if a Content Security Policy is turned on.

## Request flow

- Routes: [config/routes.rb](config/routes.rb). Root is `pages#home`. Auth routes: `GET/POST /login`, `DELETE /logout`, `GET /sign-up`. Extra: `POST /aquariums/:id/add_species` (form sends `species_id` + `count`; the "+" button sends no count, meaning 1), `DELETE /aquariums/:id/remove_species` (`aquarium_species_id`, plus `all` to delete the entry), `GET /search_species?term=&water=&strict=` (JSON for the tank page's search-as-you-type: `id`, `text` (main name), `other_name`, `kind`, `suits_water`; needs 2+ characters; tank's water first, or only with `strict`). The catalog index takes `q`, `category` and `water` filters; no `water` param means the user's `default_water`, a blank one means "Any".
- **Preferences:** read them through `preferences` (ApplicationHelper, `helpers.preferences` in controllers). It's `current_user`, or `User.new` for guests, so the column defaults are the guest settings and nothing needs a nil check. Name display goes through `species_name` / `species_other_name` / `scientific_first?` ([species_helper.rb](app/helpers/species_helper.rb)), sizes through `species_size` and volumes through `tank_volume` ([units_helper.rb](app/helpers/units_helper.rb)).
- **Paging:** `paginate(scope)` from the `Pagination` concern (included in `ApplicationController`) returns one page and sets `@page`; render `shared/pagination` with `page: @page`. Links keep the rest of the query string. Used on the catalog, All Tanks and a user's tanks.
- **Privacy:** `AquariumsController#require_visible` redirects anyone but the owner away from a private tank; lists use `Aquarium.visible_to`.
- **Theme:** Tailwind uses `darkMode: 'class'`. The layout puts the theme in `<meta name="aquatanks-theme">`, and an inline head script sets `dark` on `<html>` from it on load and after every `turbo:render` (Turbo keeps `<html>`). Don't switch to a `data-turbo-track="reload"` approach: the extra reload eats flash messages.
- The tank page's add box is a Stimulus controller, [species_search_controller.js](app/javascript/controllers/species_search_controller.js); it builds result rows with `textContent`, so keep it that way rather than `innerHTML`. `AquariumsController#show` builds `@stock_by_category` for the grouped stocked list.
- `current_user` / `logged_in?` live in `ApplicationHelper` (session `:user_id`); controllers reach them via `helpers.current_user`.
- `ApplicationController` defines `require_user` (redirect guests to login) and `is_signed_in?` (redirect logged-in users away from login/sign-up). `AquariumsController` uses `require_user` for new/create and its own `require_owner` for edit/update/destroy/add_species/remove_species.
- Nav (desktop + mobile hamburger) is [app/views/shared/_nav.html.erb](app/views/shared/_nav.html.erb); the hamburger toggle is vanilla JS in [app/javascript/application.js](app/javascript/application.js) (bound on `DOMContentLoaded`, not a Stimulus controller).
- "My Tanks" is `users#show`, which lists that user's aquariums (only the public ones to other people). "Profile" is `users#edit`: you can only edit yourself, and changing email or password needs the current password.

## Seeding

[db/seeds.rb](db/seeds.rb) defines `SpeciesScraper`, which uses Nokogiri + open-uri to scrape eight Wikipedia lists (`SpeciesScraper::PAGES`, each tagged with a water type and category): about 2200 species as of Nov 2026. Details are in [DESIGN.md](DESIGN.md#the-species-scraper).

- Each page splits species into many tables, with different column names and orders. Columns are found by matching header text (`SpeciesScraper::COLUMNS`), not by position. If Wikipedia renames a header, update those regexes.
- Tables are expanded into a grid first (`grid`), copying `rowspan`/`colspan` cells into every position they cover. The plant, invertebrate and amphibian pages merge Genus cells down several rows.
- Common names are split on commas, semicolons and " or " (not inside parentheses, not on `/`): the first is `common_name`, the rest become aliases.
- Some freshwater plant rows list a whole genus in one cell as a bulleted list; `genus_list` turns each entry into its own species.
- Re-running is safe: species are upserted on `taxonomic_name` + `preferred_water` + `category` + `common_name`. The same species can appear once per water type (e.g. Guppy is both freshwater and brackish).

## Styling conventions

- Tailwind utility classes inline in ERB; every view supports `dark:` variants (cyan/teal palette).
- Buttons reuse this exact class string: `text-xs inline-block rounded bg-teal-700 dark:bg-teal-500 px-3 pt-2 pb-1.5 mt-1.5 self-end`, usually on a `link_to` wrapped in `<button type="button">`.
- Cards: `block max-w-sm mx-auto rounded-lg bg-white p-6 shadow-lg dark:bg-neutral-700`.
- Page titles: `text-center underline underline-offset-4 text-3xl font-medium mb-4`.
- Listing pages use `grid lg:grid-cols-3 md:grid-cols-2`.

## Known issues / gotchas

- The layout renders `flash`: `alert:` messages are red, everything else (`notice:`) is teal. Use `alert:` for failures.
- Species CRUD is open to anyone, signed in or not.
- The aquarium and user controller tests are broken scaffold stubs (missing `aquariums` fixture, no `new_user_url` route), and so are the old aquarium/user system tests. Working tests: `ruby bin/rails test test/models test/helpers test/controllers/species_controller_test.rb test/integration`, then separately `ruby bin/rails test test/system/species_search_test.rb test/system/theme_test.rb` (Chrome). Mixing the two kinds in one command fails. Integration tests sign in with `sign_in_new_user(**preferences)` from test_helper (the users.yml fixtures have no usable password; emails are capped at 20 characters). In system tests click the login *button*: the nav also has a "Login" link.
- Aquarium index's "Owner" link points at `@user` (nil) instead of `aquarium.user`.
- Views pull some images from external clipart URLs.