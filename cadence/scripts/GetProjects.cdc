import CoinYour from "../contracts/CoinYour.cdc"

pub fun main(): {UInt64: CoinYour.ProjectData} {
  return CoinYour.getProjects();
}