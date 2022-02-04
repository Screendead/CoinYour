import CoinYour from "../contracts/CoinYour.cdc"

pub fun main(addr: Address): [UInt64] {
  let account = getAccount(addr)
  
  if let ref = account.getCapability<&{CoinYour.CollectionPublic}>(CoinYour.CollectionPublicPath)
    .borrow() {
      let words = ref.getIDs()
      return words
    }
  
  return []
}

//OLD v2 - before contract 7
//`

// import CoinYour from "../contracts/CoinYour.cdc"

// pub fun main(addr: Address): {UInt64: CoinYour.WordEdition}? {
//   let account = getAccount(addr)
  
//   if let ref = account.getCapability<&{CoinYour.CollectionPublic}>(CoinYour.CollectionPublicPath)
//               .borrow() {
//                 let words = ref.listConstitutionWords()
//                 return words
//               }
  
//   return nil
// }
// `






//OLD v1
// `
//   import ExampleNFT from "../contracts/CoinYour.cdc"
//   import NonFungibleToken from 0x632e88ae7f2d7c20
  
// //  pub fun main(addr: Address): [UInt64]? {
//   pub fun main(addr: Address): &NonFungibleToken.NFT? {
//     let account = getAccount(addr)

// //  let ref = account.getCapability<&{ExampleNFT.NFTReceiver}>(/public/NFTCollection)
// let ref = account.getCapability<&{NonFungibleToken.CollectionPublic}>(/public/NFTCollection)
// .borrow() ?? panic("Cannot borrow reference")
// //.borrow() ?? panic("Could not get receiver reference to the NFT Collection") 
//                  // let wordTokens = ref.listWords()
//                //  let wordTokens = ref.getIDs()
//                  let wordTokens = ref.borrowNFT(id: 0)
//                  return wordTokens
                
//               //  
    
//  //   return nil
//   }
// `