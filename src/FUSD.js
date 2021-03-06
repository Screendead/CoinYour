import {
  getAccountAddress,
  mintFlow,
  deployContractByName,
  sendTransaction,
  executeScript
} from "flow-js-testing"
import { getEmulatorAddress } from './CoinYour';

export const deployFUSDContract = async () => {
  const FUSDAdmin = await getEmulatorAddress()
  await mintFlow(FUSDAdmin, "10.0")
  const addressMap = { FungibleToken: "0xee82856bf20e2aa6" }
  await deployContractByName({ to: FUSDAdmin, name: "FUSD", addressMap })
}

export const createFUSDVault = async (recipient) => {
  const signers = [recipient]
  const name = "CreateFUSDVault"
  await sendTransaction({ name, signers })
}

export const createFUSDMinter = async () => {
  const FUSDAdmin = await getEmulatorAddress()
  const signers = [FUSDAdmin]
  const name = "CreateFUSDMinter"
  await sendTransaction({ signers, name })
}

export const mintFUSD = async (recipient, amount) => {
  const FUSDAdmin = await getEmulatorAddress()
  const signers = [FUSDAdmin]
  const args = [recipient, amount]
  const name = "MintFUSD"
  await sendTransaction({ signers, args, name })
}

export const getFUSDBalance = async (recipient) => {
  const args = [recipient]
  const balance = await executeScript({ name: "GetFUSDBalance", args })
  return balance
}

export const fundAccountWithFUSD = async (recipient, amount) => {
  await createFUSDMinter()
  await createFUSDVault(recipient)
  await mintFUSD(recipient, amount)
  const balance = await getFUSDBalance(recipient)
  return balance
}