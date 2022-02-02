import CoinYour from "../contracts/CoinYour.cdc"

transaction {
  prepare(acct: AuthAccount) {
    let collection <- CoinYour.createEmptyCollection()
    acct.save<@CoinYour.Collection>(<-collection, to: CoinYour.CollectionStoragePath)
    acct.link<&{CoinYour.CollectionPublic}>(CoinYour.CollectionPublicPath, target: CoinYour.CollectionStoragePath)
  }
}