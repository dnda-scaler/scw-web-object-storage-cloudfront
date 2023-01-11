all: .init deploy
.init:
	- echo "Get Cloudfront Server IPs"
	- wget https://d7uri8nf7uskq.cloudfront.net/tools/list-cloudfront-ips -O list-cloudfront-ips.json
	- $(eval CLOUDFRONT_GLOBAL_IP_LIST=$(shell cat list-cloudfront-ips.json | jq -r '.CLOUDFRONT_GLOBAL_IP_LIST'))
	- $(eval CLOUDFRONT_REGIONAL_EDGE_IP_LIST=$(shell cat list-cloudfront-ips.json | jq -r '.CLOUDFRONT_REGIONAL_EDGE_IP_LIST'))
	- cp infrastructure/terraform.tfvars.json.template infrastructure/terraform.tfvars.json
	- jq '.cloudfront_global_ips = ${CLOUDFRONT_GLOBAL_IP_LIST}' infrastructure/terraform.tfvars.json > infrastructure/terraform.tfvars.json.tmp && mv infrastructure/terraform.tfvars.json.tmp infrastructure/terraform.tfvars.json
	- jq '.cloudfront_regional_ips = ${CLOUDFRONT_REGIONAL_EDGE_IP_LIST}' infrastructure/terraform.tfvars.json > infrastructure/terraform.tfvars.json.tmp && mv infrastructure/terraform.tfvars.json.tmp infrastructure/terraform.tfvars.json
	- npm i --prefix my-web-app
	- npm run build --prefix my-web-app
	- terraform -chdir=infrastructure init
deploy:
	- terraform -chdir=infrastructure validate
	- terraform -chdir=infrastructure apply -auto-approve
clean-up:
	- terraform -chdir=infrastructure destroy -auto-approve
	