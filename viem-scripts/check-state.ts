import { AlchemyProvider } from "ethers";
import { config as envConfig } from "dotenv";
import path from "path";

envConfig({ path: path.resolve(__dirname, "../.env") });

const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY;
const ALICE = process.env.ALICE;

async function main() {
  if (!ALICE || !ALCHEMY_API_KEY) {
    throw new Error("ALICE or ALCHEMY_API_KEY is not set");
  }

  const provider = new AlchemyProvider("sepolia", ALCHEMY_API_KEY);
  const alice_code = await provider.getCode(ALICE);
  const alice_storage = await provider.getStorage(ALICE, 0);
  console.log(`ALICE code: ${alice_code}`);
  console.log(`ALICE storage: ${alice_storage}`);
}

main();
