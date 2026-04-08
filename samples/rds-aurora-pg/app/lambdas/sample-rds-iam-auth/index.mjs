import { Signer } from "@aws-sdk/rds-signer";
import pg from 'pg';
import fs from 'fs';
import path from 'path';

export const handler = async (event) => {
    const result = await dbOps();
    const response = {
      statusCode: 200,
      body: JSON.stringify('Hello from Lambda!'),
    };
    return response;
  };

async function createAuthToken() {
  // Define connection authentication parameters
  const dbinfo = {
    hostname: "lab-aws-samples-postgresql.cluster-c9mwk8cswsm7.eu-west-3.rds.amazonaws.com",
    port: 5432,
    username: "adminpg",
    region: process.env.AWS_REGION,
  }

  // Create RDS Signer object
  const signer = new Signer(dbinfo);

  // Request authorization token from RDS, specifying the username
  const token = await signer.getAuthToken();
  return token;
}

async function dbOps() {

  const token = await createAuthToken();
  console.log(token)
  // Define connection configuration
  const client = new pg.Client({
    user: "adminpg",
    host: "lab-aws-samples-postgresql.cluster-c9mwk8cswsm7.eu-west-3.rds.amazonaws.com",
    database: "postgres",
    password: token,
    port: 5432,
    ssl: 'no-verify'
  });

    await client.connect();
    var res = await client.query("SELECT * FROM pg_roles;");
    console.log(res);
    client.end();
  return res;

}
