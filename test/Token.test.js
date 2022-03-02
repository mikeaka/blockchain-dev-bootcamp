import { tokens, EVM_REVERT } from './helpers'

const Token = artifacts.require('./Token')

require('chai')
	.use(require('chai-as-promised'))
	.should()

contract('Token', ([deployer,receiver]) => {
	const name = 'AkaNzore Token'
	const symbol = 'AKAN'
	const decimals = '18'
	const totalSupply = tokens(1000000).toString()

	//declare token
	let token
	// Fetch token from blockchain / deployed to blockchain
	// beforeEach allow deploying token foreach tests
	beforeEach(async () => {
		token = await Token.new();
	})

	describe('deployment', () => {
		it('tracks the name', async () => {
			//Read token name here
			const result = await token.name()
			//The token name is 'My Name'
			result.should.equal(name)
		})
		it('tracks the symbol', async () => {
			const result = await token.symbol()
			result.should.equal(symbol)
		})
		it('tracks the decimals', async () => {
			const result = await token.decimals()
			result.toString().should.equal(decimals)			
		})		
		it('tracks the total supply', async () => {
			const result = await token.totalSupply()
			result.toString().should.equal(totalSupply.toString())
		})
		it('assigns the total supply to the deployer', async () => {
			const result = await token.balanceOf(deployer)
			result.toString().should.equal(totalSupply.toString())
		})
	})

	describe('sending tokens', () => {
		let amount
		let result

		describe('success', async () => {
			beforeEach(async () => {
				amount = tokens(100)
				// -------- Transfer-----------------------
				// transfer have only 2 arguments but we can use javascript metadata to add more
				// from will allow accessing to solidity msg.sender, who use the function to send
				result = await token.transfer(receiver, amount, { from: deployer})
			})

			it('transfer token balances', async () => {
				let balanceOf
				// balance before transfer
				//balanceOf = await token.balanceOf(deployer)
				//console.log("deployer balance before transfer", balanceOf.toString())
				//balanceOf = await token.balanceOf(receiver)
				//console.log("receiver balance before transfer", balanceOf.toString())

				// balance after transfer
				balanceOf = await token.balanceOf(deployer)
				balanceOf.toString().should.equal(tokens(999900).toString())
				balanceOf = await token.balanceOf(receiver)
				balanceOf.toString().should.equal(tokens(100).toString())

			})

			it('Emit Transfer event', async () => {
				//console.log(result.logs)
				const log = result.logs[0]
				log.event.should.equal('Transfer')
				const event = log.args
				event.from.toString().should.equal(deployer, 'From is correct')
				event.to.toString().should.equal(receiver, 'To is correct')
				event.value.toString().should.equal(amount.toString(), 'Value is correct')

			})			

		})

		describe('failure', async () => {
		
			it('rejects insufficient balances', async () => {
				let invalidAmount
				invalidAmount = tokens(100000000) // 100 millions greater than the total supply
				await token.transfer(receiver, invalidAmount, { from: deployer }).should.be.rejectedWith(EVM_REVERT);

				// Attempt to send tokens, when you have none
				invalidAmount = tokens(10) // recipient (receiver) has no tokens
				await token.transfer(deployer, invalidAmount, { from: receiver }).should.be.rejectedWith(EVM_REVERT);
			})

			it('reject invalid recipient', async () => {
				await token.transfer(0x0, amount, { from: deployer }).should.be.rejectedWith;
			})
		})

	})



})