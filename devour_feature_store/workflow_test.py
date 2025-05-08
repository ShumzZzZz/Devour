from feast import FeatureStore
import pandas as pd
from feast.data_source import PushMode

fs = FeatureStore()

data = {
	"product_id": [-9999],
	"general_score": [0.009009009],
	"event_timestamp": ["2025-05-08 14:24:00.000000"]
}
feature_df = pd.DataFrame(data)

feature_df["event_timestamp"] = pd.to_datetime(feature_df["event_timestamp"])

fs.push(
	push_source_name="push_source",
	df=feature_df,
	to=PushMode.ONLINE
)
