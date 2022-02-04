import CoinYour from "../contracts/CoinYour.cdc"

transaction {
    prepare(acct: AuthAccount) {
      // Return early if the account already has a collection
      if acct.borrow<&CoinYour.Collection>(from: CoinYour.CollectionStoragePath) != nil {
      panic ("contract exists")
      }

     let collection <- CoinYour.createEmptyCollection()
     acct.save<@CoinYour.Collection>(<-collection, to: CoinYour.CollectionStoragePath)
     acct.link<&{CoinYour.ConstitutionWordsCollectionPublic}>(CoinYour.CollectionPublicPath, target: CoinYour.CollectionStoragePath)
     return 
    }
  }
