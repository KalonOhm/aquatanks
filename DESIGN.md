# Aquatanks design notes

## Project goals

Aquatanks is a place to record home aquariums and what lives in them.

1. **Describe a tank.** Size in gallons, water type (freshwater, saltwater, brackish), filter style, live or artificial plants, substrate.
2. **Stock it from a real species list.** Users pick fish from a catalog of about 1450 aquarium species instead of typing names freehand, and record how many of each they keep.
3. **Browse.** Anyone can look through the fish catalog and see everyone's tanks. Signed-in users manage their own tanks under "My Tanks".
4. **Stay small.** Plain Rails with server-rendered views, Tailwind and SQLite. No JavaScript build step and no external services at runtime.

### Planned / open work

These come from TODOs and commented-out code in the repo:

- **Search-as-you-type when adding fish.** The Add Fish form is currently a dropdown of every species. `GET /search_fishes?term=` already returns `[{id, text}]` JSON for an autocomplete box.
- **Link to other users' pages** from a tank's "Owner" line.
- **Validate fish image URLs.** There's a commented-out `image_url_exists` check in `Fish`.

Possible next steps that follow naturally from the data, but aren't committed to:

- Remove a fish from a tank, or change how many there are.
- Warn when a fish's `preferred_water` doesn't match the tank's `water_type`.
- Enforce ownership on the server (today only the view hides edit and delete buttons from non-owners).

## Data model

```
User 1──* Aquarium *──* Fish
                 └── aquariums_fishes (aquarium_id, fish_id, count)
```

- A **Fish** is a species from the catalog, shared by everyone, not an individual animal.
- A row in **aquariums_fishes** (model `AquariumFish`) says "this tank has *count* of this species". `count` must be greater than 0.
- `Fish.preferred_water` is one of `freshwater`, `brackish_water` or `saltwater`. It records which Wikipedia list the species came from.

## The fish scraper

The catalog comes from Wikipedia, scraped once at setup by [db/seeds.rb](db/seeds.rb) (`ruby bin/rails db:seed`). The app never contacts Wikipedia while it's running.

### Sources

| Page | `preferred_water` |
|---|---|
| [List of freshwater aquarium fish species](https://en.wikipedia.org/wiki/List_of_freshwater_aquarium_fish_species) | `freshwater` |
| [List of brackish aquarium fish species](https://en.wikipedia.org/wiki/List_of_brackish_aquarium_fish_species) | `brackish_water` |
| [List of marine aquarium fish species](https://en.wikipedia.org/wiki/List_of_marine_aquarium_fish_species) | `saltwater` |

### What the pages look like (as of Oct 2026)

- Each page holds many tables, one per fish family.
- Column names and order differ between pages, and sometimes between tables on the same page:
  - Freshwater: Common name, Scientific name, Image, Size, Remarks, Tank size, …
  - Brackish: Common name, Taxonomy, Picture, Size, Remarks, Salinity. One table has "Tank type" instead of Size.
  - Marine: Common name, Image, Taxonomy, Reef safe, Description, Max size.
- Tables contain blank rows and family-name divider rows: a single cell spanning the table width.
- Image `src`s are protocol-relative (`//upload.wikimedia.org/...`) and carry tracking query parameters.
- No table uses `rowspan`.

### How it handles that

1. **Find the fish tables.** Any `<table>` whose first row has a header matching "Common name".
2. **Map columns by header text, not position.** `FishScraper::COLUMNS` holds one regex per field. Each table works out its own column indexes from its header row, so the same code handles all three pages.

   | Field | Matches headers like |
   |---|---|
   | `common_name` | Common name |
   | `taxonomic_name` | Scientific name, Taxonomy, Binomial |
   | `image_url` | Image, Picture, Photo |
   | `size` | Size, Max size (but not "Tank size") |
   | `other_remarks` | Remarks, Description |

   A column a table doesn't have becomes `nil`.
3. **Skip rows that don't fit.** A row is used only when its number of cells equals the number of headers. That drops blank rows and divider rows without special-casing them.
4. **Clean the values.**
   - Remove citation markers like `[12]` and collapse whitespace.
   - Prefix image URLs with `https:` and strip the query string.
   - If a fish has no common name, use its scientific name, so the dropdown never shows a blank entry.
   - Skip rows with neither name.
   - Store sizes as the full text (`50 cm (19.5 in)`), because the formats vary too much to parse into numbers reliably.
5. **Upsert, don't append.** Fish are matched on `common_name` + `taxonomic_name` + `preferred_water` and updated in place. Re-running the seed refreshes the catalog without duplicating fish, and without breaking tanks that already reference them. A species can appear once per water type (Guppy is in both the freshwater and brackish lists).
6. **Keep the placeholder image.** When a row has no image, `image_url` is left out of the update so the column's default placeholder applies.

All writes happen in one transaction, so a failed run leaves the catalog unchanged.

### When Wikipedia changes again

- **A renamed column:** adjust the matching regex in `COLUMNS`.
- **A new column:** nothing to do, it's ignored.
- **Fewer fish than expected:** usually rows are being skipped by the cell-count check. If a page starts using `rowspan`, the scraper will need to expand spans into a grid before reading cells.
- **Debugging:** load one page in `ruby bin/rails console`, then print each table's header row and the cell count per row. Wikipedia asks automated clients to send a descriptive User-Agent, which the scraper does.
