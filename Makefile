.PHONY: nats init-nsc

local:
	nats-server -c local.conf

leaf:
	nats-server -c leaf.conf

init-nsc:
	./init-nsc.sh

init-leaf-nsc:
	./init-leaf-nsc.sh
