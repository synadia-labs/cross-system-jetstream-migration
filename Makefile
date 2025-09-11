.PHONY: nats init-nsc

local:
	nats-server -c local.conf

leaf:
	nats-server -c leaf.conf

init-nsc:
	./init-nsc.sh

init-leaf-nsc:
	./init-leaf-nsc.sh

clean:
	@echo 'reset leaf node config'
	@sed -E -i '' 's/account: "[A-Z0-9]+"/account: A\.\.\./g' leaf.conf
	
	@echo 'reset cloud.tf'
	@sed -E -i '' 's/subjects/# subjects/g' ./tf/cloud/cloud.tf
	
	@echo 'remove nsc directories'
	@rm -rf .nsc .leaf
