pragma solidity ^0.5.0;

import "./Token.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

//Deposit and withdraw funds
// manage orders - make orders or cancel
// handle Trades - charge fees

// TODO
// [X] Set the fee account
// [X] Deposit Ether
// [X] Withdraw Ether
// [X] Deposit tokens
// [X] Withdraw tokens
// [X] Check balances
// [] Make order
// [] Cancel order
// [] Fill order
// [] Charge fees

contract Exchange {
	using SafeMath for uint;

	//Variables
	address public feeAccount; //Account that will receive exchange fees
	uint256 public feePercent; // the fee percentage
	address constant ETHER = address(0); //store Ether in tokens mapping with blank address
	
	// mapping(tokenAddress (all tokens that has been deposit) => mapping(address of the user that has deposit the token itself => uint256 is the balance)) public tokens;
	// token based mapping, foreach token we have a mapping telling the address of the user and the balance
	mapping(address => mapping(address => uint256)) public tokens;

	// Events
	event Deposit(address token, address user, uint256 amount, uint256 balance);
	event Withdrawn(address token, address user, uint256 amount, uint256 balance);

	constructor(address _feeAccount, uint256 _feePercent) public {
		feeAccount = _feeAccount;
		feePercent = _feePercent;
	}

	// Fallback: revert if Ether is sent to this smart contract by mistake
	function() external {
		revert();
	}

	function depositEther() payable public {
		tokens[ETHER][msg.sender] = tokens[ETHER][msg.sender].add(msg.value);
		// Emit event
		emit Deposit(ETHER, msg.sender, msg.value, tokens[ETHER][msg.sender]);
	}

	function withdrawEther(uint _amount) public {
		require(tokens[ETHER][msg.sender] >= _amount);
		tokens[ETHER][msg.sender] = tokens[ETHER][msg.sender].sub(_amount);
		msg.sender.transfer(_amount);
		emit Withdrawn(ETHER, msg.sender, _amount, tokens[ETHER][msg.sender]);
	}

	function depositToken(address _token, uint256 _amount) public {
		// Which token - (address _token)
		// how much - (uint256 _amount)

		// don't allow Ether deposits
		require(_token != ETHER);

		// ---------- send tokens to this contracts (Exchange)
		// access to the token to get function
		// 'this' represent this smart contract (Exchange)
		// it will move tokens to the smart contract itself
		require(Token(_token).transferFrom(msg.sender, address(this), _amount));

		// deposit tokens
		tokens[_token][msg.sender] = tokens[_token][msg.sender].add(_amount);
		// ------ manage deposit


		// Emit event
		emit Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);

	}

	function withdrawToken(address _token, uint256 _amount) public {
		require(_token != ETHER);
		require(tokens[_token][msg.sender] >= _amount);
		tokens[_token][msg.sender] = tokens[_token][msg.sender].sub(_amount);
		require(Token(_token).transfer(msg.sender, _amount));
		emit Withdrawn(_token, msg.sender, _amount, tokens[_token][msg.sender]);
	}

	function balanceOf(address _token, address _user) public view returns (uint256) {
		return tokens[_token][_user];
	}
}