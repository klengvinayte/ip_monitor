### IP address availability monitoring system.

This is an application that allows you to register and delete IP addresses, as well as check their availability

**How to run the project with Docker**

```angular2html
docker-compose up --build
```
```angular2html
docker-compose up -d web
```

**How to set up the database with Docker**
```angular2html
docker-compose exec web rake db:setup
```

```angular2html
docker-compose exec web rake db:migrate
```

```angular2html
docker-compose exec web rake db:dump_schema
```


**How to set up the TimescaleDB extension**
```angular2html
docker-compose exec db psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}
```

```angular2html
CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;
```

**How to run the tests with Docker**

Run the following commands to run the tests:
```angular2html
docker-compose run web rake db:migrate RAILS_ENV=test
```

```angular2html
docker-compose run test rspec
```

[CI](https://github.com/<YOUR-USER>/<YOUR-REPO>/actions/workflows/ci.yml/badge.svg)

