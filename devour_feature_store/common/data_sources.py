from feast import FileSource, PushSource, RequestSource
# from feast.infra.offline_stores.contrib.spark_offline_store.spark_source import SparkSource
# from feast import ValueType

from feast.data_format import ParquetFormat

product_general_score_source = FileSource(
    name="product_general_score_source",
    path="data/product_features/product_general_scores.parquet",
    file_format=ParquetFormat(),
    timestamp_field="event_timestamp",
)

general_score_push_source = PushSource(
    name="general_score_push_source",
    batch_source=product_general_score_source
)

# cannot be named as push_source,otherwise will raise error
