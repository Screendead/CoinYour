import path from "path"
import {
  emulator,
  init,
  executeScript,
  getAccountAddress,
  mintFlow
} from "flow-js-testing"
import {
  deployContracts,
} from "./src/CoinYour";
import { fundAccountWithFUSD } from "./src/FUSD";

jest.setTimeout(50000);

describe("CoinYour", () => {
  beforeEach(async () => {
    const basePath = path.resolve(__dirname, "./cadence");
    const port = 8080;
    init(basePath, port);
    return emulator.start(port, false);
  });

  afterEach(async () => {
    return emulator.stop();
  });

  it("Deploys CoinYour contract", async () => {
    await deployContracts()
  });

  it("Should list 0 word tokens", async () => {
    const res = await executeScript({ name: "list-minted-words.script" })
    console.log(res);
    expect(res).toMatchObject({})
  });

  it("Should mint FUSD", async () => {
    const recipient = await getAccountAddress("emulator-account")
    const balance = await fundAccountWithFUSD(recipient, "100.00")
    expect(balance).toBe("100.00000000")
  })

  // it("Should mint a word token", async () => {
  //   const recipient = await getAccountAddress("WordTokenRecipient")
  //   await mintFlow(recipient, "10.0")
  //   await fundAccountWithFUSD(recipient, "100.00")
  //   await createCoinYourCollection(recipient)
  //   await mintWordToken(recipient, TEST_WORD_TOKEN)
  //   const userWordTokens = await listUserWordTokens(recipient)
  //   expect(userWordTokens['1']).toMatchObject(TEST_WORD_TOKEN)
  // })
})