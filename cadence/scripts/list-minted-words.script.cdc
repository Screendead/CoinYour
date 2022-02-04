import CoinYour from "../contracts/CoinYour.cdc"

pub fun main(): {UInt64: CoinYour.WordEdition} {
  return CoinYour.allMintedWords;
}