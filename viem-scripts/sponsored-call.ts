import {
  createPublicClient,
  createWalletClient,
  encodePacked,
  Hex,
  http,
  keccak256,
  parseEther,
} from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { sepolia } from "viem/chains";
import { config as envConfig } from "dotenv";
import path from "path";
import {
  SPONSORED_CALL_ADDRESS,
  abi,
  tokenABI,
  TEST_TOKEN_ADDRESS,
} from "./contracts";
import { encodeFunctionData } from "viem";
envConfig({ path: path.resolve(__dirname, "../.env") });

const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL;
const ALICE_PK = process.env.ALICE_PK;
const SPONSOR_PK = process.env.SPONSOR_PK;

async function main() {
  if (!SEPOLIA_RPC_URL || !ALICE_PK || !SPONSOR_PK) {
    throw new Error("ENV is not set");
  }
  const alice_wallet = privateKeyToAccount(ALICE_PK as Hex);

  const walletClient = createWalletClient({
    chain: sepolia,
    account: privateKeyToAccount(SPONSOR_PK as Hex),
    transport: http(SEPOLIA_RPC_URL),
  });
  const readClient = createPublicClient({
    chain: sepolia,
    transport: http(SEPOLIA_RPC_URL),
  });

  const authorization = await walletClient.signAuthorization({
    account: alice_wallet,
    contractAddress: SPONSORED_CALL_ADDRESS,
  });

  //Call.data payload
  const calldata = encodeFunctionData({
    abi: tokenABI,
    functionName: "transfer",
    // test token recipient address & amount
    // TODO: set the recipient address
    args: ["0x0000000000000000000000000000000000000000", parseEther("1")],
  });

  //Encode Call
  const encodedCall = encodePacked(
    ["address", "bytes", "uint256"],
    [TEST_TOKEN_ADDRESS, calldata, BigInt(0)]
  );

  const nonce = (await readClient.readContract({
    abi: abi,
    address: alice_wallet.address,
    functionName: "nonce",
  })) as bigint;

  //TODO: Be careful about the nonce!
  const callsHash = keccak256(
    encodePacked(["uint256", "bytes"], [nonce, encodedCall])
  );
  const sig = await alice_wallet.signMessage({
    message: { raw: callsHash },
  });

  const call = {
    to: TEST_TOKEN_ADDRESS,
    data: calldata,
    value: BigInt(0),
  };

  const tx = await walletClient.writeContract({
    abi,
    address: alice_wallet.address,
    authorizationList: [authorization],
    functionName: "executeCalls",
    args: [[call], sig],
  });
  console.log(tx);
}

main();
