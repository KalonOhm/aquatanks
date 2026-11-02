# Aquatanks design notes

## Project goals

Aquatanks is a place to record home aquariums and what lives in them.

1. **Describe a tank.** Size in gallons, water type (freshwater, saltwater, brackish), filter style, live or artificial plants, substrate.
2. **Stock it from a real species list.** Users pick from a catalog of about 2200 aquarium fish, invertebrates, plants and amphibians instead of typing names freehand, and record how many of each they keep.
3. **Browse.** Anyone can look through the species catalog and see everyone's tanks. Signed-in users manage their own tanks under "My Tanks".
4. **Stay small.** Plain Rails with server-rendered views, Tailwind and SQLite. No JavaScript build step and no external services at runtime.

### Planned / open work

- **Typo-tolerant search.** Search matches each word separately, in any order, as part of any name ("sword amazon" finds every Amazon sword), but "anubius" finds nothing. Options: a closest-spelling check in Ruby, or SQLite full-text search with trigrams.
- **Link to other users' pages** from a tank's "Owner" line.
- **Validate image URLs.** There's a commented-out `image_url_exists` check in `Species`. Broken images already fall back to a placeholder in the view.

Possible next steps that follow naturally from the data, but aren't committed to:

- Warn on the tank page when something already stocked doesn't match the tank's water. (The add search already flags mismatches before adding.)
- Work out the tank's live-plants flag from the plants stocked in it.
- Scrape the brackish invertebrate and plant lists (see Sources below).

## Finding and adding species

- **Catalog page** (`/species`): a search box plus category and water filters, all plain GET parameters (`q`, `category`, `water`), so a filtered list can be bookmarked or shared.
- **Tank page:** the owner adds species through a search-as-you-type box instead of a dropdown of every species. A Stimulus controller ([species_search_controller.js](app/javascript/controllers/species_search_controller.js)) asks `GET /search_species?term=&water=` as you type. Species suited to the tank's water come first; the rest are flagged "doesn't match this tank's water" but can still be added. Picking a result fills a hidden `species_id` and enables the Add button.
- **Stocked list:** grouped under Fish / Invertebrates / Plants / Amphibians headings, alphabetical within each. A species at 0 is greyed out: "population collapsed" for animals, "none left" for plants.
- **Search rule** (`Species.search`): every word typed has to appear somewhere in the common name, scientific name or an alias, as part of a word and in any order.

## User preferences

Signed-in users set these on their Profile page (`users#edit`). Guests get the defaults, which are the `users` column defaults.

| Preference | Options (default first) | What it changes |
|---|---|---|
| Results per page | 25, 10, 50, 100 | Catalog, All Tanks and a user's tanks. A `?per_page=` in the URL overrides it for that page. |
| Units | US, metric | Tank volume (gallons / litres) and species sizes (inches / cm). Temperature (°F / °C) will follow once something stores a temperature. |
| Theme | Follow my device, light, dark | The colour scheme. |
| Show species for | Any water type, or one of the three | The catalog's starting water filter (picking "Any" there still shows everything), and the water type preselected for a new tank. |
| Scientific names first | off | Lists, the species page, the stocked list and add-search results lead with the Latin name. |
| Strict add search | off | The add box only suggests species matching the tank's water, instead of flagging mismatches. |
| New tanks visible to others | on | Starting value of a new tank's own public/private setting. |

The profile page also edits name, email and password (email and password changes need the current password).

**Units:** tank volume is always stored in US gallons, as a decimal so litres survive the round trip. Wikipedia gives most species sizes in both units ("33 cm (13.0 in)"), so the page shows just the preferred half of each pair; sizes in any other format are shown as written.

**Privacy:** each tank is public or private. Private tanks are left out of All Tanks and the owner's tank list for everyone but the owner, and opening one redirects. Tanks that existed before privacy was added are public.

**Paging** is hand-rolled (the `Pagination` concern and `shared/_pagination`) rather than a gem, in keeping with "stay small".

### Ideas for later preferences

Time zone (for future maintenance logs), water-change/maintenance reminders (needs a mailer and background jobs), a profile display name/bio/avatar, default catalog sort, a compact list vs picture cards, a confirm-before-"−" toggle, and deleting your account (the route exists and the cleanup rules already cascade).

## Data model

```
User 1──* Aquarium *──* Species 1──* SpeciesAlias
                 └── aquarium_species (aquarium_id, species_id, count)
```

- A **Species** is an entry in the catalog, shared by everyone, not an individual animal or plant. It has a `category`: `fish`, `invertebrate`, `plant` or `amphibian`.
- **Only a name is required.** A species needs a common name or a scientific name. Everything else (picture, size, remarks, water type) is optional, and pages show only the fields that are filled in. A missing or broken picture shows a placeholder image.
- A **SpeciesAlias** is another common name for a species. Wikipedia often gives several ("Black tetra, skirt tetra"); the first becomes `common_name` and the rest become aliases, so searching any of them finds the species.
- A row in **aquarium_species** (model `AquariumSpecies`) says "this tank has *count* of this species". `count` can be 0: the species died out, but the tank keeps the entry so the owner remembers what to restock.
- **Nothing is left pointing at a deleted record.** Deleting a user deletes their tanks, deleting a tank deletes what's stocked in it, and deleting a species from the catalog removes it from every tank. Database foreign keys enforce the same links.
- `Species.preferred_water` is one of `freshwater`, `brackish_water` or `saltwater`. For scraped species it records which Wikipedia list the species came from.

Until Nov 2026 the catalog only held fish, and `Species` was called `Fish` (table `fishes`, join table `aquariums_fishes`). The rename migration kept every existing row.

## The species scraper

The catalog comes from Wikipedia, scraped once at setup by [db/seeds.rb](db/seeds.rb) (`ruby bin/rails db:seed`). The app never contacts Wikipedia while it's running.

### Sources

| Page | `preferred_water` | `category` | Species (Nov 2026) |
|---|---|---|---|
| [Freshwater aquarium fish](https://en.wikipedia.org/wiki/List_of_freshwater_aquarium_fish_species) | `freshwater` | `fish` | 1450 fish across these three |
| [Brackish aquarium fish](https://en.wikipedia.org/wiki/List_of_brackish_aquarium_fish_species) | `brackish_water` | `fish` | |
| [Marine aquarium fish](https://en.wikipedia.org/wiki/List_of_marine_aquarium_fish_species) | `saltwater` | `fish` | |
| [Freshwater aquarium invertebrates](https://en.wikipedia.org/wiki/List_of_freshwater_aquarium_invertebrate_species) | `freshwater` | `invertebrate` | ~50 |
| [Marine aquarium invertebrates](https://en.wikipedia.org/wiki/List_of_marine_aquarium_invertebrate_species) | `saltwater` | `invertebrate` | ~140 |
| [Freshwater aquarium plants](https://en.wikipedia.org/wiki/List_of_freshwater_aquarium_plant_species) | `freshwater` | `plant` | ~340 |
| [Marine aquarium plants](https://en.wikipedia.org/wiki/List_of_marine_aquarium_plant_species) | `saltwater` | `plant` | ~135 (macroalgae, seagrass, mangroves) |
| [Freshwater aquarium amphibians](https://en.wikipedia.org/wiki/List_of_freshwater_aquarium_amphibian_species) | `freshwater` | `amphibian` | ~100 |

Not scraped: the [brackish invertebrate](https://en.wikipedia.org/wiki/List_of_brackish_aquarium_invertebrate_species) and [brackish plant](https://en.wikipedia.org/wiki/List_of_brackish_aquarium_plant_species) lists. They're short bullet lists (~35 entries in all, no pictures, many scientific names only) rather than tables, and their most useful entries (Amano shrimp, nerite snails) are already on the freshwater pages. Aquatic turtles were left out on purpose: they need land and basking areas, which a tank record doesn't describe.

### What the pages look like (as of Nov 2026)

- Each page holds many tables, one per family or group.
- Column names and order differ between pages, and sometimes between tables on the same page:
  - Freshwater fish: Common name, Scientific name, Image, Size, Remarks, Tank size, …
  - Brackish fish: Common name, Taxonomy, Picture, Size, Remarks, Salinity. One table has "Tank type" instead of Size.
  - Marine fish, invertebrates and plants: Common name(s), Image, Taxonomy, (Reef safe / Temperament / Care level / Lighting …), Description or Notes, Max size.
  - Freshwater invertebrates, plants and amphibians: (Family,) Genus, Species, Common name, (Size, Care notes, Distribution, Status,) Commercial sources, Image. The Species column holds the full binomial.
- Tables contain blank rows and family-name divider rows: a single cell spanning the table width.
- The Genus/Species pages use `rowspan`: one Genus cell covers all the species rows below it.
- Some freshwater plant rows list a whole genus in one Species cell as a bulleted list: "*Anubias afzelii* (Narrow-leafed anubias)", one per line. One cell runs its entries together with `*` instead.
- Several common names in one cell are separated by commas, semicolons or "or". Slashes usually join half-names ("Adolfo's catfish/corydoras", "Regal / Hippo tang").
- Empty cells are sometimes written as "none", "N/A" or "?". Missing pictures are sometimes the text "Needs quality image".
- Image `src`s are protocol-relative (`//upload.wikimedia.org/...`) and carry tracking query parameters.

### How it handles that

1. **Find the species tables.** Any `<table>` whose first row has a header matching "Common name".
2. **Expand spans into a grid.** Before reading anything, each table becomes a plain grid of rows and columns: a cell with `rowspan` or `colspan` is copied into every position it covers. After that, column *n* of every row really is column *n*.
3. **Map columns by header text, not position.** `SpeciesScraper::COLUMNS` holds one regex per field. Each table works out its own column indexes from its header row, so the same code handles every page.

   | Field | Matches headers like |
   |---|---|
   | `common_name` | Common name, Common name(s), Common names |
   | `taxonomic_name` | Scientific name, Taxonomy, Binomial, Species |
   | `genus` | Genus (only used when the Species cell is blank or "?") |
   | `image_url` | Image, Picture, Photo |
   | `size` | Size, Max size, Max size (bell diameter), but not "Tank size" |
   | `other_remarks` | Remarks, Description, Notes, Care notes |

   A column a table doesn't have becomes `nil`.
4. **Skip rows that don't fit.** A row is used only when it has one cell per header and isn't a single cell spanning the whole width. That drops blank rows and divider rows without special-casing them.
5. **Split genus lists.** A Species cell containing a bulleted list becomes one species per entry: the text before the parentheses is the scientific name, the text inside is the common name(s). The row's picture shows only one of them, so these entries get no picture.
6. **Split common names into aliases.** Commas, semicolons and " or " separate names, except inside parentheses ("Siamese fighting fish (sometimes Betta, esp. US)" stays whole). In genus lists only commas and semicolons do: there "or" joins two adjectives sharing a noun ("Crinkled or ruffled aponogeton"). The first name is `common_name`; the rest are saved as `SpeciesAlias` rows, minus any that just repeat the scientific name.
7. **Clean the values.**
   - Remove footnote markers like `[12]`, `[a]` and `[citation needed]`, and collapse whitespace.
   - Treat "none", "N/A", "?", "-" and "unknown" as blank.
   - Prefix image URLs with `https:` and strip the query string.
   - If a species has no common name, use its scientific name, so the dropdown never shows a blank entry.
   - Skip rows with neither name.
   - Store sizes as the full text (`50 cm (19.5 in)`), because the formats vary too much to parse into numbers reliably.
8. **Upsert, don't append.** Species are matched on `taxonomic_name` + `preferred_water` + `category` + `common_name` and updated in place, so re-running the seed refreshes the catalog without duplicating anything or breaking tanks that reference it. A species can appear once per water type (Guppy is in both the freshwater and brackish lists). Older seeds stored the whole multi-name cell as `common_name`, so a row is also matched on that, which lets those rows be split into aliases in place.
9. **Don't erase saved values.** A field that's blank on Wikipedia this time is left out of the update, so it doesn't wipe a value saved earlier. A species with no picture keeps `image_url` blank, and the view shows the placeholder.

All writes happen in one transaction, so a failed run leaves the catalog unchanged.

### When Wikipedia changes again

- **A renamed column:** adjust the matching regex in `COLUMNS`.
- **A new column:** nothing to do, it's ignored.
- **A new list page:** add it to `PAGES` with its water type and category.
- **Fewer species than expected:** usually rows are being skipped by the cell-count check. Print a table's grid (`SpeciesScraper.grid(table)`) and compare row lengths with the header.
- **Odd-looking names** (very long, or several names run together): usually a new cell layout, like the genus lists. Look for the longest `common_name`s after seeding.
- **Debugging:** load one page in `ruby bin/rails console`, then print each table's header row and the cell count per row. Wikipedia asks automated clients to send a descriptive User-Agent, which the scraper does.
