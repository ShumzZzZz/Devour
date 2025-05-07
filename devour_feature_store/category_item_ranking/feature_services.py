from feast import FeatureService
from common.features import *

category_ranking_generic_feature_service = FeatureService(
	name="category_ranking_generic_feature_service",
	features=[
		product_general_score_fv[["product_id", "general_score"]],
	],
	owner="shumin.zheng"
)