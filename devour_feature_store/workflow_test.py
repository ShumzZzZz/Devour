from feast import FeatureStore
import pandas as pd
import numpy as np
from datetime import datetime
from feast.data_source import PushMode


def run_test(mode='online'):
	fs = FeatureStore()

	n = 1_000_000

	# Sequential product IDs from 900001 to 920000
	product_ids = np.arange(9_000_001, 9_000_001 + n)

	# Generate random general scores between 0 and 1
	general_scores = np.random.random(size=n)

	# Use today's timestamp for all events
	event_timestamp = datetime.now()

	# Build the DataFrame
	df = pd.DataFrame({
		'product_id': product_ids,
		'general_score': general_scores,
		'general_score_1': general_scores,
		'general_score_2': general_scores,
		'general_score_3': general_scores,
		'general_score_4': general_scores,
		'general_score_5': general_scores,
		'general_score_6': general_scores,
		'general_score_7': general_scores,
		'general_score_8': general_scores,
		'general_score_9': general_scores,
		'general_score_10': general_scores,
		'event_timestamp': [event_timestamp] * n
	})

	fs.push(
		push_source_name="ds_push_product_general_score",
		df=df,
		to=PushMode.ONLINE if mode == 'online' else PushMode.ONLINE_AND_OFFLINE
	)


if __name__ == "__main__":
	run_test()
