import { Signer } from "@aws-sdk/rds-signer";
import pg from 'pg';
import fs from 'fs';

// Populated by the Lambda's Terraform wiring (environment block), never hardcoded:
// DB_HOST = aurora_master cluster endpoint, DB_USER = master_username, DB_NAME = database_name.
const DB_HOST = process.env.DB_HOST;
const DB_USER = process.env.DB_USER;
const DB_NAME = process.env.DB_NAME || "postgres";
const DB_PORT = 5432;
const CA_BUNDLE = fs.readFileSync(new URL("./rds-ca-2019-root.pem", import.meta.url));

export const handler = async () => {
  const result = await dbOps();
  return {
    statusCode: 200,
    body: JSON.stringify(result.rows),
  };
};

async function createAuthToken() {
  const signer = new Signer({
    hostname: DB_HOST,
    port: DB_PORT,
    username: DB_USER,
    region: process.env.AWS_REGION,
  });

  return signer.getAuthToken();
}

async function dbOps() {
  const token = await createAuthToken();

  const client = new pg.Client({
    user: DB_USER,
    host: DB_HOST,
    database: DB_NAME,
    password: token,
    port: DB_PORT,
    ssl: {
      ca: CA_BUNDLE,
      rejectUnauthorized: true,
    },
  });

  await client.connect();
  try {
    return await client.query("SELECT * FROM pg_roles;");
  } finally {
    await client.end();
  }
}
