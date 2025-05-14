from feast import FeatureStore

fs = FeatureStore(repo_path='/Users/shuminzheng/PycharmProjects/devour/devour_feature_store/infra_staging')
# only works if registry db is exposed directly as above
# for remote registry like the following, get metadata is fine, but actual calling to get_online_features failed
# w/ weird error saying feature view xxx not found in project
# fs = FeatureStore(repo_path='/Users/shuminzheng/PycharmProjects/devour/devour_feature_store')



for p in fs.registry.list_projects():
	print(p)

# fs.apply(objects=fs.list_feature_views())

for fv in fs.list_feature_views():
	print(fv)

res = fs.get_online_features(
	features=[
		"product_general_score_fresh:general_score"],
	entity_rows=[
		{"product_id": 1001},
		{"product_id": 9}
	],

).to_dict()

# res = fs.get_online_features(
# 	features=[
# 		"zipcode_features:state",
# 		"zipcode_features:population", ],
# 	entity_rows=[
# 		{"zipcode": 94538},
# 	],
#
# ).to_dict()


print(res)
