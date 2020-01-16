# MinIO + Kafka

`NB!` Pay attention that Zookeeper, Kafka and Schema registry are `Confluent distribution`
## Install mc (minio client)
```bash
wget https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
./mc --help
```
Check config of thee client `cat ~/.mc/config.json `
```json
{
	"version": "9",
	"hosts": {
		"gcs": {
			"url": "https://storage.googleapis.com",
			"accessKey": "YOUR-ACCESS-KEY-HERE",
			"secretKey": "YOUR-SECRET-KEY-HERE",
			"api": "S3v2",
			"lookup": "dns"
		},
		"local": {
			"url": "http://localhost:9000",
			"accessKey": "",
			"secretKey": "",
			"api": "S3v4",
			"lookup": "auto"
		},
		"play": {
			"url": "https://play.min.io",
			"accessKey": "Q3AM3UQ867SPQQA43P2F",
			"secretKey": "zuf+tfteSlswRu7BJ86wekitnifILbZam1KYY3TG",
			"api": "S3v4",
			"lookup": "auto"
		},
		"s3": {
			"url": "https://s3.amazonaws.com",
			"accessKey": "YOUR-ACCESS-KEY-HERE",
			"secretKey": "YOUR-SECRET-KEY-HERE",
			"api": "S3v4",
			"lookup": "dns"
		}
	}
}
```

Update part of local deployment:
```json
...
"local": {
    "url": "http://localhost:9000",
    "accessKey": "minio",
    "secretKey": "minio123",
    "api": "S3v4",
    "lookup": "auto"
},
...
```

## Kafka
Create a topic
```bash 
docker-compose exec kafka kafka-topics --create --if-not-exists --zookeeper zookeeper:2181 --partitions 10 --replication-factor 1 --topic minio-events-v1 
```
List topics
```bash
docker-compose exec kafka kafka-topics --list --zookeeper zookeeper:2181
```
## Confluent Kafkacat
List kafka topics
```bash
docker run --tty \
           --network kafka-minio_default \
           confluentinc/cp-kafkacat \
           kafkacat -b kafka:9092 \
                    -L
``` 

Consuming messages from a topic
```bash
docker run --tty \
           --network kafka-minio_default \
           confluentinc/cp-kafkacat \
           kafkacat -b kafka:9092 -C -K: \
                    -f '\nKey (%K bytes): %k\t\nValue (%S bytes): %s\n\Partition: %p\tOffset: %o\n--\n' \
                    -t minio-events-v1
```

## Useful minio CMDs
```bash 
# get config
mc admin config get local notify_kafka

# set new config
mc admin config set local notify_kafka:1 tls_skip_verify="off"  queue_dir="" queue_limit="0" sasl="off" sasl_password="" sasl_username="" tls_client_auth="0" tls="off" client_tls_cert="" client_tls_key="" brokers="kafka:9092" topic="minio-events-v1"

# restart server
mc admin service restart local
```

Other
```bash
# create bucket
mc mb local/images

# triger rule on specific event
mc event add local/images arn:minio:sqs::1:kafka --suffix .jpg

# list triggers
mc event list local/images
arn:minio:sqs::1:kafka s3:ObjectCreated:*,s3:ObjectRemoved:* Filter: suffix=”.jpg”
```

