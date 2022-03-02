export const EVM_REVERT = 'VM Exception while processing transaction: revert'

// n = number of token
export const tokens = (n) => {
	return new web3.utils.BN(
		web3.utils.toWei(n.toString(), 'ether')
	)
}