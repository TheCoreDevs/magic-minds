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

    function batchMintFromReserve(uint[] memory amount, address[] memory to) external onlyOwner {
        uint length = amount.length;
        require(length == to.length, "array length missmatch");
        
        uint tokenId = totalSupply;
        uint total;

        uint cAmount;
        address cTo;

        for (uint i; i < length; i++) {

            assembly {
                cAmount := mload(add(add(amount, 0x20), mul(i, 0x20)))
                cTo := mload(add(add(to, 0x20), mul(i, 0x20)))
            }

            require(!Address.isContract(cTo), "Cannot mint to contracts!");

            _balances[cTo] += cAmount;
            
            for (uint f; f < cAmount; f++) {
                tokenId++;

                _owners[tokenId] = cTo;
                emit Transfer(address(0), cTo, tokenId);
            }
            
            total += cAmount;
        }

        require(tokenId <= 500, "Exceeds reserve!");
        
        totalSupply = uint16(total);
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
    function royaltyInfo(uint tokenId, uint salePrice) external view override returns(address receiver, uint256 royaltyAmount) {
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
        uint bal = address(this).balance;
        payable(0x12723aD63dA5D0C9Cfa671Ddf8f208b7eA03C913).transfer(bal * 4 / 10);
        payable(0x14CFCE63790aE8567c83858050273F01684C1540).transfer(bal * 15 / 100);
        payable(msg.sender).transfer(bal * 14 / 100);
        payable(0x5aE9936E3BBbc98b19622d6A73d1003F533f8544).transfer(bal * 7 / 100);
        payable(0x7222b04D739B93e95E48baad5896B30F3105A0Ad).transfer(bal * 4 / 100);
        payable(0xdF09b919392687072AD42eE6986c861751C2559D).transfer(bal * 325 / 10000);
        payable(0xb8258175018a494ca3E241e709e7A1E74Aef8116).transfer(bal * 325 / 10000);
        payable(0x53D0D29b5bABDDB0284624D25aBd0F482a09F81b).transfer(bal * 3 / 100);
        payable(0xE321d503EF3181B2A930876A3098F0d0aB3bCF6E).transfer(bal * 3 / 100);
        payable(0x22722720Df246B776f01e98977d89C103985Eb78).transfer(bal * 3 / 100);
        payable(0x915FD7751dBbD3d4E8b359D5b99486941636c12f).transfer(bal * 25 / 1000);
        payable(0x0876Fd16eC5755CEBE7b2b96B2DFaF490466540c).transfer(bal * 2 / 100);
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
