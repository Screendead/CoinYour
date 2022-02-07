import path from "path"
import {
  emulator,
  init,
  executeScript,
  getAccountAddress,
  mintFlow,
  sendTransaction,
  shallRevert,
  shallPass,
} from "flow-js-testing"
import {
  deployContracts,
  createCoinYourCollection,
  registerProject,
  mintWordToken,
  getProjects,
  listUserWordTokens,
} from "./src/CoinYour";
import {
  fundAccountWithFUSD,
  createFUSDVault,
  getFUSDBalance,
} from "./src/FUSD";

jest.setTimeout(50000);

const TEST_PROJECT = {
  name: "Coin Your Constitution",
  description: "A project to help you coin your constitution",
  messageMaxLength: 100,
  website: "https://coinyour.art/constitution/", // Must include trailing slash! Otherwise formatting NFT metadata will create a nonfunctional URL
  active: true,
  minimumPrice: "0.00000000",
  startDate: null,
  endDate: null,
  words: ["We", "the", "People", "of", "the", "United", "States", "in", "Order", "to", "form", "a", "more", "perfect", "Union", "establish", "Justice", "insure", "domestic", "Tranquility", "provide", "for", "the", "common", "defence", "promote", "the", "general", "Welfare", "and", "secure", "the", "Blessings", "of", "Liberty", "to", "ourselves", "and", "our", "Posterity",],
  prices: ["4096.00000000", "2048.00000000", "1024.00000000", "512.00000000", "256.00000000", "128.00000000", "64.00000000", "32.00000000", "16.00000000", "8.00000000", "4.00000000", "2.00000000", "1.00000000"],
  sequential: true,
  nftNameTemplate: [
    "\"", "${WORD_TEXT}", "\" ", "w", "${WORD_NUMBER}", "e", "${EDITION_NUMBER}"
  ],
  nftDescriptionTemplate: [
    "${FULL_WORD_ID}", ": \"", "${WORD_TEXT}", "\" (Word #", "${WORD_NUMBER}", ", Edition ", "${EDITION_NUMBER}", " of ", "${NUMBER_OF_EDITIONS}", " from project #", "${PROJECT_NUMBER}", " \"", "${PROJECT_NAME}", "\") minted by ", "${NFT_MINTED_BY}", " at ", "${DIRECT_LINK_TO_TOKEN}", " with the message: ", "${NFT_MESSAGE}"
  ],
  receivers: {},
  metadata: {},
};

let TEST_WORD_TOKEN;

describe("CoinYour", () => {
  beforeEach(async () => {
    const basePath = path.resolve(__dirname, "./cadence");
    const port = 8080;
    init(basePath, port);
    
    let em = await emulator.start(port, false);

    await deployContracts()

    let jack = await getAccountAddress("Jack");
    let chris = await getAccountAddress("Chris");

    await createFUSDVault(jack);
    await createFUSDVault(chris);

    TEST_PROJECT.receivers[jack] = "100.00000000";
    TEST_PROJECT.receivers[chris] = "100.00000000";

    TEST_WORD_TOKEN = {
      wordEditionID: (1 << 17) + (5 << 4) + (13 << 0),
      messageToMint: "Hello, world!",
      author: "0x0000000000000000",
      imageURL: "https://example.com/image.png",
      amount: "1.00000000",
    };

    return em;
  });

  afterEach(async () => {
    // emulator.setLogging(false)
    return emulator.stop();
  });

  it("Should list 0 word tokens", async () => {
    const res = await executeScript({ name: "list-minted-words.script" })
    console.log(res);
    expect(res).toMatchObject({})
  });

  it("Should mint FUSD", async () => {
    const recipient = await getAccountAddress("Jack")
    const balance = await fundAccountWithFUSD(recipient, "100.00000000")
    expect(balance).toBe("100.00000000")
  })

  it("Should register a project", async () => {
    const signer = await getAccountAddress("AdminAccount")
    await mintFlow(signer, "10.00000000")
    await registerProject(signer, {
      id: 1,
      ...TEST_PROJECT
    });
    const projects = await getProjects();
    expect(projects).toMatchObject({
      '1': TEST_PROJECT,
    });
  })

  it("Should mint a word token", async () => {
    // Register Project
    const signer = await getAccountAddress("AdminAccount")
    await mintFlow(signer, "10.00000000")
    await registerProject(signer, {
      id: 1,
      ...TEST_PROJECT
    });

    const recipient = await getAccountAddress("Buyer")
    await mintFlow(recipient, "10.00000000")
    await fundAccountWithFUSD(recipient, "100.00000000")

    // // Mint Word Token
    await createCoinYourCollection(recipient)

    await mintWordToken(recipient, TEST_WORD_TOKEN)

    let balance = await getFUSDBalance(recipient)

    const userWordTokens = await listUserWordTokens(recipient)
    // expect(txResult)

    const jack = await getAccountAddress("Jack");
    const chris = await getAccountAddress("Chris");
    let jackBalance = await getFUSDBalance(jack);
    let chrisBalance = await getFUSDBalance(chris);

    expect(userWordTokens).toMatchObject([TEST_WORD_TOKEN.wordEditionID])
    expect(balance).toBe("99.00000000");
    expect(jackBalance).toBe("0.50000000");
    expect(chrisBalance).toBe("0.50000000");
  })

  it("Should fail to mint a word token due to low balance", async () => {
    // Register Project
    const signer = await getAccountAddress("AdminAccount")
    await mintFlow(signer, "10.00000000")
    await registerProject(signer, {
      id: 1,
      ...TEST_PROJECT
    });

    const recipient = await getAccountAddress("Buyer")
    await mintFlow(recipient, "10.00000000")
    await fundAccountWithFUSD(recipient, "0.50000000") // Price of edition 13 is 1.00000000

    // // Mint Word Token
    await createCoinYourCollection(recipient)

    let txResult = await shallRevert(
      mintWordToken(recipient, TEST_WORD_TOKEN)
    );
    let balance = await getFUSDBalance(recipient)

    expect(txResult).not.toBeDefined(); // shallRevert should return undefined if it mintWordToken fails
    expect(balance).toBe("0.50000000"); // Balance should not change if transaction fails
  })

  it("Should fail to mint a word token due to message being too long", async () => {
    // Register Project
    const signer = await getAccountAddress("AdminAccount")
    await mintFlow(signer, "10.00000000")
    await registerProject(signer, {
      id: 1,
      ...TEST_PROJECT
    });

    const recipient = await getAccountAddress("Buyer")
    await mintFlow(recipient, "10.00000000")
    await fundAccountWithFUSD(recipient, "100.00000000")

    // // Mint Word Token
    await createCoinYourCollection(recipient)

    TEST_WORD_TOKEN.messageToMint = "a".repeat(101)

    let txResult = await shallRevert(
      mintWordToken(recipient, TEST_WORD_TOKEN)
    );
    let balance = await getFUSDBalance(recipient)

    expect(txResult).not.toBeDefined(); // shallRevert should return undefined if it mintWordToken fails
    expect(balance).toBe("100.00000000"); // Balance should not change if transaction fails
  })

  it("Should fail to mint a sequential word token due to being out of sequence", async () => {
    // Register Project
    const signer = await getAccountAddress("AdminAccount")
    await mintFlow(signer, "10.00000000")
    await registerProject(signer, {
      id: 1,
      ...TEST_PROJECT
    });

    const recipient = await getAccountAddress("Buyer")
    await mintFlow(recipient, "10.00000000")
    await fundAccountWithFUSD(recipient, "100.00000000")

    // // Mint Word Token
    await createCoinYourCollection(recipient)

    TEST_WORD_TOKEN.wordEditionID = (1 << 17) + (5 << 4) + (6 << 0); // Edition 6 of 13

    let txResult = await shallRevert(
      mintWordToken(recipient, TEST_WORD_TOKEN)
    );
    let balance = await getFUSDBalance(recipient)

    expect(txResult).not.toBeDefined(); // shallRevert should return undefined if it mintWordToken fails
    expect(balance).toBe("100.00000000"); // Balance should not change if transaction fails
  })

  it("Should mint all tokens from Edition 13 down to Edition 1", async () => {
    // Register Project
    const signer = await getAccountAddress("AdminAccount")
    await mintFlow(signer, "10.00000000")
    await registerProject(signer, {
      id: 1,
      ...TEST_PROJECT
    });

    const recipient = await getAccountAddress("Buyer")
    await mintFlow(recipient, "10.00000000")
    await fundAccountWithFUSD(recipient, "8192.00000000")

    // // Mint Word Token
    await createCoinYourCollection(recipient)

    let expectedResult = [];

    for (let i = 13; i > 0; i--) {
      TEST_WORD_TOKEN.wordEditionID = (1 << 17) + (12 << 4) + (i << 0);
      TEST_WORD_TOKEN.amount = TEST_PROJECT.prices[i - 1],
      expectedResult.push(TEST_WORD_TOKEN.wordEditionID);
      console.log(i);

      await mintWordToken(recipient, TEST_WORD_TOKEN)
    }

    let balance = await getFUSDBalance(recipient)

    const userWordTokens = (await listUserWordTokens(recipient)).sort((a, b) => a - b);

    const jack = await getAccountAddress("Jack");
    const chris = await getAccountAddress("Chris");
    let jackBalance = await getFUSDBalance(jack);
    let chrisBalance = await getFUSDBalance(chris);

    expect(userWordTokens).toMatchObject(expectedResult.sort((a, b) => a - b))
    expect(balance).toBe("1.00000000");
    expect(jackBalance).toBe("4095.50000000");
    expect(chrisBalance).toBe("4095.50000000");
  })

  it("Should fail to mint a word token due to the edition number being too high", async () => {
    // Register Project
    const signer = await getAccountAddress("AdminAccount")
    await mintFlow(signer, "10.00000000")
    await registerProject(signer, {
      id: 1,
      ...TEST_PROJECT
    });

    const recipient = await getAccountAddress("Buyer")
    await mintFlow(recipient, "10.00000000")
    await fundAccountWithFUSD(recipient, "100.00000000")

    // // Mint Word Token
    await createCoinYourCollection(recipient)

    TEST_WORD_TOKEN.wordEditionID = (1 << 17) + (5 << 4) + (14 << 0); // Edition 14 of 13 !!

    let txResult = await shallRevert(
      mintWordToken(recipient, TEST_WORD_TOKEN)
    );
    let balance = await getFUSDBalance(recipient)

    expect(txResult).not.toBeDefined(); // shallRevert should return undefined if it mintWordToken fails
    expect(balance).toBe("100.00000000"); // Balance should not change if transaction fails
  })
})
