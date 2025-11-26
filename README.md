# impartBelize

## How to get started

clone the repo and cd into the project

```bash
git clone https://github.com/amilcar-vasquez/impartBelize.git
cd impartBelize
```

create a .envrc file using the .envrc.example template or rename it and fill in the variables

```bash
mv .envrc.example .envrc
```

Next run the setup script to create the database with the appropriate permisions.

```bash
make db/setup
```

Once the database exits, the migrations must be pushed to create the tables and seed initial data.

```bash
make db/migrations/up
```

The API should be good to go. you can now start the server with

```bash
make run/api
```

Test the api availability in the web browser by going to

```HTTP
http://localhost:4000/v1/healthcheck
```

## Getting started with Flutter for the UI

The flutter project can be found under the /ui directory

```bash
cd ui
```

Make sure that flutter is installed by running

```bash
flutter --version
```

check if it has any missing flutter dependencies and fix them

```bash
flutter doctor
```

Install the project dependencies

```bash
flutter pub get
```

Start an emulator using android studio then Check the devices available to run

```bash
flutter devices
```

run on an android emulator

```bash
flutter run -d <emulator-id>
#flutter run -d emulator-5554
```

supabase_flutter package uses native dependencies so it takes a while to download. you can check the progress with the `--verbose` flag

## How to use

The very first user that registers using the mobile app is given the admin role. everyone else is given the user role by default and can only be changed by the admin account.
