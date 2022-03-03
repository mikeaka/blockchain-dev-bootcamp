pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Token {
	using SafeMath for uint;

	//Variables
	string public name = "AkaNzore Token";
	string public symbol = "AKAN";
	uint256 public decimals = 18;
	uint256 public totalSupply;
	// ------------- Track Balances
	// Mapping (key  / pair) address (account in blockchain) => to token balance
	mapping(address => uint256) public balanceOf;
	// -------------
	// First address is the person that will approuve the token
	// allowance keep track of allowance allow for the exchange to spend
	// second mapping is for the exchange, we can have exchange 1, exchange 2, exchange 3 
	// ... and address is the address of the exchange and unit256 is the amount allowed to spend
	mapping(address => mapping(address => uint256)) public allowance;

	// --------------define Events
	// indexed allow to filter on it later
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);


	constructor() public {
		totalSupply = 1000000 * (10 ** decimals);
		// msg.sender represent the person that deploy the smart contract
		// in ganache it will be the first account
		balanceOf[msg.sender] = totalSupply;
	}

	function transfer(address _to, uint256 _value) public returns (bool success) {
		//msg.sender is the one that call the function 
		//need to be true to continue execute the code
		require(balanceOf[msg.sender] >= _value);
		_transfer(msg.sender, _to, _value);

		return true;
	}

	function _transfer(address _from, address _to, uint256 _value) internal {
		// Check valid address recipient
		require(_to != address(0));
		//msg.sender is the one that call the function that decrease is balance because he send 
		balanceOf[_from] = balanceOf[_from].sub(_value);
		// increase the receiver balance
		balanceOf[_to] = balanceOf[_to].add(_value);
		// Call Event
		emit Transfer(_from, _to, _value);

	}

	// Approve Token (allow someone else to spend token)
	// approve amount that will be added to allowance
	function approve(address _spender, uint256 _value) public returns (bool success) {
		require(_spender != address(0));
		allowance[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}
	
	//transfer from
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(_value <= balanceOf[_from]);
		//value inferieur ou egal a ce qui a ete approuve. From is the exchange
		require(_value <= allowance[_from][msg.sender]);
		allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
		_transfer(_from, _to, _value);
		return true;
	}


}
