import path from "path"
import {
  emulator,
  init,
  executeScript,
  getAccountAddress,
  mintFlow,
  sendTransaction,
} from "flow-js-testing"
import {
  deployContracts,
  createCoinYourCollection,
  registerProject,
  mintWordToken,
  getProjects,
} from "./src/CoinYour";
import { fundAccountWithFUSD } from "./src/FUSD";

jest.setTimeout(50000);

const TEST_PROJECT = {
  id: 1,
  name: "Coin Your Constitution",
  description: "A project to help you coin your constitution",
  website: "https://coinyour.art/constitution/", // Must include trailing slash! Otherwise formatting NFT metadata will create a nonfunctional URL
  active: true,
  minimumPrice: null,
  startDate: null,
  endDate: null,
  words: ["We", "the", "People", "of", "the", "United", "States", "in", "Order", "to", "form", "a", "more", "perfect", "Union", "establish", "Justice", "insure", "domestic", "Tranquility", "provide", "for", "the", "common", "defence", "promote", "the", "general", "Welfare", "and", "secure", "the", "Blessings", "of", "Liberty", "to", "ourselves", "and", "our", "Posterity",],
  prices: ["4096.0","2048.0","1024.0","512.0","256.0","128.0","64.0","32.0","16.0","8.0","4.0","2.0","1.0"],
  nftNameTemplate: [
    "\"", "${WORD_TEXT}", "\" ", "w", "${WORD_NUMBER}", "e", "${EDITION_NUMBER}"
  ],
  nftDescriptionTemplate: [
    "${FULL_WORD_ID}", ": \"", "${WORD_TEXT}", "\" (Word #", "${WORD_NUMBER}", ", Edition ", "${EDITION_NUMBER}", " of ", "${NUMBER_OF_EDITIONS}", " from project #", "${PROJECT_NUMBER}", " \"", "${PROJECT_NAME}", "\") minted by ", "${NFT_MINTED_BY}", " at ", "${DIRECT_LINK_TO_TOKEN}", " with the message: ", "${NFT_MESSAGE}"
  ],
  receivers: {
    "0x71b6206d010d80f4": "100.0", // Jack
    "0xcf105f1329ba52e4": "100.0", // Chris
  },
  metadata: {},
}

const TEST_WORD_TOKEN = {
  wordEditionID: (1 << 17) + (5 << 4) + (12 << 0),
  messageToMint: "Hello, world!",
  author: "0x0",
  imageURL: "https://example.com/image.png",
  amount: "1.00",
}

describe("CoinYour", () => {
  beforeEach(async () => {
    const basePath = path.resolve(__dirname, "./cadence");
    const port = 8080;
    init(basePath, port);
    return emulator.start(port, true);
  });

  afterEach(async () => {
    emulator.setLogging(false)
    return emulator.stop();
  });

  it("Should do something", async () => {
    const signer = await getAccountAddress("Jack")
    await mintFlow(signer, "10.0")
    const args = [
      TEST_PROJECT.id,
      TEST_PROJECT.name,
      TEST_PROJECT.description,
      TEST_PROJECT.website,
      TEST_PROJECT.active,
      TEST_PROJECT.minimumPrice,
      TEST_PROJECT.startDate,
      TEST_PROJECT.endDate,
      TEST_PROJECT.words,
      TEST_PROJECT.prices,
      TEST_PROJECT.nftNameTemplate,
      TEST_PROJECT.nftDescriptionTemplate,
      TEST_PROJECT.receivers,
      TEST_PROJECT.metadata,
    ]
    await (async () => {
      await sendTransaction({ signers: [signer], name: "TestTransaction", args })
    })();
    // expect(projects).toMatchObject([TEST_PROJECT]);
  })

  // it("Deploys CoinYour contract", async () => {
  //   await deployContracts()
  // });

  // it("Should list 0 word tokens", async () => {
  //   await deployContracts()
  //   const res = await executeScript({ name: "list-minted-words.script" })
  //   console.log(res);
  //   expect(res).toMatchObject({})
  // });

  // it("Should mint FUSD", async () => {
  //   await deployContracts()
  //   const recipient = await getAccountAddress("Jack")
  //   const balance = await fundAccountWithFUSD(recipient, "100.00")
  //   expect(balance).toBe("100.00000000")
  // })

  // it("Should register a project", async () => {
  //   await deployContracts()
  //   const signer = await getAccountAddress("AdminAccount")
  //   await mintFlow(signer, "10.0")
  //   await registerProject(signer, TEST_PROJECT);
  //   const projects = await getProjects();
  //   // expect(projects).toMatchObject([TEST_PROJECT]);
  // })

  // it("Should mint a word token", async () => {
  //   await deployContracts()
  //   const recipient = await getAccountAddress("Jack")
  //   await mintFlow(recipient, "10.0")
  //   await fundAccountWithFUSD(recipient, "100.00")
  //   await createCoinYourCollection(recipient)
  //   await mintWordToken(recipient, TEST_WORD_TOKEN)
  //   // const userWordTokens = await listUserWordTokens(recipient)
  //   // expect(userWordTokens['1']).toMatchObject(TEST_WORD_TOKEN)
  // })
})