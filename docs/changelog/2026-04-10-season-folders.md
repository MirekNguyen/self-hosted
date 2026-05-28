# Season Folders & Jellyfin Metadata Providers — 2026-04-10

## Problem

41 out of 52 Sonarr series had `seasonFolder: false`. All episode files were dumped in the root series folder (e.g., `/downloads/anime/JUJUTSU KAISEN/`) without `Season XX/` subfolders. Jellyfin couldn't determine correct seasons from the flat file structure.

Additionally, Jellyfin's Anime library had AniDB listed in the metadata fetcher **order** but not in the **enabled** fetchers list — meaning AniDB metadata was never actually fetched. The TV Shows and Movies libraries had AniDB enabled (irrelevant, slows lookups) and `EnableInternetProviders: false`.

## Changes

### Sonarr: Season folders enabled (all 41 series)

- Used Sonarr bulk editor API (`PUT /api/v3/series/editor`) to set `seasonFolder: true` on all 41 affected series
- Triggered `RenameFiles` command on 33 series that had existing files (459 total files moved)
- Files moved from flat structure into proper `Season XX/` subfolders
- Example: `JUJUTSU KAISEN/[Erai-raws] Jujutsu Kaisen...mkv` -> `JUJUTSU KAISEN/Season 03/JUJUTSU KAISEN (2020) - S03E12 - 059 - Sendai Colony [...].mkv`

Affected series include: To Be Hero X, The Last of Us, Kowloon Generic Romance, The Pitt, Queen of Tears, When Life Gives You Tangerines, The Bear, Lord of Mysteries, My Dress-Up Darling, The Fragrant Flower Blooms with Dignity, Blue Eye Samurai, GNOSIA, Alice in Borderland, PLUR1BUS, Stranger Things, My Hero Academia, Heavenly Delusion, Fire Force, Sentenced to Be a Hero, Fate/strange Fake, Heated Rivalry, The Mandalorian, JUJUTSU KAISEN, Hell's Paradise, The Studio, Can This Love Be Translated?, A Knight of the Seven Kingdoms, Frieren, Hometown Cha-Cha-Cha, Kingdom, Classroom of the Elite, MARRIAGETOXIN, Witch Hat Atelier.

8 series without files (Lajna, What's Wrong with Secretary Kim, Alchemy of Souls, Surely Tomorrow, Spice Up Our Love, Death's Game, Move to Heaven, Resident Playbook) had the flag set for future downloads.

### Jellyfin: Metadata providers optimized

**Anime library** (`/downloads/anime`):
- Enabled AniDB as primary metadata fetcher for Series, Season, and Episode types (was in order but disabled)
- Added AniDB to episode image fetchers
- Enabled `EnableInternetProviders` and `EnableAutomaticSeriesGrouping`

**TV Shows library** (`/downloads/tv-shows`):
- Removed AniDB from all fetcher lists (irrelevant for non-anime)
- Set TMDb as primary, OMDB as fallback
- Enabled `EnableInternetProviders`

**Movies library** (`/downloads/movies`):
- Removed AniDB from all fetcher lists
- Set TMDb as primary, OMDB as fallback
- Enabled `EnableInternetProviders`

Triggered full library rescan after all changes.

## Files changed

- `docs/jellyfin.md` — Added metadata providers section, plugin inventory
- `docs/sonarr.md` — Added season folders section
- `docs/changelog/2026-04-10-season-folders.md` — This file

## Decisions

- **AniDB only in Anime library**: AniDB is specialized for anime. Including it in TV/Movies libraries causes unnecessary API calls and can return incorrect matches for non-anime content.
- **TMDb as primary for TV/Movies**: TMDb has the most comprehensive and accurate metadata for Western TV shows and movies. OMDB fills gaps.
- **AniDB as primary for Anime**: AniDB handles absolute episode numbering, Japanese titles, and anime-specific season grouping better than TMDb.
- **EnableAutomaticSeriesGrouping**: Helps Jellyfin group anime seasons that AniDB treats as separate entries.
