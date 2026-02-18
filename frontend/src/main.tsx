import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { WagmiProvider, createConfig, http } from 'wagmi'
import { injected } from '@wagmi/connectors'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import App from './App'

const queryClient = new QueryClient()

const anvil = {
    id: 31337,
    name: 'Anvil',
    network: 'anvil',
    nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
    rpcUrls: { default: { http: ['http://127.0.0.1:8545'] } },
    testnet: true,
} as const

const config = createConfig({
    chains: [anvil],
    connectors: [injected()],
    transports: {
        [anvil.id]: http('http://127.0.0.1:8545'),
    },
})

createRoot(document.getElementById('root')!).render(
    <StrictMode>
        <QueryClientProvider client={queryClient}>
            <WagmiProvider config={config}>
                <App />
            </WagmiProvider>
        </QueryClientProvider>
    </StrictMode>,
)
