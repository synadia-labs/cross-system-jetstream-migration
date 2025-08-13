NSC_DIR := ./.nsc

nats:
	nats-server -c nats.conf

init-nsc:
	rm -rf $(NSC_DIR)
	nsc --all-dirs $(NSC_DIR) add operator --name memory --generate-signing-key --sys
	nsc --all-dirs $(NSC_DIR) add account --name A
	nsc --all-dirs $(NSC_DIR) edit account --name A --js-enable 1
	nsc --all-dirs $(NSC_DIR) edit account --name A --js-enable 3
	nsc --all-dirs $(NSC_DIR) add user --name admin
	nsc --all-dirs $(NSC_DIR) add user --name orders --allow-sub 'QUEUE.ORDERS.> ORDERS' --allow-pub 'QUEUE.SHIPMENTS.>'
	nsc --all-dirs $(NSC_DIR) add user --name shipments --allow-sub 'QUEUE.SHIPMENTS.> SHIPMENTS'
	nsc --all-dirs $(NSC_DIR) generate config --mem-resolver --config-file $(NSC_DIR)/nsc.conf
