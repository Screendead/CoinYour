import CoinYour from "../contracts/CoinYour.cdc"

pub fun main(addr: Address): Bool {
  let ref = getAccount(addr).getCapability<&{WordTokenContract.CollectionPublic}>(WordTokenContract.CollectionPublicPath).check()
  return ref
}