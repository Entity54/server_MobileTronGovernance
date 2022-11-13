// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Treasury {
    address public admin;
    address public govAdmin;
    string public name;

    modifier onlyAdmin() {
        require(msg.sender == admin, "action only for admin");
        _;
    }

    modifier onlyGovAdmin() {
        require(msg.sender == govAdmin, "action only for govAdmin");
        _;
    }

    event Received(address, uint256);

    constructor(address _admin, string memory _name) {
        admin = _admin;
        govAdmin = msg.sender;
        name = _name;
    }

    function sendTransfer(address receiver, uint256 amount)
        external
        payable
        onlyGovAdmin
    {
        payable(receiver).transfer(amount);
    }

    function getBalanceSC() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawSC() public onlyAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
