NSC_DIR := ./.nsc

nats:
	nats-server -c nats.conf -D

init-nsc:
	rm -rf $(NSC_DIR)
	nsc --all-dirs $(NSC_DIR) add operator --name memory --generate-signing-key --sys
	nsc --all-dirs $(NSC_DIR) add account --name A
	nsc --all-dirs $(NSC_DIR) edit account --name A --js-enable 1
	nsc --all-dirs $(NSC_DIR) edit account --name A --js-enable 3
	nsc --all-dirs $(NSC_DIR) add user --name admin
	nsc --all-dirs $(NSC_DIR) add user --name orders --allow-sub 'QUEUE.ORDERS.> ORDERS' --allow-pub 'QUEUE.SHIPMENTS.>'
	nsc --all-dirs $(NSC_DIR) add user --name shipments --allow-sub 'QUEUE.SHIPMENTS.> SHIPMENTS'
	nsc --all-dirs $(NSC_DIR) generate config --nats-resolver --config-file $(NSC_DIR)/nsc.conf

import-synctl:
	# SCP_SERVER=... SCP_TOKEN=... make import-synctl
	NSC_HOME=$(NSC_DIR) NKEYS_PATH=$(NSC_DIR) synctl system import --all --users

import-nsc:
	@printf '\n===Operator JWT===\n'
	@nsc --all-dirs $(NSC_DIR) describe operator --raw

	@printf '\n===SYS JWT===\n'
	@nsc --all-dirs $(NSC_DIR) describe account --name SYS --raw

	@printf '\n===Signing Keys===\n'
	@nsc --all-dirs $(NSC_DIR) list keys --account SYS --show-seeds

private-link:
	# SPL_PLATFORM_URL=... SPL_TOKEN=... make private-link
	# https://github.com/synadia-io/private-link/releases/
	./synadia-private-link --nats-url="nats://localhost:4222"
