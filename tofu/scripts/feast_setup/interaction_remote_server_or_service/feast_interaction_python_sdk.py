import datetime

from feast import FeatureStore, Project


fs = FeatureStore(repo_path='/infra_staging')
# only works if registry db is exposed directly as above
# for remote registry like the following, get metadata is fine, but actual calling to get_online_features failed
# w/ weird error saying feature view xxx not found in project
# fs = FeatureStore(repo_path='/Users/shuminzheng/PycharmProjects/devour/devour_feature_store')


p = Project(name="devour", tags={"owner": "shumin"})

fs.apply(objects=[p])

for p in fs.registry.list_projects():
	print(p)

# fs.apply(objects=fs.list_feature_views())

for fv in fs.list_feature_views():
	print(fv)

# fs.materialize(
# 	feature_views=["product_general_score_fresh"],
# 	start_date=datetime.datetime(2022, 1, 1),
# 	end_date=datetime.datetime.now()
# )

res = fs.get_online_features(
	features=[
		"product_general_score:general_score"],
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
