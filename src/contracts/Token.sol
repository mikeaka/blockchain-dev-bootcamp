pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Token {
	using SafeMath for uint;

	//Variables
	string public name = "AkaNzore Token";
	string public symbol = "AKAN";
	uint256 public decimals = 18;
	uint256 public totalSupply;
	// Track Balances
	// Mapping (key  / pair) address (account in blockchain) => to token balance
	mapping(address => uint256) public balanceOf;

	// --------------define Events
	// indexed allow to filter on it later
	event Transfer(address indexed from, address indexed to, uint256 value);

	constructor() public {
		totalSupply = 1000000 * (10 ** decimals);
		// msg.sender represent the person that deploy the smart contract
		// in ganache it will be the first account
		balanceOf[msg.sender] = totalSupply;
	}

	function transfer(address _to, uint256 _value) public returns (bool success) {
		// Check valid address recipient
		require(_to != address(0));
		
		//need to be true to continue execute the code
		require(balanceOf[msg.sender] >= _value);

		//msg.sender is the one that call the function that decrease is balance because he send 
		balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);

		// increase the receiver balance
		balanceOf[_to] = balanceOf[_to].add(_value);

		// Call Event
		emit Transfer(msg.sender, _to, _value);

		return true;
	}
}
