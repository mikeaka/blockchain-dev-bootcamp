const Token = artifacts.require('./Token')

require('chai')
	.use(require('chai-as-promised'))
	.should()

contract('Token', (accounts) => {
	const name = 'AkaNzore Token'
	const symbol = 'AKAN'
	const decimals = '18'
	const totalSupply = '1000000000000000000000000'

	//declare token
	let token
	// Fetch token from blockchain / deployed to blockchain
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
			result.toString().should.equal(totalSupply)			
		})
	})
})