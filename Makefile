.PHONY: network-up network-down network-clean

network-up:
	@echo "Starting network..."
	./scripts/generate_certs.sh
	cd infrastructure/fabric && /usr/bin/docker-compose up -d
	@echo "Waiting for containers to stabilize..."
	sleep 5
	./scripts/init_network.sh

infra-up:
	@echo "Starting backend infrastructure (Postgres + Kafka)..."
	/usr/bin/docker-compose --env-file .env -f infrastructure/docker-compose-backend.yaml up -d

infra-down:
	@echo "Stopping backend infrastructure..."
	/usr/bin/docker-compose --env-file .env -f infrastructure/docker-compose-backend.yaml down -v

app-up:
	@echo "Starting Backend App (API + Worker)..."
	/usr/bin/docker-compose --env-file .env -f backend/docker-compose-app.yaml up -d --build

app-down:
	@echo "Stopping Backend App..."
	/usr/bin/docker-compose --env-file .env -f backend/docker-compose-app.yaml down

test:
	@echo "Running chaincode tests..."
	./scripts/test_chaincode.sh

network-down:
	@echo "Stopping network..."
	cd infrastructure/fabric && /usr/bin/docker-compose down -v


network-clean: network-down
	@echo "Cleaning up..."
	./scripts/clean_generated_files.sh
	@echo "Cleanup done."
