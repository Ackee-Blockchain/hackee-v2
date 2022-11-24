pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./HackeeReceiver.sol";

contract Hackee is ERC20 {

    using Address for address;

    uint256 private password;
    address private owner;
    mapping(address => bool) private hackees;
    mapping(address => bool) private admins;
    mapping(address => bool) private airdrops;
    mapping(address => uint8) private attempts;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admin can call this function");
        _;
    }

    modifier onlyHackee() {
        require(hackees[msg.sender], "You're not a hackee yet");
        _;
    }

    constructor() ERC20("Hackee", "HACKEE") {
        owner = address(this);
        resetPassword();
    }

    function processPayload(bytes memory payload) external {
        address(this).call(payload);
    }

    function addAdmin(address addr) external onlyOwner {
        admins[addr] = true;
    }

    function addHackee(uint256 _password) external returns(bool) {
        increaseAttempts(1);
        return _addHackee(_password);
    }

    function _addHackee(uint256 _password) private returns(bool) {
        if (password == _password){
            resetPassword();
            hackees[msg.sender] = true;
            return true;
        } else {
            return false;
        }
    }

    function increaseAttempts(uint8 count) public {
        unchecked {
            attempts[msg.sender] += count;
        }
        require(attempts[msg.sender] <= 10, "To many attempts");
    }

    function claimAirdrop() external {
        require(airdrops[msg.sender] == false, "Airdrop already claimed");
        _mint(msg.sender, 1000);

        if (msg.sender.isContract()){
            HackeeReceiver(msg.sender).onAirdropReceive();
        }
        airdrops[msg.sender] = true;
    }
    
    function getPoints(address addr) external view returns (uint8){
        uint8 result = 0;

        if (hackees[addr]) {
            result += 2;
            if (attempts[addr] == 1) {
                result += 2;
            } else if (attempts[addr] == 0) {
                result += 4;
            }
        }

        if (balanceOf(addr) > 10000){
            result += 2;
        }

        if (admins[addr]) {
            result += 2;
        }

        return result;
    }

    function resetPassword() private {
        password = (block.timestamp * block.number) % 10000;
    }
}