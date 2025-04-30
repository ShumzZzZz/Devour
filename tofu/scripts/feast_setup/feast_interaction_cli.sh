#!/bin/zsh

curl "http://localhost:8002/get-online-features" \
	--json '{
		"features": ["zipcode_features:state", "zipcode_features:population"],
		"entities": {"zipcode": [7675, 94538]}
	}' \
	| jq