// import 'dotenv/config'
import {
    defineChain, createWalletClient, http, publicActions, parseEther, formatUnits, parseEventLogs,
    decodeFunctionData
} from 'viem'
import { privateKeyToAccount } from 'viem/accounts'
import tokenArtifact from '../contracts/out/CappedToken.sol/CappedToken.json' with { type: "json" };
import tokenSaleArtifact from '../contracts/out/TokenSale.sol/TokenSale.json' with { type: "json" };

import * as dotenv from 'dotenv'

dotenv.config()

const privateKey = process.env.PK_FOR_ANVIL
const tokenAddress = process.env.VITE_TOKEN as `0x${string}`
const tokenSaleAddress = process.env.VITE_TOKEN_SALE as `0x${string}`
// const tokenAddress = '0x5FbDB2315678afecb367f032d93F642f64180aa3' as `0x${string}`

// const tokenAddress = '0x5FbDB2315678afecb367f032d93F642f64180aa3' as `0x${string}`
// export TOKEN=0x5FbDB2315678afecb367f032d93F642f64180aa3
const anvilChain = defineChain({
    id: 31337,
    name: 'Anvil',
    network: 'anvil',
    nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
    rpcUrls: {
        default: { http: ['http://127.0.0.1:8545'] }
    }
})

const account = privateKeyToAccount(privateKey as `0x${string}`)

console.log("account: ", account)



try {
    const tokenAbi = tokenArtifact.abi
    const abi = tokenSaleArtifact.abi
    console.log("Generated tokenSaleArtifact.abi: ")
    const bytecode = tokenSaleArtifact.bytecode?.object ?? tokenSaleArtifact.deployedBytecode?.object;
    console.log("Generated tokenSaleArtifact.bytecode: ");
    // IIFE
    (async () => {
        try {
            const rpcUrl = process.env.ANVIL_RPC_URL ?? 'http://127.0.0.1:8545';
            console.log('createWalletClient for rpcUrl: ', rpcUrl);
            const client = createWalletClient({
                account,
                chain: anvilChain,
                transport: http(rpcUrl),
            }).extend(publicActions);




            const myAddress = account.address // from privateKeyToAccount

            const balanceBefore = await client.readContract({
                address: tokenAddress,
                abi: tokenAbi,
                functionName: 'balanceOf',
                args: [myAddress],
            }) as bigint


            // Prepare to write to the contract and get the transaction hash
            console.log('Sending write prep transaction…')



            // client must be a WalletClient (has an account + transport + chain)
            const txHash = await client.writeContract({
                address: tokenSaleAddress,
                abi: abi,
                functionName: 'buy',
                value: parseEther('0.001'),
            })

            const tx = await client.getTransaction({ hash: txHash })
            console.log('tx.input:', tx.input)

            const decoded = decodeFunctionData({
                abi,
                data: tx.input,
            })
            console.log('decoded call:', decoded)


            // Optionally wait for the transaction to be mined
            const receipt = await client.waitForTransactionReceipt({hash: txHash})
            console.log('receipt.status: ', receipt.status) // 'success' or 'reverted'
            console.log('receipt.logs: ', receipt.logs) // 'success' or 'reverted'
            console.log('Function call worked in block: ', receipt.blockNumber)

            const transferLogs = parseEventLogs({
                abi: tokenAbi,
                logs: receipt.logs,
                eventName: 'Transfer',
            })

            console.log('Transfer logs:', transferLogs)

            const balanceAfter = await client.readContract({
                address: tokenAddress,
                abi: tokenAbi,
                functionName: 'balanceOf',
                args: [myAddress],
            }) as bigint

            const tokenCode = await client.getBytecode({ address: tokenAddress })
            const saleCode = await client.getBytecode({ address: tokenSaleAddress })
            console.log('tokenCode length:', tokenCode?.length)
            console.log('saleCode length :', saleCode?.length)

            const saleToken = await client.readContract({
                address: tokenSaleAddress,
                abi,
                functionName: 'cappedToken',
            })
            console.log('TokenSale cappedToken address:', saleToken)

            console.log('myAddress:', myAddress)


            const decimals = await client.readContract({
                address: tokenAddress,
                abi: tokenAbi,
                functionName: 'decimals',
            })
            console.log('token decimals:', decimals)

            const totalSupply = await client.readContract({
                address: tokenAddress,
                abi: tokenAbi,
                functionName: 'totalSupply',
            }) as bigint
            console.log('token totalSupply:', totalSupply.toString())

            const saleBalance = await client.readContract({
                address: tokenAddress,
                abi: tokenAbi,
                functionName: 'balanceOf',
                args: [tokenSaleAddress],
            }) as bigint
            console.log('token balanceOf(TokenSale):', saleBalance.toString())

            console.log('raw token balance before (wei-like):', balanceBefore.toString())
            console.log('raw token balance after  (wei-like):', balanceAfter.toString())
            console.log('formatted token balance before:', formatUnits(balanceBefore, 18))
            console.log('formatted token balance after :', formatUnits(balanceAfter, 18))
        } catch (err) {
            console.error('Deployment failed:', err)
        }

    })()
} catch (e) {
    console.error('Failed to load artifact:', e)
}


