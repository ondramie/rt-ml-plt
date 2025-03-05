// src/main.rs
mod pipelines;

use reqwest::Client;
use arroyo::connectors::kafka::{KafkaConfig, KafkaSink, KafkaSource};
use  arroyo::prelude::*;
use crate::pipelines::fiat_offboard::{FiatPaymentMethod, FiatTransaction, FraudResponse  };
use tokio;

async fn call_snowflake_api(
    client: &Client,
    txn_amount: i64,
    entity_id: String,
    transaction_id: String,
) -> Result<FraudResponse, Box<dyn std::error::Error>> {
    let url = "http://localhost:4567/snowflake/api/fraud_check";
    let payload = serde_json::json!({
        "txn_amount": txn_amount,
        "entity_id": entity_id,
        "transaction_id": transaction_id
    });

    let response = client
        .post(url)
        .json(&payload)
        .send()
        .await?
        .json::<FraudResponse>()
        .await?;

    Ok(response)
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // HTTP client for Snowflake API
    let client = Client::new();

    // Kafka source: fiat_transactions
    let tx_config = KafkaConfig {
        bootstrap_servers: "localhost:9092".to_string(),
        topic: "fiat_transactions".to_string(),
        format: DataFormat::Json,
        ..Default::default()
    };
    let tx_source = KafkaSource::new(tx_config);

    // Kafka sink: high_risk_transactions
    let sink_config = KafkaConfig {
        bootstrap_servers: "localhost:9092".to_string(),
        topic: "high_risk_transactions".to_string(),
        format: DataFormat::Json,
        ..Default::default()
    };
    let sink = KafkaSink::new(sink_config);

    // Pipeline
    let mut pipeline = PipelineBuilder::new()
        .add_source(tx_source)
        .map_async(move |tx: FiatTransaction| {
            let client = client.clone(); // Clone for async closure
            async move {
                let fraud_response = call_snowflake_api(
                    &client,
                    tx.amount_cents,
                    tx.entity_id.clone(),
                    tx.id.clone(), // Pass transaction ID
                )
                .await?;

                Ok(Some(fraud_response))
            }
        })
        .filter(|fraud_response: &FraudResponse| fraud_response.fraud_score > 7)
        .add_sink(sink)
        .build();

    println!("Starting Arroyo fiat pipeline with Snowflake API...");
    pipeline.run().await?;
    Ok(())
}
