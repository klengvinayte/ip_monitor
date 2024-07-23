How to run the project with Docker

```angular2html
docker-compose up --build
```
```angular2html
docker-compose up -d web
```

How to set up the database with Docker
```angular2html
docker-compose exec web rake db:setup
```

```angular2html
docker-compose exec web rake db:migrate
```

```angular2html
docker-compose exec web rake db:dump_schema
```


How to run the tests with Docker
```angular2html
docker-compose run test rspec
```
