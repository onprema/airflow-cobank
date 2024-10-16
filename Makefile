local-setup:
	@if ! grep -q "^AIRFLOW_UID=" .env 2>/dev/null; then \
		echo AIRFLOW_UID=$$(id -u) >> .env; \
	fi

local-init-db:
	docker compose up airflow-init

local-up: local-setup local-init-db
	docker compose up

local-down:
	docker compose down --volumes --remove-orphans

clean:
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type d -name "*.pyc" -exec rm -rf {} +
