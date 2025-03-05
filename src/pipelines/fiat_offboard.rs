// src/pipelines/fiat_offboard.rs

use serde::{Deserialize, Serialize};
use serde_json;

#[derive(Debug, Deserialize, Serialize)]
pub struct FiatPaymentMethod {
    pub id: String,
    pub data: serde_json::Value,
    pub provider: String,
    pub status: String,
    pub token: String,
    #[serde(rename = "type")]
    pub type_: String,
    pub created_at: String,
    pub updated_at: String,
    pub entity_id: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct FiatTransaction {
    pub id: String,
    pub amount_cents: i64,
    pub blockchain: String,
    pub crypto_asset: String,
    pub metadata: Option<serde_json::Value>,
    pub payment_currency: String,
    pub provider: String,
    pub status: String,
    #[serde(rename = "type")]
    pub type_: String,
    pub created_at: String,
    pub updated_at: String,
    pub entity_id: String,
    pub fiat_payment_method_id: Option<String>,
    pub payment_id: Option<String>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct FraudResponse {
    pub fraud_score: i32,            // 0-10 risk rating
    pub risk_category: String,       // "low|medium|high"
    pub key_indicators: Vec<String>, // ["list", "of", "top", "3", "factors"]
    pub rationale: String,           // "concise technical explanation"
    pub entity_id: String,
    pub transaction_id: String,
    pub cs_response: Option<String>, // Assuming string for simplicity
}
