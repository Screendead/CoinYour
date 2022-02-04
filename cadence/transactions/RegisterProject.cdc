import CoinYour from "../contracts/CoinYour.cdc";
 
transaction (
  id: UInt64,
  name: String,
  description: String,
  messageMaxLength: Int?,
  website: String,
  active: Bool,
  minimumPrice: UFix64?,
  startDate: UFix64?,
  endDate: UFix64?,
  words: [String],
  prices: [UFix64],
  sequential: Bool,
  nftNameTemplate: [String],
  nftDescriptionTemplate: [String],
  receivers: {Address: UFix64},
  metadata: {String: AnyStruct},
) {
  var adminRef: &CoinYour.Admin

  prepare(acct: AuthAccount) {
    self.adminRef = acct.borrow<&CoinYour.Admin>(from: CoinYour.AdminStoragePath) ?? panic("Cannot borrow admin ref")
  }

  execute {
    self.adminRef.registerProject(
      id: id,
      name: name,
      description: description,
      messageMaxLength: messageMaxLength,
      website: website,
      active: active,
      minimumPrice: minimumPrice,
      startDate: startDate,
      endDate: endDate,
      words: words,
      prices: prices,
      sequential: sequential,
      nftNameTemplate: nftNameTemplate,
      nftDescriptionTemplate: nftDescriptionTemplate,
      receivers: receivers,
      metadata: metadata,
    );
  }
}
