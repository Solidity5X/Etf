// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import './ETF.sol';

contract ETFFactory {
    struct etf {
        string name;
        address add;
    }
    mapping(uint256 => etf) idToEtf;
    uint256 currentEtf;
    uint256 MAX_INT = 2**256 - 1;


    /*\
    creates a new ETF.
    requires to mint atleast 1 token.
    \*/
    function createETF(string memory _name, string memory _symbol, address[] memory _tokens, uint256[] memory _amounts) public {
        require(_tokens.length == _amounts.length, "you forgot somethings!");
        address etfAdd = address(new ETF(_name, _symbol, _tokens, _amounts));
        for(uint256 i; i < _tokens.length; i++) {
            require(IERC20(_tokens[i]).transferFrom(msg.sender, address(this), _amounts[i]), "transfer failed!");
            require(IERC20(_tokens[i]).approve(etfAdd, MAX_INT));
        }
        ETF(etfAdd).deposit(1e18);
        require(ETF(etfAdd).transfer(msg.sender, 1e18));
        etf memory toAdd = etf(_name, etfAdd);
        idToEtf[currentEtf] = toAdd;
        currentEtf++;
    }

    /*\
    gets etf info by id.
    \*/
    function getETFInfoById(uint256 _id) external view returns(string memory name, address add, uint256 totalSupply){
        name = idToEtf[_id].name;
        add = idToEtf[_id].add;
        totalSupply = ETF(idToEtf[_id].add).totalSupply();
    }

    /*\
    gets the id of the etf by entering the name.
    different etfs can have the same name so that it returns a array.
    \*/
    function getIdsByName(string memory _name) external view returns(uint256[] memory ids) {
        bytes32 hash = keccak256(abi.encodePacked(_name));
        uint256 count = 0;
        for(uint256 i; i < currentEtf-1; i++) {
            if(keccak256(abi.encodePacked(idToEtf[i].name)) == hash) {
                ids[count] = i;
                count++;
            }
        }
    }


    /*\
    gets id of etfs that user is invested in.
    100k wei is enough to set user as invested
    \*/
    function getInvestedOf(address _add) external view returns(uint256[] memory ids) {
        uint256 count;
        for(uint256 i; i < currentEtf-1; i++) {
            if(ETF(idToEtf[i].add).balanceOf(_add) >= 100000) {
                ids[count] = i;
                count++;
            }
        }
    }
    
    /*\
    gets tokens and amounts by id.
    \*/
    function getTokensAndAmountsById(uint256 _id) external view returns(address[] memory, uint256[] memory) {
        return(ETF(idToEtf[_id].add).getTokens(), ETF(idToEtf[_id].add).getAmounts());
    }


}
