import './App.css'
import Alert from "./components/Alert.tsx";
import Button from "./components/Button.tsx";
import ListGroup from "./components/ListGroup.tsx";

import {formatUnits, parseEther} from 'viem'
import tokenArtifact from '../../contracts/out/CappedToken.sol/CappedToken.json' with { type: "json" };
import tokenSaleArtifact from '../../contracts/out/TokenSale.sol/TokenSale.json' with { type: "json" };
import {useConnect, useDisconnect, useWriteContract, useConnection, useReadContract} from "wagmi";
import { useState } from "react";
// export {
//     /** @deprecated use `UseConnectionParameters` instead */
//         type UseConnectionParameters as UseAccountParameters, type UseConnectionParameters,
//     /** @deprecated use `UseConnectionsReturnType` instead */
//         type UseConnectionReturnType as UseAccountReturnType, type UseConnectionReturnType,
//     /** @deprecated use `useConnection` instead */
//         useConnection as useAccount, useConnection, } from '../hooks/useConnection.js';

const tokenAddress = import.meta.env.VITE_TOKEN as `0x${string}`
const tokenSaleAddress = import.meta.env.VITE_TOKEN_SALE as `0x${string}`

let items = [
    'New York',
    'Los Angeles',
    'Chicago',
    'Toronto',
    'Tokyo'
];
const handleSelect = (item: string) => {
    console.log(item);
}

function App() {

    const { address, isConnected } = useConnection()
    const { mutate, connectors } = useConnect()
    const { mutate: disconnect } = useDisconnect()
    const { mutateAsync, isPending } = useWriteContract()

    const handleBuy = async () => {
        try {
            await mutateAsync({
                address: tokenSaleAddress,
                abi: tokenSaleArtifact.abi,
                functionName: 'buy',
                value: parseEther('0.005'),
                chainId: 31337,
            })
        } catch (e) {
            console.error('buy failed', e)
        }
    }
    const { data: tokenBalance } = useReadContract ({
        address: tokenAddress,
        abi: tokenArtifact.abi,
        functionName: 'balanceOf',
        args: address ? [address] : undefined,
    })
    const [showAlert, setShowAlert] = useState(false)
    return <>

        {showAlert && <div><Alert onClose={() => {
            // handleClose();
            setShowAlert(false);
        }}>Hello <span>World!!!</span></Alert></div>}

        <div><Button
            onClick={ () => {
                // handleClick();
                setShowAlert(true);
            }}
            type="primary">My Button</Button></div>

        <div id="liveAlertPlaceholder"></div>
        <button type="button" className="btn btn-primary" id="liveAlertBtn">Show live alert</button>
        <ListGroup items={items} header="Cities" onSelect={handleSelect}/>

        <div>
            {!isConnected ? (
                connectors.map((c) => (
                    <button key={c.id} onClick={() => mutate({ connector: c })}>
                        Connect ({c.name})
                    </button>
                ))
            ) : (
                <>
                    <p>Connected: {address}</p>
                    <button onClick={() => disconnect()}>Disconnect</button>

                    <button onClick={handleBuy} disabled={isPending}>
                        {isPending ? 'Buying…' : 'Buy 5 CT (0.001 ETH each)'}
                    </button>
                </>
            )}
        </div>

        <div>
            {/* existing UI elements here */}

            {isConnected && (
                <p>
                    Token balance:{" "}
                    {tokenBalance ? formatUnits(tokenBalance as bigint, 18) : '0'}
                </p>
            )}
        </div>
    </>;
}

export default App;
