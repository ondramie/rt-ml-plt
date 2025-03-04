#!/bin/bash

echo "Testing Arroyo fraud pipeline..."
echo "--------------------------------"

# Submit the pipeline to Arroyo
echo "Submitting pipeline to Arroyo..."
PIPELINE_SQL=$(cat src/arroyo/fraud_pipeline.sql)
curl -X POST http://localhost:5115/api/v1/pipelines \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg query "$PIPELINE_SQL" '{"name":"fraud-detection","query":$query,"parallelism":1}')" \
  --silent

# Wait for pipeline to be created
echo "Waiting for pipeline to initialize..."
sleep 5

# Create topics if they don't exist
echo "Ensuring Kafka topics exist..."
docker exec kafka /opt/kafka/bin/kafka-topics.sh --create --topic transactions_raw --bootstrap-server kafka:9092 --partitions 3 --replication-factor 1 --if-not-exists
docker exec kafka /opt/kafka/bin/kafka-topics.sh --create --topic transaction_scores --bootstrap-server kafka:9092 --partitions 3 --replication-factor 1 --if-not-exists

# Start consumer in background to capture results
echo "Starting consumer for transaction_scores topic..."
docker exec kafka /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic transaction_scores --from-beginning > results.txt &
CONSUMER_PID=$!

# Wait for consumer to initialize
sleep 2

# Send test transactions
echo "Sending test transactions..."
echo '{"id":"tx001","amount":12000,"ip":"foreign"}' | docker exec -i kafka /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server kafka:9092 --topic transactions_raw
echo '{"id":"tx002","amount":5500,"ip":"local"}' | docker exec -i kafka /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server kafka:9092 --topic transactions_raw
echo '{"id":"tx003","amount":1200,"ip":"foreign"}' | docker exec -i kafka /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server kafka:9092 --topic transactions_raw
echo '{"id":"tx004","amount":15000,"ip":"foreign"}' | docker exec -i kafka /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server kafka:9092 --topic transactions_raw

# Wait for processing
echo "Waiting for Arroyo to process transactions..."
sleep 10

# Check topic messages
echo "Checking topic messages..."
echo "transactions_raw topic:"
docker exec kafka /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic transactions_raw --from-beginning --max-messages 4 --timeout-ms 5000
echo "transaction_scores topic:"
docker exec kafka /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic transaction_scores --from-beginning --max-messages 4 --timeout-ms 5000

# Kill consumer and show results
kill $CONSUMER_PID
echo "--------------------------------"
echo "Results:"
cat results.txt
echo "--------------------------------"
echo "Test complete!"
