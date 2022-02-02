import {
  getAccountAddress,
  mintFlow,
  deployContractByName,
  sendTransaction,
  executeScript
} from "flow-js-testing"

export const getWordTokenAdminAddress = async () => getAccountAddress("WordTokenAdmin")

export const deployWordTokenContract = async () => {
  const WordTokenAdmin = await getAccountAddress("WordTokenAdmin")
  await mintFlow(WordTokenAdmin, "10.0")
  const addressMap = { FungibleToken: "0xee82856bf20e2aa6" }
  await deployContractByName({ to: WordTokenAdmin, name: "WordTokenContract", addressMap })
}

export const createWordTokenTemplate = async (wordToken) => {
  const WordTokenAdmin = await getWordTokenAdminAddress()
  const signers = [WordTokenAdmin]
  const name = "CreateTemplate"
  const args = [wordToken.dna, wordToken.name]
  await sendTransaction({ name, signers, args })
}

export const createWordTokenCollection = async (recipient) => {
  const name = "CreateCollection"
  const signers = [recipient]
  await sendTransaction({ name, signers })
}

export const mintWordToken = async (recipient, wordToken) => {
  const name = "MintWordToken"
  const signers = [recipient]
  const args = [wordToken.templateID, wordToken.price]
  await sendTransaction({ name, args, signers })
}

export const justCreateWordToken = async (recipient, wordToken) => {
  const name = "JustCreateWordToken"
  const signers = [recipient]
  const args = [wordToken.word, wordToken.price]
  await sendTransaction({ name, args, signers })
}

export const listUserWordTokens = async (recipient) => {
  const name = "ListUserWordTokens"
  const args = [recipient]
  const wordTokens = await executeScript({ name, args })
  return wordTokens
}

export const createWordTokenFamily = async (family) => {
  const WordTokenAdmin = await getWordTokenAdminAddress()
  const name = "CreateFamily"
  const signers = [WordTokenAdmin]
  const args = [family.name, family.price]
  await sendTransaction({ name, signers, args })
}

export const addTemplateToFamily = async (family, template) => {
  const WordTokenAdmin = await getWordTokenAdminAddress()
  const name = "AddTemplateToFamily"
  const signers = [WordTokenAdmin]
  const args = [family.familyID, template.templateID]
  await sendTransaction({ name, signers, args })
}

export const listTemplatesOfFamily = async (familyID) => {
  const name = "ListFamilyTemplates"
  const args = [familyID]
  const res = await executeScript({ name, args })
  return res;
}

export const batchMintWordTokenFromFamily = async (familyID, templateIDs, amount, recipient) => {
  const name = "BatchMintWordTokenFromFamily"
  const signers = [recipient]
  const args = [familyID, templateIDs, amount]
  await sendTransaction({ name, signers, args })
}

