use reqwest::Client;
use std::time::Duration;
use crate::{
    error::{AppError, Result},
    models::{
        ChatCompletionRequest, ChatCompletionResponse, TokenUsage,
        OpenAIChatRequest, OpenAIChatResponse, OpenAIMessage, OpenAIConfig
    },
};
use chrono::Utc;
use uuid::Uuid;

pub struct OpenAIService {
    client: Client,
    config: OpenAIConfig,
}

impl OpenAIService {
    pub fn new(config: OpenAIConfig) -> Result<Self> {
        let client = Client::builder()
            .timeout(Duration::from_secs(config.timeout_seconds))
            .build()
            .map_err(|e| AppError::HttpClientError(format!("Failed to create HTTP client: {}", e)))?;

        Ok(Self { client, config })
    }

    pub async fn chat_completion(&self, request: ChatCompletionRequest) -> Result<ChatCompletionResponse> {
        let model = request.model.as_deref().unwrap_or(&self.config.default_model);
        
        // Prepare messages for OpenAI API
        let mut messages = Vec::new();
        
        // Add system prompt if provided
        if let Some(system_prompt) = &request.system_prompt {
            messages.push(OpenAIMessage {
                role: "system".to_string(),
                content: system_prompt.clone(),
            });
        }
        
        // Add user message
        messages.push(OpenAIMessage {
            role: "user".to_string(),
            content: request.content.clone(),
        });

        let openai_request = OpenAIChatRequest {
            model: model.to_string(),
            messages,
            temperature: request.temperature,
            max_tokens: request.max_tokens,
        };

        let base_url = self.config.base_url.as_deref().unwrap_or("https://api.openai.com");
        let url = format!("{}/v1/chat/completions", base_url);

        tracing::info!("Sending request to OpenAI API: {}", url);

        let response = self
            .client
            .post(&url)
            .header("Authorization", format!("Bearer {}", self.config.api_key))
            .header("Content-Type", "application/json")
            .json(&openai_request)
            .send()
            .await
            .map_err(|e| AppError::OpenAIError(format!("Request failed: {}", e)))?;

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            return Err(AppError::OpenAIError(format!(
                "API request failed with status {}: {}",
                status, error_text
            )));
        }

        let openai_response: OpenAIChatResponse = response
            .json()
            .await
            .map_err(|e| AppError::OpenAIError(format!("Failed to parse response: {}", e)))?;

        // Extract the content from the first choice
        let content = openai_response
            .choices
            .first()
            .map(|choice| choice.message.content.clone())
            .unwrap_or_else(|| "No response generated".to_string());

        let response = ChatCompletionResponse {
            id: Uuid::new_v4(),
            content,
            model: openai_response.model,
            usage: TokenUsage {
                prompt_tokens: openai_response.usage.prompt_tokens,
                completion_tokens: openai_response.usage.completion_tokens,
                total_tokens: openai_response.usage.total_tokens,
            },
            timestamp: Utc::now().to_rfc3339(),
        };

        tracing::info!(
            "OpenAI API response received. Tokens used: {}",
            response.usage.total_tokens
        );

        Ok(response)
    }

    pub async fn summarize_text(&self, content: &str, max_length: usize) -> Result<String> {
        let system_prompt = format!(
            "You are a helpful assistant that summarizes text. Please provide a concise summary of the given text in approximately {} characters or less. Focus on the main points and key information.",
            max_length
        );

        let request = ChatCompletionRequest {
            content: content.to_string(),
            model: Some(self.config.default_model.clone()),
            temperature: Some(0.3), // Lower temperature for more consistent summaries
            max_tokens: Some((max_length / 3) as u32), // Rough estimate: 1 token ≈ 3 characters
            system_prompt: Some(system_prompt),
        };

        let response = self.chat_completion(request).await?;
        Ok(response.content)
    }

    pub async fn analyze_scan_data(&self, data: &str, format: &str) -> Result<String> {
        let system_prompt = format!(
            "You are an expert at analyzing {} data. Please analyze the provided data and provide insights, extract key information, and identify any patterns or important details.",
            format
        );

        let user_prompt = format!("Please analyze this {} data: {}", format, data);

        let request = ChatCompletionRequest {
            content: user_prompt,
            model: Some(self.config.default_model.clone()),
            temperature: Some(0.5),
            max_tokens: Some(1000),
            system_prompt: Some(system_prompt),
        };

        let response = self.chat_completion(request).await?;
        Ok(response.content)
    }
} 