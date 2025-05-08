#!/bin/zsh

curl "http://localhost:8002/get-online-features" \
	--json '{
		"features": ["product_general_score:general_score", "product_general_score:event_timestamp"],
		"entities": {"product_id": [0]}
	}' \
	| jq

#	--json '{
#		"features": ["zipcode_features:state", "zipcode_features:population"],
#		"entities": {"zipcode": [7675, 94538]}
#	}' \