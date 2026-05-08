import { BlobServiceClient } from '@azure/storage-blob';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const uploadsDir = path.join(__dirname, '../../public/uploads');
const allowedMimeToExt = {
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/gif': '.gif',
  'image/webp': '.webp'
};

function getFileExtension(file) {
  const fromName = path.extname(file.originalname || '').toLowerCase();
  if (fromName) return fromName;
  return allowedMimeToExt[file.mimetype] || '.bin';
}

function getUniqueName(ext) {
  return `${Date.now()}-${Math.random().toString(36).slice(2, 11)}${ext}`;
}

function getAzureContainerName() {
  return process.env.AZURE_STORAGE_CONTAINER_NAME || 'photos';
}

function getAzureBlobClient() {
  const conn = process.env.STORAGE_CONNECTION_STRING;
  if (!conn) return null;

  const blobServiceClient = BlobServiceClient.fromConnectionString(conn);
  return blobServiceClient.getContainerClient(getAzureContainerName());
}

async function uploadToAzure(file) {
  const container = getAzureBlobClient();
  if (!container) return null;

  const ext = getFileExtension(file);
  const blobName = getUniqueName(ext);

  await container.createIfNotExists({ access: 'blob' });

  const blockBlobClient = container.getBlockBlobClient(blobName);
  await blockBlobClient.uploadData(file.buffer, {
    blobHTTPHeaders: { blobContentType: file.mimetype }
  });

  return blockBlobClient.url;
}

async function uploadToLocal(file) {
  await fs.mkdir(uploadsDir, { recursive: true });

  const ext = getFileExtension(file);
  const fileName = getUniqueName(ext);
  const filePath = path.join(uploadsDir, fileName);

  await fs.writeFile(filePath, file.buffer);
  return `/uploads/${fileName}`;
}

export async function uploadImage(file) {
  if (!file || !file.buffer) {
    throw new Error('Invalid upload payload');
  }

  const azureUrl = await uploadToAzure(file);
  if (azureUrl) return azureUrl;

  // Fallback keeps local development and tests working without Azure credentials.
  return uploadToLocal(file);
}
