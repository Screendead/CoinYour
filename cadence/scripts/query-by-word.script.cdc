  import CoinYour from 0xWordToken

  pub fun main(wordID: UInt64): [CoinYour.WordEdition] {
    return CoinYour.queryByWord(projectID: UInt64(1), wordID: wordID)
  }
