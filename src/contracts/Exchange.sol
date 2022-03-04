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
	mapping(uint256 => bool) public orderFilled;

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
	event Trade(		
		uint256 id,
		address user, // person who create the order
		address tokenGet, // token the user want to purchase
		uint256 amountGet, // amount the user want to purchase
		address tokenGive, // token the will use during the trade
		uint256 amountGive, // the amount the user want to give
		address userFill, // User that fill the order
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

	function fillOrder(uint256 _id) public {
		require(_id > 0 && _id <= orderCount);
		// require that the id is NOT in orderfilled or orderCancelled
		require(!orderFilled[_id]);
		require(!orderCancelled[_id]);

		// fetch the Order (type _Order)
		_Order storage _order = orders[_id];

		_trade(_order.id, _order.user, _order.tokenGet, _order.amountGet, _order.tokenGive, _order.amountGive);

		// Mark order as filled
		orderFilled[_order.id] = true;
	}

	function _trade(uint256 _orderId, address _user, address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive) internal {
		// ------ trade will swap balances

		// Fee paid by the user that fills the order, a.k.a msg.sender
		// fee will be deducted from _amountGet
		uint256 _feeAmount = _amountGet.mul(feePercent).div(100);

		// Execute trade
		// -------- send tokenGet from 1 to 2
		// msg.sender is the user that fill the order
		// _user is the one that create the order
		tokens[_tokenGet][msg.sender] = tokens[_tokenGet][msg.sender].sub(_amountGet.add(_feeAmount));
		// _user is the address that will receive the amountGet
		tokens[_tokenGet][_user] = tokens[_tokenGet][_user].add(_amountGet);

		// Pay fees
		tokens[_tokenGet][feeAccount] = tokens[_tokenGet][feeAccount].add(_feeAmount);

		// receive token from 2 to 1
		tokens[_tokenGive][_user] = tokens[_tokenGive][_user].sub(_amountGive);
		tokens[_tokenGive][msg.sender] = tokens[_tokenGive][msg.sender].add(_amountGive);

		// charge fees
		// Emit trade event
		emit Trade(_orderId, _user, _tokenGet, _amountGet, _tokenGive, _amountGive, msg.sender, now);
	}

}