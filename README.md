[![CI](https://github.com/mveytsman/bike-brigade/workflows/CI/badge.svg)](https://github.com/mveytsman/bike-brigade/actions?query=workflow%3ACI)
# BikeBrigade

## Prerequisities
1.  [nix](https://nixos.org/download.html)
1.  [docker](https://www.docker.com/get-started)

## Getting an environment set up
1. Clone this repo
2. Copy the env file `cp .env.local.sample .env.local`
3. Run `nix-shell` inside the directory. This will create an environment that has all the dependencies installed locally.
4. Inside the nix shell, run `docker-compose up -d`
5. To install dependencies, run `mix deps.get`
6. To set up the database run `mix do ecto.create, ecto.migrate`
7. To set up the assets, `npm install --prefix=assets/`
8. To install seeds, `mix run priv/repo/seeds.exs`

## Development environment
You'll want to be inside the `nix-shell` when working on this project. Make sure postgres is running with `docker-compose up -d`

To start the server & console run:

```
scripts/server
```

Note: if you want the Elixir language server to be accessible to your editor, you will have to lauch your editor from within the `nix-shell`, or do some [direnv](https://github.com/direnv/direnv/) or [lorri](https://github.com/target/lorri) magic.

### Testing

You can run the entire test suite with

```
scripts/test
```

If you wish to run a specific test you can provide a file and optionally a line number

```
scripts/test path/to/test.exs:LINENUMBER
```

### Updating nix dependencies
[niv](https://github.com/nmattia/niv) is used to ensure everyone is using the same version of nixpkgs.
To update the nixpkgs version run:

```
nix-shell -p niv
niv update
```

You can then commit the changes.

## Deploying

### Staging

Force push to the staging branch in order to deploy to staging

```
scripts/deploy_staging
```

### Production

Pushes to the `main` branch (including merged PRs) automatically trigger a production deploy. Please **be aware of this when pushing small changes without a PR.**

## External dependencies
- [Google Drive API](https://developers.google.com/drive/api/v3/reference)
- [Google Maps API](https://developers.google.com/maps/documentation)
- [Google Storage API](https://cloud.google.com/storage/docs/apis)
- [LeafletJS](https://leafletjs.com/)
- [Mailchimp API](https://mailchimp.com/developer/)
- [Mapbox Tiles](https://docs.mapbox.com/help/glossary/static-tiles-api/)
- [Slack API](https://api.slack.com/)
- [Tailwind](https://tailwindcss.com/)
- [TailwindUI](https://tailwindui.com/) - paid library of Tailwind components. Licensed to [@mveytsman](https://github.com/mveytsman).
- [Twilio](https://www.twilio.com/)


# Contributors
This project's history has been squashed as part of open-sourcing, so not all contributions are reflected in the Git history.

Please see [CONTRIBUTORS.md](https://github.com/bikebrigade/dispatch/blob/main/CONTRIBUTORS.md) for the list of contributors.

# License

Copyright 2021 The Bike Brigade Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
