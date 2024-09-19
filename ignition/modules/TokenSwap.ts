import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const TokenSwapModule = buildModule("TokenSwapModule", (m) => {

    const swap = m.contract("TokenSwap");

    return { swap };
});

export default TokenSwapModule;