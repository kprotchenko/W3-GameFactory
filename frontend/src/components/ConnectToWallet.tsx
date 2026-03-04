import {formatUnits, parseEther, getAddress, parseUnits} from "viem";
import tokenSaleArtifact from "../../../contracts/out/TokenSale.sol/TokenSale.json";
import {
    useBalance,
    useConnect,
    useConnection,
    useDisconnect,
    useReadContract,
    useWaitForTransactionReceipt,
    useWriteContract
} from "wagmi";
import tokenArtifact from "../../../contracts/out/CappedToken.sol/CappedToken.json";
import * as React from "react";
const tokenAddress = import.meta.env.VITE_TOKEN as `0x${string}`
const tokenSaleAddress = import.meta.env.VITE_TOKEN_SALE as `0x${string}`
const CHAIN_ID = 31337 as const

function ConnectToWallet(){
    const { address, isConnected } = useConnection()
    const { mutate, connectors } = useConnect()
    const { mutate: disconnect } = useDisconnect()

    // -------------------------
    // Local UI state
    // -------------------------
    const [sellTknAmount, setSellTknAmount] = React.useState<string>("0"); // human-readable tokens (e.g. "1.5")
    const [buyTknForEthAmount, setBuyTknForEthAmount] = React.useState<string>("0"); // ETH amount for buy

    const sellTknAmountAdj = React.useMemo<bigint | null>(() => {
        if (!sellTknAmount) return null; // empty input
        try {
            const v = parseUnits(sellTknAmount, 18);
            return v > 0n ? v : null;
        } catch {
            return null; // invalid input (e.g. "abc", "1..2")
        }
    }, [sellTknAmount]);



    // --- ETH (native) balance ---
    const {
        data: ethBalance,
        refetch: refetchEthBalance,
    } = useBalance({
        address,
        chainId: CHAIN_ID,
    }) // :contentReference[oaicite:3]{index=3}

    // --- ETH (native) balance ---
    const {
        data: ethTokenSaleBalance,
        refetch: refetchEthTokenSaleBalance,
    } = useBalance({
        address: tokenSaleAddress,
        chainId: CHAIN_ID,
    }) // :contentReference[oaicite:3]{index=3}

    // 1) Read token balance + grab refetch function
    const {
        data: tokenBalance,
        refetch: refetchTokenBalance,
    } = useReadContract({
        address: tokenAddress,
        abi: tokenArtifact.abi,
        functionName: "balanceOf",
        args: address ? [address] : undefined,
        // optional, but avoids running before address exists
        query: { enabled: Boolean(address) },
    });
    const {
        data: allowanceData,
        refetch: refetchAllowance
    } = useReadContract({
        address: tokenAddress,
        abi: tokenArtifact.abi,
        functionName: "allowance",
        args: address ? [address, tokenSaleAddress] : undefined,
        chainId: CHAIN_ID,
        query: { enabled: Boolean(address) },
    });
    const allowance = (allowanceData as bigint | undefined) ?? 0n;

    const {
        data: totalTknSupplyData,
        refetch: refetchTknTotalSupply,
    } = useReadContract({
        address: tokenAddress,
        abi: tokenArtifact.abi,
        functionName: "totalSupply",
    });
    const totalTknSupply = (totalTknSupplyData as bigint | undefined) ?? 0n;

    // 2) Buy tx
    const buyTx = useWriteContract();
    const approveTx = useWriteContract();
    const sellTx = useWriteContract();
    const withdrawTokensTx = useWriteContract();
    const withdrawFundsTx = useWriteContract();

    // -------------------------
    // Wait for receipts
    // -------------------------
    const buyReceipt = useWaitForTransactionReceipt({
        hash: buyTx.data,
        chainId: CHAIN_ID,
    });
    const approveReceipt = useWaitForTransactionReceipt({
        hash: approveTx.data,
        chainId: CHAIN_ID,
    });
    const sellReceipt = useWaitForTransactionReceipt({
        hash: sellTx.data,
        chainId: CHAIN_ID,
    });
    const withdrawTokensReceipt = useWaitForTransactionReceipt({
        hash: withdrawTokensTx.data, // wagmi sets this to the tx hash after mutate/mutateAsync
        chainId: CHAIN_ID,
    });
    const withdrawFundsReceipt = useWaitForTransactionReceipt({
        hash: withdrawFundsTx.data, // wagmi sets this to the tx hash after mutate/mutateAsync
        chainId: CHAIN_ID,
    });





    // 4) When mined, refetch balance so UI updates
    React.useEffect(() => {
        if (!buyReceipt.isSuccess) return
        refetchTokenBalance()
        refetchEthBalance()
        refetchEthTokenSaleBalance()
        refetchTknTotalSupply()
    }, [buyReceipt.isSuccess, refetchEthBalance, refetchTokenBalance, refetchEthTokenSaleBalance, refetchTknTotalSupply]);

    React.useEffect(() => {
        if (!approveReceipt.isSuccess) return;
        refetchAllowance();
    }, [approveReceipt.isSuccess, refetchAllowance]);

    // 4) When sold, refetch balance so UI updates
    React.useEffect(() => {
        if (!sellReceipt.isSuccess) return
        refetchTokenBalance()
        refetchEthBalance()
        refetchEthTokenSaleBalance()
        refetchTknTotalSupply()
    }, [sellReceipt.isSuccess, refetchEthBalance, refetchTokenBalance, refetchEthTokenSaleBalance, refetchTknTotalSupply]);

    // 4) When finished, refetch balance so UI updates
    React.useEffect(() => {
        if (!withdrawTokensReceipt.isSuccess) return
        refetchTokenBalance()
        refetchEthBalance()
        refetchEthTokenSaleBalance()
    }, [withdrawTokensReceipt.isSuccess, refetchEthBalance, refetchTokenBalance, refetchEthTokenSaleBalance]);

    React.useEffect(() => {
        if (!withdrawFundsReceipt.isSuccess) return
        refetchTokenBalance()
        refetchEthBalance()
        refetchEthTokenSaleBalance()
    }, [withdrawFundsReceipt.isSuccess, refetchEthBalance, refetchTokenBalance, refetchEthTokenSaleBalance]);

    // ...

    const { data: saleOwner } = useReadContract({
        address: tokenSaleAddress,
        abi: tokenSaleArtifact.abi,
        functionName: 'owner',
        chainId: CHAIN_ID,
        query: { enabled: Boolean(address) },
    })
    const isOwner =
        Boolean(address && saleOwner) &&
        getAddress(address!) === getAddress(saleOwner as `0x${string}`)

    const { data: maxSupply } = useReadContract({
        address: tokenAddress,
        abi: tokenArtifact.abi,
        functionName: 'maxSupply',
        chainId: CHAIN_ID,
        query: { staleTime: Infinity, gcTime: Infinity, refetchOnWindowFocus: false, refetchOnMount: false, refetchOnReconnect: false },
    });

    const handleBuy = async () => {
        try {
            await buyTx.mutateAsync({
                address: tokenSaleAddress,
                abi: tokenSaleArtifact.abi,
                functionName: "buy",
                value: parseEther(buyTknForEthAmount),
                chainId: CHAIN_ID,
            });
        } catch (e) {
            console.error("buy failed", e);
        }
    };

    const handleApprove = async () => {
        if (!address) return;
        if (sellTknAmount == null) return;
        try {
            if (sellTknAmountAdj === null || sellTknAmountAdj === 0n) return;
            await approveTx.mutateAsync({
                address: tokenAddress,
                abi: tokenArtifact.abi,
                functionName: "approve",
                args: [tokenSaleAddress, sellTknAmountAdj],
                chainId: CHAIN_ID,
            });
        } catch (e) {
            console.error("approve failed", e);
        }
    };

    const handleSell = async () => {
        if (!address) return;
        if (sellTknAmount == null) return;
        try {
            if (sellTknAmountAdj === null || sellTknAmountAdj === 0n) return;
            await sellTx.mutateAsync({
                address: tokenSaleAddress,
                abi: tokenSaleArtifact.abi,
                functionName: "sell",
                args: [sellTknAmountAdj],
                chainId: CHAIN_ID,
            });
            setSellTknAmount("0");
        } catch (e) {
            console.error("sell failed", e);
        }
    };

    const handleWithdrawFunds = async () => {
        try {
            await withdrawFundsTx.mutateAsync({
                address: tokenSaleAddress,
                abi: tokenSaleArtifact.abi,
                functionName: "withdrawFunds",
                chainId: CHAIN_ID,
            });
        } catch (e) {
            console.error("withdrawFunds failed", e);
        }
    }

    const handleWithdrawTokens = async () => {
        try {
            await withdrawTokensTx.mutateAsync({
                address: tokenSaleAddress,
                abi: tokenSaleArtifact.abi,
                functionName: "withdrawTokens",
                chainId: CHAIN_ID,
            });
        } catch (e) {
            console.error("withdrawTokens failed", e);
        }
    }


    return (
        <>
            <div>
                {!isConnected ? (
                    connectors.map((c) => (
                        <button key={c.id} onClick={() => mutate({ connector: c })}>
                            Connect ({c.name?c.name:'unknown'}:{c.id?c.id:'unknown'})
                        </button>
                    ))
                ) : (
                    <>
                        <section style={{ marginTop: 16 }}>
                            <label>
                                <button onClick={() => disconnect()} className="btn btn-primary" >Disconnect</button>
                            </label>
                            {" "}Connected Wallet: {address}
                        </section>
                        <section style={{ marginTop: 16 }}>
                            <h3>Buy</h3>
                            <label>
                                ETH to spend on tokens:{" "}
                                <input
                                    id="buyTknForEthAmount-input"
                                    value={buyTknForEthAmount}
                                    onChange={(e) => setBuyTknForEthAmount(e.target.value)}
                                    style={{ width: 120 }}
                                />

                            </label>
                            {" "}
                            <span
                                title={totalTknSupply === maxSupply ? "Max Supply has been reached" : ""}
                                style={{ display: "inline-block" }} // important so the span has a box
                            >
                                <button onClick={handleBuy} disabled={totalTknSupply === maxSupply || buyTx.isPending} className="btn btn-primary"
                                        >
                                    {buyTx.isPending ? 'Buying…' : 'Buy'}
                                </button>
                            </span>
                        </section>'
                        <section style={{ marginTop: 16 }}>
                            <h3>Sell</h3>
                            <label>
                                Tokens amount to sell back:{" "}
                                <input
                                    id="sellTknAmount-input"
                                    value={sellTknAmount}
                                    onChange={(e) => setSellTknAmount(e.target.value)}
                                    style={{ width: 120 }}
                                />
                            </label>
                            {" "}
                            <button onClick={handleApprove}
                                    disabled={approveTx.isPending}
                                    className="btn btn-primary" >
                                {approveTx.isPending ? "Approving…" : "Approve"}
                            </button>
                            {" "}
                            <span
                                title={sellTknAmountAdj === null || sellTknAmountAdj === 0n || allowance === 0n || allowance < sellTknAmountAdj ? "Approval required before selling" : ""}
                                style={{ display: "inline-block" }} // important so the span has a box
                            >
                                <button
                                    className="btn btn-primary"
                                    onClick={handleSell}
                                    disabled={sellTknAmountAdj === null || sellTknAmountAdj === 0n || allowance === 0n || allowance < sellTknAmountAdj || sellTx.isPending}
                                    >
                                    {sellTx.isPending ? 'Selling…' : 'Sell'}
                                </button>
                            </span>
                        </section>
                        <div>
                            <div>title: {sellTknAmountAdj === null || sellTknAmountAdj === 0n || allowance === 0n || allowance < sellTknAmountAdj ? "Approval required before selling" : ""}</div>
                            <div>sellTknAmount : {sellTknAmountAdj}</div>
                            <div>Allowance : {allowance}</div>
                        </div>
                        <section style={{ marginTop: 16 }}>
                            <div>
                                Connected Wallet's ETH balance:{' '}
                                {ethBalance
                                    ? `${formatUnits(ethBalance.value, ethBalance.decimals)} ${ethBalance.symbol}`
                                    : '—'}
                            </div>
                            <div>
                                Connected Wallet's Token balance:{" "}
                                {tokenBalance ? formatUnits(tokenBalance as bigint, 18) : '0'}
                            </div>
                            <div>
                                TokenSale contract's ETH balance:{' '}
                                {ethTokenSaleBalance
                                    ? `${formatUnits(ethTokenSaleBalance.value, ethTokenSaleBalance.decimals)} ${ethTokenSaleBalance.symbol}`
                                    : '—'}
                            </div>
                            <div>
                                CappedToken contract's current totalTknSupply:{' '}
                                {totalTknSupply
                                    ? formatUnits(totalTknSupply as bigint, 18)
                                    : '0'}
                            </div>
                        </section>
                        {isOwner ? (
                            <section>
                                <h3>Owner actions</h3>
                                <button onClick={handleWithdrawFunds} className="btn btn-primary" >Withdraw ETH</button>
                                {" "}
                                <button onClick={handleWithdrawTokens} className="btn btn-primary" >Withdraw tokens</button>
                            </section>
                        ) : (
                            <div style={{ opacity: 0.7 }}>
                                Connected account is not the owner (owner: {String(saleOwner ?? '—')}).
                            </div>
                        )}
                    </>

                )}
            </div>
        </>
    );
}
export default ConnectToWallet;