pragma solidity ^0.6.6;

//import "./Context.sol";
//import "./IERC721Metadata.sol";
import "./IERC721.sol";
//import "./IERC721Enumerable.sol";
//import "./IERC721Receiver.sol";
import "./ERC165.sol";
import "./SafeMath.sol";
//import "./Address.sol";
//import "./EnumerableSet.sol";
//import "./EnumerableMap.sol";
//import "./strings.sol";
//import "./initializable.sol";
import "./IERC165.sol";



abstract contract ERC721 is IERC165, IERC721, ERC165UpgradeSafe
{
    using SafeMath for uint256;
    
    string public _name;
    string public _symbol;
    string public _baseURI;
    uint256 totalsupply;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    
    
    
    constructor(string memory name, string memory symbol) public
    {
        _name = name;
        _symbol =  symbol;
        _registerInterface(_INTERFACE_ID_ERC721);
        //_registerInterface(_INTERFACE_ID_ERC721_METADATA);
        //_registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }
    //mapping from address to ownedTokens
    mapping (address => uint256[])public ownedTokens;
    mapping (uint256 => address) public tokenOwner;
    // Mapping from token ID to index of the owner tokens list 
    mapping(uint256 => uint256) public ownedTokensIndex; 
    //Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) public allTokensIndex;
    //how many tokens we actually own
    mapping (address => uint256) public ownedTokensCount;
    //mapping fromm tokenid to approvedtokens
    mapping(uint256 => address) public approvedTokens;
     //mapping for holding index of token in owner 
    mapping(address => mapping(uint256 => uint256)) private _ownerTokenIndex;
    mapping (address => mapping (address => bool)) public operatorApprovals;
    
    mapping(uint256 => string) private _tokenURIs;
    
    //event Approval(address, address, uint256);
    
    function balanceOf(address owner) public view override returns (uint256) {}
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {}

    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
      function totalSupply() public view returns(uint256)
    {
        return totalsupply;
    }
   
    function balancOf(address owner) public view returns(uint256)
    {
        require(owner != address(0),"invalid address");
        return(ownedTokens[owner].length);
    }
      uint256 public tokenIdCounter;
    function registerProperty(string memory plotno) public {
        
        tokenIdCounter = tokenIdCounter.add(1);
        mint(msg.sender,tokenIdCounter);
        _setTokenURI(tokenIdCounter,plotno);
    }
    
     function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    function ownerOf(uint256 tokenId) public view override returns(address)
    {
        address owner = tokenOwner[tokenId];
        require(owner != address(0), "token does not exist");

        return owner;
    }
     
    
    function tokenOwnerByIndex(uint256 tokenIndex, address owner) public view returns(uint256)
    {
        return ownedTokens[owner][tokenIndex];
    }
    
    function tokenByIndex(uint256 index) public view returns(uint256)
    {
        return ownedTokensIndex[index];
    }
     //sets the approval for the operator
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "caller should be other than owner");

        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    //checks whether the operator is approved or not
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return operatorApprovals[owner][operator];
    }
    //checks approval conditions for a particular tokenId and then callls _approve
    function approve(address to, uint256 tokenId)public override
    {
        address owner = ownerOf(tokenId);
        require(to != owner,"to field is owner");
        require(msg.sender == owner || isApprovedForAll(msg.sender, to), "not approved for all");
        _approve(to, tokenId);
        
    }
    //assigns the approved address to the mapping
    function _approve(address to, uint256 tokenId) private 
    {
        approvedTokens[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }
  
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override 
    {
         require(msg.sender == ownerOf(tokenId) || (isApprovedForAll(from,to)),"not approved");
        safeTransferFrom(from, to, tokenId);
    }
   function exists(uint256 tokenId) internal view returns (bool) {
        require(tokenId > 0,"ERC721: Token does not exist");
        address owner = tokenOwner[tokenId];
        
        if(owner != address(0))
            return true;
        else
            return false;
    }
      function mint(address to, uint256 tokenId) public virtual {
        require(to != address(0), "mint to the zero address is not allowed");
        require(!exists(tokenId), "token already minted");


        ownedTokens[to].push(tokenId);

        emit Transfer(address(0), to, tokenId);

}
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);


        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
        totalsupply = totalsupply.sub(1);
        
        //state update on token delete
        _deleteToken(owner,tokenId);

        emit Transfer(owner, address(0), tokenId);
    }
function _deleteToken(address owner, uint tokenId) internal virtual returns(bool success, uint256 index){
        require(exists(tokenId),"Token does not exist");
        require(tokenOwner[tokenId] == owner," Token is not owned by owner");
        
        index = _ownerTokenIndex[owner][tokenId];
        
        //more than one token swap last entry to current index
        if(ownedTokens[owner].length>1){
            uint lastToken = ownedTokens[owner][ownedTokens[owner].length-1];   
            ownedTokens[owner][index] = lastToken;
            _ownerTokenIndex[owner][lastToken] = index;
        }
        //remove last entry
        ownedTokens[owner].pop();
        //remove Index
        delete _ownerTokenIndex[owner][tokenId];
        //remove owner
        delete tokenOwner[tokenId];
        success = true;
    }
}
