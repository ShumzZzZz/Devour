from feast import FeatureStore

fs = FeatureStore(fs_yaml_file='./feature_store_remote_client.yaml')

# for p in fs.registry.list_projects():
# 	print(p)
#
# for fv in fs.list_feature_views():
# 	print(fv)

res = fs.get_online_features(
	features=[
		"product_general_score:general_score",
		"product_general_score:event_timestamp", ],
	entity_rows=[
		{"product_id": 1005},
	],

).to_dict()

print(res)
