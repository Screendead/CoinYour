import {
  getAccountAddress,
  mintFlow,
  deployContractByName,
  sendTransaction,
  executeScript
} from "flow-js-testing"

export const getEmulatorAddress = async () => getAccountAddress("emulator-account")

export const deployContracts = async () => {
  const emulatorAddress = await getEmulatorAddress()
  await mintFlow(emulatorAddress, "10.0")
  const addressMap = {
    FungibleToken: "0xee82856bf20e2aa6",
  }
  await deployContractByName({ to: emulatorAddress, name: "FUSD", addressMap })
  addressMap.FUSD = emulatorAddress;

  await deployContractByName({ to: emulatorAddress, name: "NonFungibleToken", addressMap })
  addressMap.NonFungibleToken = emulatorAddress;

  await deployContractByName({ to: emulatorAddress, name: "MetadataViews", addressMap })
  addressMap.MetadataViews = emulatorAddress;
  
  await deployContractByName({ to: emulatorAddress, name: "CoinYour", addressMap })
}

export const createCoinYourCollection = async (recipient) => {
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

export const listUserWordTokens = async (recipient) => {
  const name = "ListUserWordTokens"
  const args = [recipient]
  const wordTokens = await executeScript({ name, args })
  return wordTokens
}
