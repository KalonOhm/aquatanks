# Aquatanks 🐠

Aquatanks is a Rails app for recording your aquariums and what lives in them. Describe a tank (size, water type, filter, plants, substrate), then stock it from a catalog of about 2200 aquarium fish, invertebrates, plants and amphibians scraped from Wikipedia. You can also browse the catalog and other people's tanks.

Goals, the data model and how the scraper works are in [DESIGN.md](DESIGN.md).

## Stack

- Ruby 4.0, Rails 8.1, SQLite
- Hotwire (Turbo + Stimulus) via importmap, so there's no Node or `npm install`
- Tailwind CSS v3 via `tailwindcss-rails`
- Sign-in with `has_secure_password`

## Setup

Requirements: Ruby 4.0. On Windows, use [RubyInstaller](https://rubyinstaller.org/) **with Devkit**, and make sure Ruby's `bin` folder is on your PATH.

```sh
gem install bundler
bundle install
bin/rails db:create db:migrate
bin/rails db:seed      # downloads the species catalog from Wikipedia (needs internet)
```

The seed is safe to run again: it updates existing species instead of duplicating them.

## Running

```sh
bin/dev
```

This starts the Rails server on http://localhost:3000 and the Tailwind watcher together.

### Windows (PowerShell)

The `bin/` scripts have no file extension, so prefix them with `ruby`. `bin/dev` is a shell script, so use two terminals instead:

```powershell
ruby bin/rails db:seed

# terminal 1
ruby bin/rails server
# terminal 2
ruby bin/rails tailwindcss:watch
```

## Tests

```sh
bin/rails test           # model and controller tests
bin/rails test:system    # browser tests (needs Chrome)
```

Most tests are still the stubs Rails generated.

## Status

This is a work in progress. Known gaps:

- Anyone can add, edit or delete catalog species.
- Search doesn't tolerate typos yet.
- You can't delete your account from the profile page yet.

See [DESIGN.md](DESIGN.md#planned--open-work) for what's planned.
