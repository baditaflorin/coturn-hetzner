.PHONY: up down logs test certs

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f

# Quick connectivity test — prints "TURN OK" if the server responds
test:
	@docker compose exec coturn \
		turnutils_uclient -t -u $${TURN_USER} -w $${TURN_PASS} -p 3478 $${SERVER_IP} \
		&& echo "TURN OK" || echo "TURN FAILED — check logs with: make logs"

# Get a free TLS cert via certbot (needs port 80 free and a domain)
certs:
	docker run --rm -it \
		-p 80:80 \
		-v $$(pwd)/certs:/etc/letsencrypt \
		certbot/certbot certonly --standalone \
		-d $${TURN_DOMAIN} \
		--agree-tos --no-eff-email -m admin@$${TURN_DOMAIN}
	@echo "Certs written to ./certs/ — restart with: make down && make up"
