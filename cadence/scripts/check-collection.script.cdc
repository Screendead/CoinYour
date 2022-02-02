import CoinYour from 0xWordToken

pub fun main(addr: Address): Bool {
  let ref = getAccount(addr).getCapability<&{WordTokenContract.CollectionPublic}>(WordTokenContract.CollectionPublicPath).check()
  return ref
}