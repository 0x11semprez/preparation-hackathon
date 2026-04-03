-include .env
export
OG_RPC ?= https://evmrpc-testnet.0g.ai

dev: .installed
	@echo "  ⚡ radegast — anvil:8545 api:8000 app:3000"
	@trap 'kill 0' INT; \
		anvil --chain-id 31337 --silent & \
		cd ai && .venv/bin/uvicorn v3.fastapi.server:app --host 0.0.0.0 --port 8000 --reload & \
		(test -f frontend/package.json && cd frontend && pnpm dev || sleep infinity) & \
		wait

.installed: install.sh
	@chmod +x install.sh && ./install.sh && touch .installed
front:
	@cd frontend && npm run dev
install:
	@rm -f .installed && $(MAKE) .installed

build:
	@cd contracts && forge build
test:
	@cd contracts && forge test -vvv
deploy-og:
	@cd contracts && forge script script/Deploy.s.sol --rpc-url $(OG_RPC) --broadcast -vvvv
deploy-local:
	@cd contracts && forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
ai-train:
	@cd ai && .venv/bin/python shared/model/train.py
up:
	@docker compose -f docker/docker-compose.yml up -d --build
down:
	@docker compose -f docker/docker-compose.yml down
clean:
	@rm -rf contracts/out contracts/cache ai/__pycache__ .installed
push:
	@git add . && git commit -m "Need to ship fast" && git push origin $(git branch --show-current)

.PHONY: dev install build test deploy-og deploy-local ai-train up down clean
