  import CoinYour from "../contracts/CoinYour.cdc"

  pub fun main(wordID: UInt64): [CoinYour.WordEdition] {
    return CoinYour.queryByWord(projectID: UInt64(1), wordID: wordID)
  }
