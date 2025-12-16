SHELL := /bin/bash

COMPOSE := docker compose -f docker-compose.yml

.PHONY: up down restart logs ps health

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

restart:
	$(COMPOSE) down && $(COMPOSE) up -d

logs:
	$(COMPOSE) logs -f --tail=200

ps:
	$(COMPOSE) ps

health:
	@echo "Ports:" && ss -tln | grep -E '(:8081|:8085)' || true
	@echo "Containers:" && $(COMPOSE) ps
	@echo "Disk:" && df -h | head -n 5
