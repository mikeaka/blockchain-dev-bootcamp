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
// [X] Make order
// [X] Cancel order
// [] Fill order
// [] Charge fees

contract Exchange {
	using SafeMath for uint;

	//Variables
	address public feeAccount; //Account that will receive exchange fees
	uint256 public feePercent; // the fee percentage
	address constant ETHER = address(0); //store Ether in tokens mapping with blank address
	uint256 public orderCount;

	// mapping(tokenAddress (all tokens that has been deposit) => mapping(address of the user that has deposit the token itself => uint256 is the balance)) public tokens;
	// token based mapping, foreach token we have a mapping telling the address of the user and the balance
	mapping(address => mapping(address => uint256)) public tokens;

	// store the order on the blockchain
	// uint256 will be the ID and the value will be _Order struct
	mapping(uint256 => _Order) public orders;

	mapping(uint256 => bool) public orderCancelled;

	// Events
	event Deposit(address token, address user, uint256 amount, uint256 balance);
	event Withdrawn(address token, address user, uint256 amount, uint256 balance);
	event Order(		
		uint256 id,
		address user, // person who create the order
		address tokenGet, // token the user want to purchase
		uint256 amountGet, // amount the user want to purchase
		address tokenGive, // token the will use during the trade
		uint256 amountGive, // the amount the user want to give
		uint256 timestamp
	);
	event Cancel(		
		uint256 id,
		address user, // person who create the order
		address tokenGet, // token the user want to purchase
		uint256 amountGet, // amount the user want to purchase
		address tokenGive, // token the will use during the trade
		uint256 amountGive, // the amount the user want to give
		uint256 timestamp
	);	

	// ---- order
	// a way to model the order
	struct _Order {
		uint256 id;
		address user; // person who create the order
		address tokenGet; // token the user want to purchase
		uint256 amountGet; // amount the user want to purchase
		address tokenGive; // token the will use during the trade
		uint256 amountGive; // the amount the user want to give
		uint256 timestamp;
	}

	// a way to store the order
	// doing by mapping

	// add the order to storage / retreive the storage
	// by using a function makeOrder


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

	function withdrawEther(uint256 _amount) public {
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

	function makeOrder(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive) public {
		orderCount = orderCount.add(1);
		// msg.sender = user from the order struct //
		orders[orderCount] = _Order(orderCount, msg.sender, _tokenGet, _amountGet, _tokenGive, _amountGive, now);
		emit Order(orderCount, msg.sender, _tokenGet, _amountGet, _tokenGive, _amountGive, now);
	}

	function cancelOrder (uint256 _id) public {
		// fetch order from mapping
		_Order storage _order = orders[_id];

		// Must be my order
		require(address(_order.user) == msg.sender);

		// Must be a valid Order
		require(_order.id == _id);

		orderCancelled[_id] = true;
		emit Cancel(orderCount, msg.sender, _order.tokenGet, _order.amountGet, _order.tokenGive, _order.amountGive, now);
	}

}