# airflow-cobank

This repository contains code related to the Airflow training for CoBank. We will be using Apache Airflow v2.10.2.

## Running Airflow locally

**This requires [Docker](https://docs.docker.com/engine/install/)**

Run the following command to start Airflow using Docker Compose
```
make local-up
```

If the command ran successfully, you can access the Airflow UI at `localhost:8080` and login with username `airflow` and password `airflow`.

To clean up the local environment, run
```
make local-down
```

This will stop Airflow and remove the Docker containers and volumes.
