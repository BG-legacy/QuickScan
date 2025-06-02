// I am importing the necessary libraries for file paths, time, serialization, async file I/O, UUIDs, and error handling
use std::path::PathBuf;
use chrono::Utc;
use serde::{Deserialize, Serialize};
use tokio::fs;
use uuid::Uuid;
use anyhow::{Context, Result};

// I am defining the structure for a stored file, including metadata and storage details
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StoredFile {
    pub id: Uuid,
    pub filename: String,
    pub file_size: u64,
    pub content_type: Option<String>,
    pub storage_path: String,
    pub storage_type: StorageType,
    pub timestamp: String,
    pub download_url: Option<String>,
}

// I am defining the types of storage supported by my backend
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum StorageType {
    Temporary,
    Supabase,
}

// I am defining the configuration for the storage service, including environment-based options
#[derive(Debug, Clone)]
pub struct StorageConfig {
    pub storage_type: StorageType,
    pub temp_dir: Option<PathBuf>,
    pub supabase_url: Option<String>,
    pub supabase_key: Option<String>,
    pub supabase_bucket: Option<String>,
}

impl Default for StorageConfig {
    // I am providing default configuration, reading from environment variables if available
    fn default() -> Self {
        let storage_type = match std::env::var("STORAGE_TYPE").as_deref() {
            Ok("supabase") => StorageType::Supabase,
            _ => StorageType::Temporary,
        };

        Self {
            storage_type,
            temp_dir: Some(std::env::temp_dir().join("quickscan_uploads")),
            supabase_url: std::env::var("SUPABASE_URL").ok(),
            supabase_key: std::env::var("SUPABASE_ANON_KEY").ok(),
            supabase_bucket: std::env::var("SUPABASE_BUCKET").unwrap_or_else(|_| "uploads".to_string()).into(),
        }
    }
}

// I am defining the main storage service, which handles file operations for both local and Supabase storage
pub struct StorageService {
    config: StorageConfig,
    http_client: reqwest::Client,
}

impl StorageService {
    // I am creating a new storage service with the given configuration
    pub fn new(config: StorageConfig) -> Result<Self> {
        let http_client = reqwest::Client::new();

        Ok(Self {
            config,
            http_client,
        })
    }

    // I am storing a file, delegating to the appropriate backend (temporary or Supabase)
    pub async fn store_file(
        &self,
        filename: &str,
        content_type: Option<String>,
        data: &[u8],
    ) -> Result<StoredFile> {
        let file_id = Uuid::new_v4();
        let file_size = data.len() as u64;
        let timestamp = Utc::now().to_rfc3339();

        match self.config.storage_type {
            StorageType::Temporary => {
                self.store_temporary_file(file_id, filename, content_type, data, file_size, timestamp).await
            }
            StorageType::Supabase => {
                self.store_supabase_file(file_id, filename, content_type, data, file_size, timestamp).await
            }
        }
    }

    async fn store_temporary_file(
        &self,
        file_id: Uuid,
        filename: &str,
        content_type: Option<String>,
        data: &[u8],
        file_size: u64,
        timestamp: String,
    ) -> Result<StoredFile> {
        let temp_dir = self.config.temp_dir.as_ref()
            .context("Temporary directory not configured")?;

        // Ensure the temp directory exists
        fs::create_dir_all(temp_dir).await
            .context("Failed to create temporary directory")?;

        // Generate a safe filename
        let safe_filename = format!("{}_{}", file_id, sanitize_filename(filename));
        let file_path = temp_dir.join(&safe_filename);

        // Write the file
        fs::write(&file_path, data).await
            .context("Failed to write file to temporary storage")?;

        Ok(StoredFile {
            id: file_id,
            filename: filename.to_string(),
            file_size,
            content_type,
            storage_path: file_path.to_string_lossy().to_string(),
            storage_type: StorageType::Temporary,
            timestamp,
            download_url: None,
        })
    }

    async fn store_supabase_file(
        &self,
        file_id: Uuid,
        filename: &str,
        content_type: Option<String>,
        data: &[u8],
        file_size: u64,
        timestamp: String,
    ) -> Result<StoredFile> {
        let supabase_url = self.config.supabase_url.as_ref()
            .context("Supabase URL not configured")?;
        let supabase_key = self.config.supabase_key.as_ref()
            .context("Supabase key not configured")?;
        let bucket = self.config.supabase_bucket.as_ref()
            .context("Supabase bucket not configured")?;

        // Generate a unique file path
        let storage_path = format!("{}/{}", file_id, sanitize_filename(filename));

        // Upload to Supabase Storage
        let upload_url = format!("{}/storage/v1/object/{}/{}", supabase_url, bucket, storage_path);
        
        let mut request = self.http_client
            .post(&upload_url)
            .header("Authorization", format!("Bearer {}", supabase_key))
            .body(data.to_vec());

        if let Some(content_type) = &content_type {
            request = request.header("Content-Type", content_type);
        }

        let response = request.send().await
            .context("Failed to upload file to Supabase")?;

        if !response.status().is_success() {
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            return Err(anyhow::anyhow!("Supabase upload failed: {}", error_text));
        }

        // Generate a public URL for the uploaded file
        let download_url = format!("{}/storage/v1/object/public/{}/{}", supabase_url, bucket, storage_path);

        Ok(StoredFile {
            id: file_id,
            filename: filename.to_string(),
            file_size,
            content_type,
            storage_path,
            storage_type: StorageType::Supabase,
            timestamp,
            download_url: Some(download_url),
        })
    }

    pub async fn get_file(&self, stored_file: &StoredFile) -> Result<Vec<u8>> {
        match stored_file.storage_type {
            StorageType::Temporary => {
                fs::read(&stored_file.storage_path).await
                    .context("Failed to read file from temporary storage")
            }
            StorageType::Supabase => {
                if let Some(download_url) = &stored_file.download_url {
                    let response = self.http_client
                        .get(download_url)
                        .send()
                        .await
                        .context("Failed to download file from Supabase")?;

                    if !response.status().is_success() {
                        return Err(anyhow::anyhow!("Failed to download file: HTTP {}", response.status()));
                    }

                    let bytes = response.bytes().await
                        .context("Failed to read file bytes from Supabase")?;
                    
                    Ok(bytes.to_vec())
                } else {
                    Err(anyhow::anyhow!("No download URL available for Supabase file"))
                }
            }
        }
    }

    pub async fn delete_file(&self, stored_file: &StoredFile) -> Result<()> {
        match stored_file.storage_type {
            StorageType::Temporary => {
                fs::remove_file(&stored_file.storage_path).await
                    .context("Failed to delete file from temporary storage")
            }
            StorageType::Supabase => {
                let supabase_url = self.config.supabase_url.as_ref()
                    .context("Supabase URL not configured")?;
                let supabase_key = self.config.supabase_key.as_ref()
                    .context("Supabase key not configured")?;
                let bucket = self.config.supabase_bucket.as_ref()
                    .context("Supabase bucket not configured")?;

                let delete_url = format!("{}/storage/v1/object/{}/{}", supabase_url, bucket, stored_file.storage_path);
                
                let response = self.http_client
                    .delete(&delete_url)
                    .header("Authorization", format!("Bearer {}", supabase_key))
                    .send()
                    .await
                    .context("Failed to delete file from Supabase")?;

                if !response.status().is_success() {
                    let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
                    return Err(anyhow::anyhow!("Supabase delete failed: {}", error_text));
                }

                Ok(())
            }
        }
    }

    pub async fn get_download_url(&self, stored_file: &StoredFile, expires_in: u64) -> Result<String> {
        match stored_file.storage_type {
            StorageType::Temporary => {
                // For temporary files, return the file path for internal API download
                Ok(format!("/api/files/{}/download", stored_file.id))
            }
            StorageType::Supabase => {
                let supabase_url = self.config.supabase_url.as_ref()
                    .context("Supabase URL not configured")?;
                let supabase_key = self.config.supabase_key.as_ref()
                    .context("Supabase key not configured")?;
                let bucket = self.config.supabase_bucket.as_ref()
                    .context("Supabase bucket not configured")?;

                // Create a signed URL for private buckets
                let signed_url_endpoint = format!(
                    "{}/storage/v1/object/sign/{}/{}?expiresIn={}",
                    supabase_url, bucket, stored_file.storage_path, expires_in
                );

                let response = self.http_client
                    .post(&signed_url_endpoint)
                    .header("Authorization", format!("Bearer {}", supabase_key))
                    .send()
                    .await
                    .context("Failed to create signed URL")?;

                if !response.status().is_success() {
                    // If signed URL creation fails, return the public URL
                    return Ok(stored_file.download_url.clone()
                        .unwrap_or_else(|| format!("{}/storage/v1/object/public/{}/{}", 
                            supabase_url, bucket, stored_file.storage_path)));
                }

                #[derive(Deserialize)]
                struct SignedUrlResponse {
                    #[serde(rename = "signedURL")]
                    signed_url: String,
                }

                let signed_response: SignedUrlResponse = response.json().await
                    .context("Failed to parse signed URL response")?;

                Ok(format!("{}{}", supabase_url, signed_response.signed_url))
            }
        }
    }

    pub async fn cleanup_expired_temp_files(&self, max_age_hours: u64) -> Result<u64> {
        if !matches!(self.config.storage_type, StorageType::Temporary) {
            return Ok(0);
        }

        let temp_dir = self.config.temp_dir.as_ref()
            .context("Temporary directory not configured")?;

        let mut deleted_count = 0;
        let cutoff_time = Utc::now() - chrono::Duration::hours(max_age_hours as i64);

        let mut entries = fs::read_dir(temp_dir).await
            .context("Failed to read temporary directory")?;

        while let Some(entry) = entries.next_entry().await? {
            let metadata = entry.metadata().await?;
            if let Ok(modified) = metadata.modified() {
                let modified_time = chrono::DateTime::<Utc>::from(modified);
                if modified_time < cutoff_time {
                    if fs::remove_file(entry.path()).await.is_ok() {
                        deleted_count += 1;
                    }
                }
            }
        }

        Ok(deleted_count)
    }
}

// Helper function to sanitize filenames
fn sanitize_filename(filename: &str) -> String {
    filename
        .chars()
        .map(|c| {
            if c.is_alphanumeric() || c == '.' || c == '-' || c == '_' {
                c
            } else {
                '_'
            }
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sanitize_filename() {
        assert_eq!(sanitize_filename("test file.txt"), "test_file.txt");
        assert_eq!(sanitize_filename("../../../etc/passwd"), "______etc_passwd");
        assert_eq!(sanitize_filename("normal-file_name.jpg"), "normal-file_name.jpg");
    }
} 