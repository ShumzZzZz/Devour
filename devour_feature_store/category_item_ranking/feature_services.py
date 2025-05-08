from feast import FeatureService
from common.features import *

category_fs_v1 = FeatureService(
	name="category_ranking_generic_feature_service",
	features=[
		product_general_score_fv[["general_score"]],
	],
	owner="shumin.zheng"
)

category_fs_v2 = FeatureService(
	name="category_ranking_generic_feature_service_fresh",
	features=[
		product_general_score_fresh_fv[["general_score"]],
	],
	owner="shumin.zheng"
)