pragma solidity ^0.8.30;

import "../dependencies/onlyswaps-solidity-v0.1.0/src/interfaces/IRouter.sol";
import {ERC20FaucetToken} from "../dependencies/onlyswaps-solidity-v0.1.0/src/mocks/ERC20FaucetToken.sol";
import {Helpers} from "./Helpers.sol";
import {IRouter} from "../dependencies/onlyswaps-solidity-v0.1.0/src/interfaces/IRouter.sol";

contract MyContract {
    IRouter internal onlyswapsRouter;
    ERC20FaucetToken internal token;
    address internal owner;
    bytes32 req;

    // we need to pass the owner as a constructor arg, because by default forge uses deployer contracts
    // on chains that support it, and using `msg.sender` will set the owner to the deployer!
    constructor(address _owner) {
        owner = _owner;
        onlyswapsRouter = IRouter(Helpers.ROUTER_ADDRESS);

        // we mint some of our RUSD tokens so the contract has a balance to trade
        token = ERC20FaucetToken(Helpers.RUSD_ADDRESS);
        token.mint();
    }

    function executeSwap() public {
        require(msg.sender == owner, "only the owner can call execute!");

        // 1. you're going to fill in your code to execute a swap here
        token.approve(Helpers.ROUTER_ADDRESS, 10000 ether);

        req = onlyswapsRouter.requestCrossChainSwap(
            Helpers.RUSD_ADDRESS,
            Helpers.RUSD_ADDRESS,
            10 ether,
            1 ether,
            Helpers.AVAX_CHAIN_ID,
            msg.sender
        );
    }

    function hasFinishedExecuting() public view returns (bool) {
        // 2. you're going to fill in your code to check if it has been verified here

        IRouter.SwapRequestParameters memory params = onlyswapsRouter.getSwapRequestParameters(req);
        return params.executed;
    }
}

