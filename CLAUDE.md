# CLAUDE.md

Aquatanks is a Rails 8.1 app where users sign up, create aquariums (tanks), and add fish species to them. The fish catalog (~1450 species) is scraped from Wikipedia at seed time. Project goals, planned work and the scraper's design are in [DESIGN.md](DESIGN.md); keep it updated when those change.

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
User 1──* Aquarium *──* Fish     (through aquariums_fishes join table, with a `count` column)
```

- `User` — `name`, `email`, `password_digest`. Name and email are unique, 4–20 chars.
- `Aquarium` — `size` (gallons), `water_type`, `filter`, `plants` (boolean: live vs artificial/none), `substrate`, `user_id`. Select options for these live in [app/views/aquariums/_form.html.erb](app/views/aquariums/_form.html.erb).
- `Fish` — `common_name`, `taxonomic_name`, `image_url` (has a DB default placeholder), `size`, `other_remarks`, `preferred_water` (`freshwater` / `brackish_water` / `saltwater`).
- `AquariumFish` — join model; validates `count >= 0`. A count of 0 means the fish died out but the entry is kept (shown greyed out) so the owner can restock.

Custom inflections in [config/initializers/inflections.rb](config/initializers/inflections.rb): `fish → fishes`, `aquarium → aquariums`. That's why routes/tables use `fishes` and fixtures are named `fish.yml` / `aquaria.yml` (generated before the inflection was added).

## Request flow

- Routes: [config/routes.rb](config/routes.rb). Root is `pages#home`. Auth routes: `GET/POST /login`, `DELETE /logout`, `GET /sign-up`. Extra: `POST /aquariums/:id/add_fish`, `GET /search_fishes`.
- `current_user` / `logged_in?` live in `ApplicationHelper` (session `:user_id`); controllers reach them via `helpers.current_user`.
- `ApplicationController` defines `require_user` (redirect guests to login) and `is_signed_in?` (redirect logged-in users away from login/sign-up). `require_user` is not currently applied anywhere.
- Nav (desktop + mobile hamburger) is [app/views/shared/_nav.html.erb](app/views/shared/_nav.html.erb); the hamburger toggle is vanilla JS in [app/javascript/application.js](app/javascript/application.js) (bound on `DOMContentLoaded`, not a Stimulus controller).
- "My Tanks" is `users#show`, which lists that user's aquariums.

## Seeding

[db/seeds.rb](db/seeds.rb) defines `FishScraper`, which uses Nokogiri + open-uri to scrape three Wikipedia lists (freshwater, brackish, marine aquarium fish), about 1450 fish as of Oct 2026.

- Each page splits fish into many tables (one per family), with different column names and orders (e.g. marine is "Common name, Image, Taxonomy, …, Max size"). Columns are found by matching header text (`FishScraper::COLUMNS`), not by position. If Wikipedia renames a header, update those regexes.
- Rows whose cell count doesn't match the header are skipped (blank rows, family-name divider rows with a single spanning cell). No table currently uses `rowspan`.
- Image `src`s are protocol-relative with tracking params; they're normalised to `https:` with the query stripped. Fish without an image keep the `image_url` column default.
- Re-running is safe: fish are upserted on `common_name` + `taxonomic_name` + `preferred_water`. The same species can appear once per water type (e.g. Guppy is both freshwater and brackish).

## Styling conventions

- Tailwind utility classes inline in ERB; every view supports `dark:` variants (cyan/teal palette).
- Buttons reuse this exact class string: `text-xs inline-block rounded bg-teal-700 dark:bg-teal-500 px-3 pt-2 pb-1.5 mt-1.5 self-end`, usually on a `link_to` wrapped in `<button type="button">`.
- Cards: `block max-w-sm mx-auto rounded-lg bg-white p-6 shadow-lg dark:bg-neutral-700`.
- Page titles: `text-center underline underline-offset-4 text-3xl font-medium mb-4`.
- Listing pages use `grid lg:grid-cols-3 md:grid-cols-2`.

## Known issues / gotchas

- **Join model naming.** The model is `AquariumFish` but the table is `aquariums_fishes`, so the model sets `self.table_name` and both `has_many :aquariums_fishes` associations pass `class_name: "AquariumFish"`. Keep those if you touch the associations. Its partial lives in `app/views/aquariums_fishes/` and must be rendered with an explicit `partial:` path.
- The layout renders `flash`: `alert:` messages are red, everything else (`notice:`) is teal. Use `alert:` for failures.
- **`AquariumsFishesController` contains model code** (`belongs_to`/`validates`), which raises if the controller is ever loaded. No routes point at it.
- `FishesController#destroy` redirects to `fishes` (undefined) — should be `fishes_path`.
- `resources :aquariums` is declared twice in routes.
- No authorization on aquarium edit/update/destroy: only the view hides buttons for non-owners. Fish CRUD is open to anyone.
- Aquarium index's "Owner" link points at `@user` (nil) instead of `aquarium.user`.
- Views pull some images from external clipart URLs.
- `association_map.drawio` at the repo root is a diagram of the model associations.
