import {
  getAccountAddress,
  mintFlow,
  deployContractByName,
  sendTransaction,
  executeScript
} from "flow-js-testing"

export const getEmulatorAddress = async () => getAccountAddress("AdminAccount")

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
  await sendTransaction({ signers, name })
}

export const getProjects = async () => {
  const name = "GetProjects"
  const res = await executeScript({ name })
  return res;
}

export const registerProject = async (signer, projectInfo) => {
  const name = "RegisterProject"
  const signers = [signer]
  // const args = [
  //   projectInfo.id,
  //   projectInfo.name,
  //   projectInfo.description,
  //   projectInfo.website,
  //   projectInfo.active,
  //   projectInfo.minimumPrice,
  //   projectInfo.startDate,
  //   projectInfo.endDate,
  //   projectInfo.words,
  //   projectInfo.prices,
  //   projectInfo.nftNameTemplate,
  //   projectInfo.nftDescriptionTemplate,
  //   projectInfo.receivers,
  //   projectInfo.metadata,
  // ]
  const args = Object.values(projectInfo);
  await sendTransaction({ signers, name, args: args })
}

export const mintWordToken = async (recipient, wordToken) => {
  const name = "MintWordToken"
  const signers = [recipient]
  const args = [
    wordToken.wordEditionID,
    wordToken.messageToMint,
    wordToken.author,
    wordToken.imageURL,
    wordToken.amount,
  ]
  return sendTransaction({ signers, name, args })
}

export const listUserWordTokens = async (recipient) => {
  const name = "ListUserWordTokens"
  const args = [recipient]
  const wordTokens = await executeScript({ name, args })
  return wordTokens
}
