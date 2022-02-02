import FungibleToken from "./FungibleToken.cdc"
import NonFungibleToken from "./NonFungibleToken.cdc"
import FUSD from "./FUSD.cdc"
import MetadataViews from "./MetadataViews.cdc"

pub contract CoinYour: NonFungibleToken {
  //declare variables
  pub var totalSupply: UInt64

  access(contract) let projectList: {UInt64: ProjectData}

  pub let allMintedWords: {UInt64: WordEdition}

  pub let CollectionStoragePath: StoragePath
  pub let CollectionPublicPath: PublicPath
  pub let AdminStoragePath: StoragePath

  //declare events
  pub event ContractInitialized()
  pub event Withdraw(id: UInt64, from: Address?)
  pub event Deposit(id: UInt64, to: Address?)

  access(contract) fun getProjectID(_ id: UInt64): UInt64 {
    return (id & 0b1111_0000000000000_0000) >> 17;
  }
  access(contract) fun getWordID(_ id: UInt64): UInt64 {
    return ((id & 0b0000_1111111111111_0000) >> 4) - 1;
  }
  access(contract) fun getEditionID(_ id: UInt64): UInt64 {
    return (id & 0b0000_0000000000000_1111) - 1;
  }

  pub struct ProjectData {
    pub var name: String
    pub var description: String
    pub var website: String
    pub var active: Bool
    pub var minimumPrice: UFix64

    pub var startDate: UFix64?;
    pub var endDate: UFix64?;

    pub var words: [String];
    pub var prices: [UFix64];
    pub var nftNameTemplate: [String];
    pub var nftDescriptionTemplate: [String];
    pub var receivers: {Address: UFix64};

    pub var metadata: {String: AnyStruct}

    pub var totalShares: UFix64;

    init(
      name: String,
      description: String,
      website: String, // Should be a URL to the project - can be a subdomain or subdirectory of a main website
      active: Bool,
      minimumPrice: UFix64?,
      startDate: UFix64?,
      endDate: UFix64?,
      words: [String],
      prices: [UFix64],
      nftNameTemplate: [String],
      nftDescriptionTemplate: [String],
      receivers: {Address: UFix64},
      metadata: {String: AnyStruct},
    ) {
      self.name = name;
      self.description = description;
      self.website = website;
      self.active = active;
      self.startDate = startDate;
      self.endDate = endDate;
      self.minimumPrice = minimumPrice ?? 0.0;
      self.words = words;
      self.prices = prices;
      self.nftNameTemplate = nftNameTemplate;
      self.nftDescriptionTemplate = nftDescriptionTemplate;
      self.receivers = receivers;
      self.metadata = metadata;

      var totalShares: UFix64 = 0.0;
      for share in receivers.values {
        totalShares = totalShares + share;
      }
      self.totalShares = totalShares;
    }

    pub fun calculateTotalShares() {
      var totalShares: UFix64 = 0.0;
      for share in self.receivers.values {
        totalShares = totalShares + share;
      }
      self.totalShares = totalShares;
    }
  }
  
  pub struct WordEdition {
    // wordEditionID structure: 
    // Project ID bitshifted left 17 bits,
    // Word ID bitshifted left 4 bits,
    // Edition ID unchanged.
    // All numbers bitwise ANDed together to unique number.
    pub let wordEditionID: UInt64
    pub let word: String
    pub let message: String
    pub let author: Address
    pub let mintedAt: UFix64
    pub let image: MetadataViews.IPFSFile

    init(wordEditionID: UInt64, word: String, message: String, author: Address, imageURL: String) {
      self.wordEditionID = wordEditionID
      self.word = word
      self.message = message
      self.author = author
      self.mintedAt = getCurrentBlock().timestamp
      //CID is the content identifier for the IPFS file.
      //It is the path without the IPFS prefix
      self.image = MetadataViews.IPFSFile(url: imageURL, path: nil)
    }
  }

  //Define the tangible thing (the CoinYourWord NFT) being created
  pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
    pub let id: UInt64
    pub let data: WordEdition

    init(id: UInt64, data: WordEdition) {
      pre {
        CoinYour.projectList[CoinYour.getProjectID(id)] != nil : "Could not mint NFT: Project does not exist"
        CoinYour.projectList[CoinYour.getProjectID(id)]!.active : "Could not mint NFT: Project is not active"
        CoinYour.projectList[CoinYour.getProjectID(id)]!.words[CoinYour.getWordID(id)] != nil : "Could not mint NFT: NFT with given ID does not exist."
        CoinYour.getEditionID(id) >= 0
            && CoinYour.getEditionID(id) <= UInt64(CoinYour.projectList[CoinYour.getProjectID(id)]!.prices.length) : "Could not mint NFT: Edition out of range."
      }

      self.id = id;
      self.data = data;
    }

    priv fun generateFromTemplate(template: [String]): String {
      var _result = "";

      for current in template {
        var thisSegment = "";

        // Use the templates (ex. ["This is word ", "${WORD_NUMBER}", "."]) to generate the name and description of the NFT on-the-fly.
        switch current {
          case "${WORD_TEXT}":
            thisSegment = self.data.word;
          case "${NFT_MESSAGE}":
            thisSegment = self.data.message;
          case "${NFT_MINTED_BY}":
            thisSegment = self.data.author.toString();
          case "${NFT_MINT_DATE}":
            thisSegment = self.data.mintedAt.toString();
          case "${WORD_NUMBER}":
            thisSegment = CoinYour.getWordID(self.id).toString();
          case "${NUMBER_OF_EDITIONS}":
            // set edition number to infinite (a lemniscate)
            thisSegment = CoinYour.projectList[CoinYour.getProjectID(self.id)]!.prices.length == 0
              ? "\u{221E}"
              : CoinYour.projectList[CoinYour.getProjectID(self.id)]!.prices.length.toString()
          case "${EDITION_NUMBER}":
          thisSegment = CoinYour.getEditionID(self.id).toString()
          case "${PROJECT_NUMBER}":
            thisSegment = CoinYour.getProjectID(self.id).toString();
          case "${FULL_WORD_ID}":
            thisSegment = "0x".concat(String.encodeHex(self.data.wordEditionID.toBigEndianBytes()));
          case "${PROJECT_NAME}":
            thisSegment = CoinYour.projectList[CoinYour.getProjectID(self.id)]!.name;
          case "${PROJECT_DESCRIPTION}":
            thisSegment = CoinYour.projectList[CoinYour.getProjectID(self.id)]!.description;
          case "${PROJECT_WEBSITE}":
            thisSegment = CoinYour.projectList[CoinYour.getProjectID(self.id)]!.website;
          case "${DIRECT_LINK_TO_WORD}":
            thisSegment = CoinYour.projectList[CoinYour.getProjectID(self.id)]!.website.concat(CoinYour.getWordID(self.id).toString());
          case "${DIRECT_LINK_TO_TOKEN}": // Provides a link in the format <PROJECT_WEBSITE>/<WORD_NUMBER>/<EDITION_NUMBER>
            thisSegment = CoinYour.projectList[CoinYour.getProjectID(self.id)]!.website.concat(CoinYour.getWordID(self.id).toString()).concat("/").concat(CoinYour.getEditionID(self.id).toString());
          default:
            thisSegment = current;
        }

        _result = _result.concat(thisSegment);
      }

      return _result;
    }
  
    pub fun getViews(): [Type] {
      return [
        Type<MetadataViews.Display>()
      ]
    }

    //return information dependent on the view the caller is looking for, implements standards from metadata contract
    pub fun resolveView(_ view: Type): AnyStruct? {
      var name = self.generateFromTemplate(template: CoinYour.projectList[CoinYour.getProjectID(self.id)]!.nftNameTemplate);
      var description = self.generateFromTemplate(template: CoinYour.projectList[CoinYour.getProjectID(self.id)]!.nftDescriptionTemplate);

      //uses metadataviews contract to define what information to provide
      switch view {
        case Type<MetadataViews.Display>():
          return MetadataViews.Display(
            name: name,
            description: description,
            thumbnail: self.data.image,
          );
      }

      return nil
    }
  }

  pub resource interface ConstitutionWordsCollectionPublic {
    pub fun deposit(token: @NonFungibleToken.NFT)
    pub fun getIDs(): [UInt64]
    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
    pub fun borrowConstitutionWord(id: UInt64): &NFT?
  }

  pub resource interface Provider {
    pub fun withdraw(withdrawID: UInt64): @NFT
  }

  pub resource interface Receiver {
    pub fun deposit(token: @NFT)
  }

  pub resource Collection: ConstitutionWordsCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
    pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

    pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
      let token <- self.ownedNFTs.remove(key: withdrawID) 
        ?? panic("Could not withdraw NFT: NFT does not exist in collection")

      // I think that emit here is important, as it will allow us to see if anyone has bought / transfered a WordNFT
      emit Withdraw(id: withdrawID, from: self.owner?.address)
      return <-token
    }

    pub fun deposit(token: @NonFungibleToken.NFT) {
      let oldToken <- self.ownedNFTs[token.id] <- token
      destroy oldToken
    }

    pub fun getIDs(): [UInt64] {
      return self.ownedNFTs.keys
    }

    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
      return &self.ownedNFTs[id] as &NonFungibleToken.NFT
    }

    pub fun borrowConstitutionWord(id: UInt64): &CoinYour.NFT? {
      if self.ownedNFTs[id] != nil {
        let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
        return ref as! &CoinYour.NFT
      } else {
        return nil
      }
    }

    destroy() {
      destroy self.ownedNFTs
    }

    init() {
      self.ownedNFTs <- {}
    }
  }

  pub fun createEmptyCollection(): @Collection {
    return <-create self.Collection()
  }

  // returns all words that have been minted on a proiect
  pub fun getMintedWords(projectID: UInt64): [WordEdition] {
    let _r: [WordEdition] = [];

    for mintedWord in self.allMintedWords.values {
      if projectID == CoinYour.getProjectID(mintedWord.wordEditionID) {
        _r.append(mintedWord)
      }
    }

    return _r
  }

  // returns a specific word and its metadata from ID
  // Make sure wordID is a number that starts from 0, not 1 as it will be directly used to look up the word in the array!
  pub fun queryByWord(projectID: UInt64, wordID: UInt64): [WordEdition] {
    let _r: [WordEdition] = [];

    for mintedWord in self.allMintedWords.values {
      if (projectID == CoinYour.getProjectID(mintedWord.wordEditionID)) && (wordID == CoinYour.getWordID(mintedWord.wordEditionID)) {
        _r.append(mintedWord)
      }
    }

    return _r
  }

  // returns all words that have been minted by an author on a proiect
  pub fun getWordsByAuthorAndProject(projectID: UInt64, author: Address): [WordEdition] {
    let _r: [WordEdition] = [];

    for mintedWord in self.allMintedWords.values {
      if projectID == CoinYour.getProjectID(mintedWord.wordEditionID) && author == mintedWord.author {
        _r.append(mintedWord)
      }
    }

    return _r
  }

  // returns all words that have been minted by an author across all projects
  pub fun getAllWordsByAuthor(author: Address): [WordEdition] {
    let _r: [WordEdition] = [];

    for mintedWord in self.allMintedWords.values {
      if author == mintedWord.author {
        _r.append(mintedWord)
      }
    }

    return _r
  }
  
  pub fun mintNFT(wordEditionID: UInt64, messageToMint: String, author: Address, imageURL: String, paymentVault: @FungibleToken.Vault): @NFT {
    pre {
      //these conditions must be true
      self.projectList[CoinYour.getProjectID(wordEditionID)] != nil : "Could not mint NFT: Project does not exist"
      self.projectList[CoinYour.getProjectID(wordEditionID)]!.active : "Could not mint NFT: Project is currently inactive"
      self.projectList[CoinYour.getProjectID(wordEditionID)]!.words[CoinYour.getWordID(wordEditionID)] != nil : "Could not mint NFT: NFT with given ID does not exist."
      //checks amount in CoinYour vault is at least as much as the set price (in the price array) for that edition of the word, if there is a prices
      (self.projectList[CoinYour.getProjectID(wordEditionID)]!.prices.length == 0 && paymentVault.balance >= self.projectList[CoinYour.getProjectID(wordEditionID)]!.minimumPrice) || (self.projectList[CoinYour.getProjectID(wordEditionID)]!.prices.length > 0 && paymentVault.balance >= self.projectList[CoinYour.getProjectID(wordEditionID)]!.prices[CoinYour.getEditionID(wordEditionID)]) : "Could not mint NFT: payment balance insufficient."
      CoinYour.getEditionID(wordEditionID) > 0 : "Could not mint NFT: Edition out of range."
      self.projectList[CoinYour.getProjectID(wordEditionID)]!.startDate == nil || getCurrentBlock().timestamp > self.projectList[CoinYour.getProjectID(wordEditionID)]!.startDate! : "Could not mint NFT: Project has not started yet."
      self.projectList[CoinYour.getProjectID(wordEditionID)]!.endDate == nil || getCurrentBlock().timestamp < self.projectList[CoinYour.getProjectID(wordEditionID)]!.endDate! : "Could not mint NFT: Project has ended."
    }

    let share = paymentVault.balance / self.projectList[CoinYour.getProjectID(wordEditionID)]!.totalShares;

    //splits payment vault accross receivers accounts (as defined by Admin)
    for key in self.projectList[CoinYour.getProjectID(wordEditionID)]!.receivers.keys {
      let numShares = self.projectList[CoinYour.getProjectID(wordEditionID)]!.receivers[key]!;

      let capability = getAccount(key)
        .getCapability(/public/fusdReceiver)
        .borrow<&FUSD.Vault{FungibleToken.Receiver}>() ?? panic("Could not borrow FUSD.Vault capability");
      
      capability.deposit(from: <- paymentVault.withdraw(amount: share * numShares))
    }
    
    //any remaining funds (rounding errors) depsited on the contract
    if paymentVault.balance > 0.00 {
      getAccount(self.account.address)
        .getCapability(/public/fusdReceiver)
        .borrow<&FUSD.Vault{FungibleToken.Receiver}>()!
        .deposit(from: <- paymentVault.withdraw(amount: paymentVault.balance));
    }

    destroy paymentVault;


    let minted = WordEdition(
      wordEditionID: wordEditionID,
      word: self.projectList[CoinYour.getProjectID(wordEditionID)]!.words[CoinYour.getWordID(wordEditionID)],
      message: messageToMint,
      author: author,
      imageURL: imageURL,
    );

    //adds newly minted word to the contract dictionary
    self.allMintedWords[wordEditionID] = minted
    self.totalSupply = self.totalSupply + 1
    emit Deposit(id: wordEditionID, to: author)
    return <- create NFT(id: wordEditionID, data: minted);
  }

  //administrative functions
//?? why can't anyone run these functions?
  pub resource Admin {
    pub fun registerProject(
      id: UInt64,
      name: String,
      description: String,
      website: String,
      active: Bool,
      minimumPrice: UFix64?,
      startDate: UFix64?,
      endDate: UFix64?,
      words: [String],
      prices: [UFix64],
      nftNameTemplate: [String],
      nftDescriptionTemplate: [String],
      receivers: {Address: UFix64},
      metadata: {String: AnyStruct}
    ) {
      pre {
        CoinYour.projectList[id] == nil : "Could not register project: Project already exists"
        website.slice(from: 0, upTo: 7) == "http://" || website.slice(from: 0, upTo: 8) == "https://" : "Could not register project: Website must start with http:// or https://"
        website.slice(from: website.length - 1, upTo: website.length) == "/" : "Could not register project: Website must end with a slash"
      }

      let projectData = CoinYour.ProjectData(
        name: name,
        description: description,
        website: website,
        active: active,
        minimumPrice: minimumPrice ?? 0.0,
        startDate: startDate,
        endDate: endDate,
        words: words,
        prices: prices,
        nftNameTemplate: nftNameTemplate,
        nftDescriptionTemplate: nftDescriptionTemplate,
        receivers: receivers,
        metadata: metadata,
      );

      projectData.calculateTotalShares();

      CoinYour.projectList[id] = projectData;
    }

    pub fun updateProject(
      projectID: UInt64,
      name: String?,
      description:String?,
      website: String?,
      active: Bool?,
      minimumPrice: UFix64?,
      startDate: UFix64?,
      endDate: UFix64?,
      words: [String]?,
      prices: [UFix64]?,
      nftNameTemplate: [String]?,
      nftDescriptionTemplate: [String]?,
      receivers: {Address: UFix64}?,
      metadata: {String: AnyStruct}?,
    ) {
      pre {
        CoinYour.projectList[projectID] != nil : "Could not update project: project does not exist."
        website != nil : "Could not update project: website cannot be unset."
        website!.slice(from: 0, upTo: 7) == "http://" || website!.slice(from: 0, upTo: 8) == "https://" : "Could not register project: Website must start with http:// or https://"
        website!.slice(from: website!.length - 1, upTo: website!.length) == "/" : "Could not register project: Website must end with a slash"
        words == nil || CoinYour.projectList[projectID]!.startDate == nil || getCurrentBlock().timestamp < CoinYour.projectList[projectID]!.startDate! : "Could not update words list: Project is currently active."
        prices == nil || CoinYour.projectList[projectID]!.endDate == nil || getCurrentBlock().timestamp < CoinYour.projectList[projectID]!.endDate! : "Could not update prices: Project is no longer active."
        (startDate != nil && endDate != nil) && startDate! < endDate! : "Could not update project: Start date must be before end date."
      }

      let projectData = CoinYour.ProjectData(
        name: name ?? CoinYour.projectList[projectID]!.name,
        description: description ?? CoinYour.projectList[projectID]!.description,
        website: website ?? CoinYour.projectList[projectID]!.website,
        active: active ?? CoinYour.projectList[projectID]!.active,
        minimumPrice: minimumPrice ?? CoinYour.projectList[projectID]!.minimumPrice,
        startDate: startDate ?? CoinYour.projectList[projectID]!.startDate,
        endDate: endDate ?? CoinYour.projectList[projectID]!.endDate,
        words: words ?? CoinYour.projectList[projectID]!.words,
        prices: prices ?? CoinYour.projectList[projectID]!.prices,
        nftNameTemplate: nftNameTemplate ?? CoinYour.projectList[projectID]!.nftNameTemplate,
        nftDescriptionTemplate: nftDescriptionTemplate ?? CoinYour.projectList[projectID]!.nftDescriptionTemplate,
        receivers: receivers ?? CoinYour.projectList[projectID]!.receivers,
        metadata: metadata ?? CoinYour.projectList[projectID]!.metadata,
      )

      projectData.calculateTotalShares();

      CoinYour.projectList[projectID] = projectData;
    }

    pub fun setReceiver(projectID: UInt64, account: Address, share: UFix64) {
      pre {
        share > 0.0 : "Share must be non-negative"
      }
      
      let projectData = CoinYour.projectList[projectID]!;
      projectData.receivers[account] = share;
      projectData.calculateTotalShares();

      CoinYour.projectList[projectID] = projectData;
    }

    pub fun removeReceiver(projectID: UInt64, account: Address) {
      pre {
        CoinYour.projectList[projectID]!.receivers.keys.contains(account) : "Receiver cannot be removed; they are not registered."
      }

      let projectData = CoinYour.projectList[projectID]!;
      projectData.receivers.remove(key: account);
      projectData.calculateTotalShares();

      CoinYour.projectList[projectID] = projectData;
    }
  }

  pub fun getProjects(): {UInt64: CoinYour.ProjectData} {
    return CoinYour.projectList;
  }

  pub fun getPrices(projectID: UInt64): [UFix64] {
    return CoinYour.projectList[projectID]!.prices;
  }

  pub fun getWords(projectID: UInt64): [String] {
    return CoinYour.projectList[projectID]!.words;
  }

  init() {
    self.totalSupply = 0;
    self.CollectionStoragePath = /storage/CoinYourCollection
    self.CollectionPublicPath = /public/CoinYourCollectionPublic
    self.AdminStoragePath = /storage/CoinYourAdmin
    self.allMintedWords = {}
    self.projectList = {}

    if(self.account.borrow<&Admin>(from: self.AdminStoragePath) != nil) {
      return
    }
    self.account.save<@Admin>(<- create Admin(), to: self.AdminStoragePath)

    if(self.account.borrow<&FUSD.Vault>(from: /storage/fusdVault) != nil) {
      return
    }
    self.account.save(<-FUSD.createEmptyVault(), to: /storage/fusdVault)
    self.account.link<&FUSD.Vault{FungibleToken.Receiver}>(
      /public/fusdReceiver,
      target: /storage/fusdVault
    )
    self.account.link<&FUSD.Vault{FungibleToken.Balance}>(
      /public/fusdBalance,
      target: /storage/fusdVault
    )

    emit ContractInitialized()
  }
}