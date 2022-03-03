import { ether, tokens, EVM_REVERT, ETHER_ADDRESS } from './helpers'

const Token = artifacts.require('./Token')
const Exchange = artifacts.require('./Exchange')

require('chai')
	.use(require('chai-as-promised'))
	.should()

contract('Exchange', ([deployer, feeAccount, user1 ]) => {
	let token
	let exchange
	const feePercent = 10

	beforeEach(async () => {
		// Deploy token
		token = await Token.new();

		// transfer some tokens to user1
		await token.transfer(user1, tokens(100), { from: deployer })

		// Deploy Exchange
		exchange = await Exchange.new(feeAccount, feePercent);
	})

	describe('deployment', () => {
		it('tracks the fee Account', async () => {
			const result = await exchange.feeAccount()
			result.should.equal(feeAccount)
		})
		it('tracks the fee Percent', async () => {
			const result = await exchange.feePercent()
			result.toString().should.equal(feePercent.toString())
		})
		
	})

	describe('fallback', async () => {
		it('revert when Ether is sent', async () => {
			await exchange.sendTransaction( { value: 1, from: user1 } ).should.be.rejectedWith(EVM_REVERT)
		})
	})

	describe('depositing Ether', async () => {
		let result
		let amount

		beforeEach(async ()=> {
			amount = ether(1)
			result = await exchange.depositEther({ from: user1, value: amount })
		})
		describe('success', async () => {
			it('track ether deposit', async () => {
				const balance = await exchange.tokens(ETHER_ADDRESS, user1)
				balance.toString().should.equal(amount.toString())
			})
			it('Emit Ether deposit event', async () => {
				const log = result.logs[0]
				log.event.should.eq('Deposit')
				const event = log.args
				event.token.toString().should.equal(ETHER_ADDRESS, 'token is correct')
				event.user.toString().should.equal(user1, 'user is correct')
				event.amount.toString().should.equal(amount.toString(), 'amount is correct')
				event.balance.toString().should.equal(amount.toString(), 'balance is correct')
			})
			
		})
		describe('failure', async () => {
			
		})
	})

	describe('depositing tokens', () => {
		let result
		let amount

		describe('success', ()=> {
			beforeEach(async () => {
				amount = tokens(10)
				await token.approve(exchange.address, amount, { from: user1 })
				result = await exchange.depositToken(token.address, amount, { from: user1 })
			})			
			
			it('track token deposit', async () => {
				let balance
				balance = await token.balanceOf(exchange.address)
				balance.toString().should.equal(amount.toString())

				// check tokens on exchange
				balance = await exchange.tokens(token.address, user1)
				balance.toString().should.equal(amount.toString())
			})
			it('Emit deposit event', async () => {
				const log = result.logs[0]
				log.event.should.eq('Deposit')
				const event = log.args
				event.token.toString().should.equal(token.address, 'token is correct')
				event.user.toString().should.equal(user1, 'user is correct')
				event.amount.toString().should.equal(amount.toString(), 'amount is correct')
				event.balance.toString().should.equal(amount.toString(), 'balance is correct')
			})
		})
		describe('failure', ()=> {
			it('rejects Ether Deposits', async() => {
				await exchange.depositToken(ETHER_ADDRESS,tokens(10), { from: user1 }).should.be.rejectedWith(EVM_REVERT)
			})
			it('fails when no tokens are appoved', async () => {
				// token has not been approved before depositing
				await exchange.depositToken(token.address, tokens(10), { from: user1 }).should.be.rejectedWith(EVM_REVERT)
			})
		})		
	})

})