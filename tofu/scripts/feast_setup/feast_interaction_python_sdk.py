from feast import FeatureStore

fs = FeatureStore(fs_yaml_file='./feature_store_remote_client.yaml')

print(fs.registry.list_entities(project="credit_scoring_local"))

