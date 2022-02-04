
  import CoinYour from "../contracts/CoinYour.cdc"
  import MetadataViews from 0xMetadataViews

  let collection = account.getCapability(CoinYour.CollectionPublicPath)
      .borrow<&{CoinYour.CollectionPublicPath}>()
      ?? panic("Could not borrow a reference to the collection")

  let nft = collection.borrowNFT(id: 42)

  if let view = nft.resolveView(Type<MetadataViews.Display>()) {
      let display = view as! MetadataViews.Display

      log(display.name)
      log(display.description)
      log(display.thumbnail)
  }
