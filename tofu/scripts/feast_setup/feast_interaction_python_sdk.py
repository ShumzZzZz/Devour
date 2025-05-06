from feast import FeatureStore

fs = FeatureStore(fs_yaml_file='./feature_store_remote_client.yaml')

# for p in fs.registry.list_projects():
# 	print(p)

res = fs.get_online_features(
	features=[
		"zipcode_features:state",
		"zipcode_features:population", ],
	entity_rows=[
		{"zipcode": 7675},
	],

).to_dict()

print(res)
