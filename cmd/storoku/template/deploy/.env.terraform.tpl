# copy to .env.terraform and set missing vars
TF_WORKSPACE= # your name here
TF_VAR_network= # optional, if the deployments targets a network different from the default specify it here
TF_VAR_app={{ .App }}{{if .DomainBase}}
TF_VAR_domain_base={{.DomainBase}}{{end}}
TF_VAR_did= # did for your env
TF_VAR_private_key= # private_key or your env -- do not commit to repo!
TF_VAR_allowed_account_id=505595374361
TF_VAR_region=us-west-2{{if .Cloudflare}}
TF_VAR_cloudflare_zone_id=37783d6f032b78cd97ce37ab6fd42848
CLOUDFLARE_API_TOKEN= # enter a cloudflare api token{{end}}{{range .Secrets}}{{if .Variable}}
TF_VAR_{{.Lower}}= # enter a value for {{.Upper}} secret{{end}}{{end}}