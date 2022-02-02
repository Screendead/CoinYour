  import CoinYour from 0xWordToken
  import FUSD from 0xFUSD
  import FungibleToken from 0xFungibleToken
  import NonFungibleToken from 0xNonFungibleToken

  transaction(wordEditionID: UInt64, messageToMint: String, author: Address, imageURL: String, amount: UFix64) {
    let receiverReference: &CoinYour.Collection
    let sentVault: @FungibleToken.Vault

    prepare(acct: AuthAccount) {
      if acct.borrow<&CoinYour.Collection>(from: CoinYour.CollectionStoragePath) == nil {
        let collection <- CoinYour.createEmptyCollection()
        acct.save<@CoinYour.Collection>(<-collection, to: CoinYour.CollectionStoragePath)
        acct.link<&{CoinYour.ConstitutionWordsCollectionPublic}>(CoinYour.CollectionPublicPath, target: CoinYour.CollectionStoragePath) 
        }

      self.receiverReference = acct.borrow<&CoinYour.Collection>(from: CoinYour.CollectionStoragePath)
        ?? panic("Cannot borrow Collection")

      let vaultRef = acct.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow FUSD vault")
      self.sentVault <- vaultRef.withdraw(amount: amount)
    }

    execute {
      let newWordEdition <- CoinYour.mintNFT(wordEditionID: wordEditionID, messageToMint: messageToMint, author: author, imageURL: imageURL, paymentVault: <-self.sentVault)
      self.receiverReference.deposit(token: <-newWordEdition)
    }
  }