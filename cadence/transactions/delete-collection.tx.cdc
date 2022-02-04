  import CoinYour from "../contracts/CoinYour.cdc"

  transaction() {
    prepare(acct: AuthAccount) {
      let collectionRef <- acct.load<@WordTokenContract.Collection>(from: WordTokenContract.CollectionStoragePath)
        ?? panic("Could not borrow collection reference")
      destroy collectionRef
      acct.unlink(WordTokenContract.CollectionPublicPath)
    }
  }
