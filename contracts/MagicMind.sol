// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ECDSA.sol";
import "./IERC2981.sol";

contract MagicMind is Ownable, IERC2981, ERC721 {
    
    bool private _onlyMagicList;
    bool private _mintingEnabled;

    uint private EIP2981RoyaltyPercent;

    mapping (address => uint8) private amountMinted;

    constructor(
        uint _royalty, 
        address _openseaProxyRegistry,
        string memory _tempBaseURI
    ) ERC721(_openseaProxyRegistry, _tempBaseURI) {
        EIP2981RoyaltyPercent = _royalty;
    }
    
    function mintFromReserve(uint amount, address to) external onlyOwner {
        require(amount + totalSupply <= 500);
        _mint(amount, to);
    }

    function mint(uint256 amount) external payable {
        require(_mintingEnabled, "Minting is not enabled!");
        require(amount <= 20 && amount != 0, "Invalid request amount!");
        require(amount + totalSupply <= 10_000, "Request exceeds max supply!");
        require(msg.value == amount * 89e15, "ETH Amount is not correct!");

        _mint(amount, msg.sender);
    }

    function preMint(bytes calldata sig, uint256 amount) external payable {
        require(_onlyMagicList, "Minting is not enabled!");
        require(_checkSig(msg.sender, sig), "User not whitelisted!");
        require(amount + amountMinted[msg.sender] <= 10 && amount != 0, "Request exceeds max per wallet!");
        require(msg.value == amount * 69e15, "ETH Amount is not correct!");

        amountMinted[msg.sender] += uint8(amount);
        _mint(amount, msg.sender);
    }

    function _checkSig(address _wallet, bytes memory _signature) private view returns(bool) {
        return ECDSA.recover(
            ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_wallet))),
            _signature
        ) == owner();
    }

    function getMsg(address _wallet) external pure returns(bytes32) {
        return keccak256(abi.encodePacked(_wallet));
    }

    /**
     * @notice returns pre sale satus 
     */
    function isPresale() external view returns(bool) {
        return _onlyMagicList;
    }

    /**
     * @notice returns public sale status
     */
    function isMinting() external view returns(bool) {
        return _mintingEnabled;
    }

    /**
     * @notice returns royalty info for EIP2981 supporting marketplaces
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint tokenId, uint salePrice) external view returns(address receiver, uint256 royaltyAmount) {
        require(_exists(tokenId), "Royality querry for non-existant token!");
        return(owner(), salePrice * EIP2981RoyaltyPercent / 10000);
    }

    /**
     * @notice sets the royalty percentage for EIP2981 supporting marketplaces
     * @dev percentage is in bassis points (parts per 10,000).
            Example: 5% = 500, 0.5% = 50 
     * @param amount - percent amount
     */
    function setRoyaltyPercent(uint256 amount) external onlyOwner {
        EIP2981RoyaltyPercent = amount; 
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function withdraw() onlyOwner external {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @notice toggles pre sale
     * @dev enables the pre sale functions. NEVER USE THIS AFTER ENABLING THE PUBLIC SALE FUNCTIONS UNLESS ITS NECESSARY
     */
    function togglePresale() external onlyOwner {
        _onlyMagicList = !_onlyMagicList;
    }

    /**
     * @notice toggles the public sale
     * @dev enables/disables public sale functions and disables pre sale functions
     */
    function togglePublicSale() external onlyOwner {
        _onlyMagicList = false;
        _mintingEnabled = !_mintingEnabled;
    }

    function tokensOfOwner(address owner) external view returns(uint[] memory) {
        uint[] memory tokens = new uint[](_balances[owner]);
        uint y = totalSupply + 1;
        uint x;

        for (uint i = 1; i < y; i++) {
            if (ownerOf(i) == owner) {
                tokens[x] = i;
                x++;
            }
        }

        return tokens;
    }
}
