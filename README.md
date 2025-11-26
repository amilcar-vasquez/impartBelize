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

Once the database exits, the migrations must be pushed to create the tables and seed inital data.

```bash
make db/migrations/up
```
