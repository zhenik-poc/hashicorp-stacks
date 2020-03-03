# Kafka + envoy proxy
## Verification 
List topics
```bash
docker run --tty \
           --network host \
           confluentinc/cp-kafkacat \
           kafkacat -b localhost:11111 \
                    -L
```

