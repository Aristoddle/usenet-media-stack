SHELL := /bin/bash

COMPOSE_FILES := docker-compose.yml docker-compose.override.yml docker-compose.traefik.yml docker-compose.vpn-mullvad.yml
COMPOSE := docker compose $(foreach f,$(COMPOSE_FILES),-f $(f))

.PHONY: up down restart logs ps health docs-build

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
	npm test --silent

docs-build:
	npm --prefix docs install
	npm --prefix docs run docs:build
