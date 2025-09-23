pragma solidity ^0.8.30;

import {ERC20FaucetToken} from "../dependencies/onlyswaps-solidity-v0.1.0/src/mocks/ERC20FaucetToken.sol";
import {Helpers} from "./Helpers.sol";
import {IRouter} from "../dependencies/onlyswaps-solidity-v0.1.0/src/interfaces/IRouter.sol";

contract MyContract {
    IRouter internal onlyswapsRouter;
    ERC20FaucetToken internal token;
    address internal owner;
    bytes32 requestId;

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

        // first we give the router contract the rights to move some tokens for us
        token.approve(Helpers.ROUTER_ADDRESS, 10000 ether);

        // then we request the swap itself
        requestId = onlyswapsRouter.requestCrossChainSwap(
            // the source and destination token addresses are the same
            Helpers.RUSD_ADDRESS, 
            Helpers.RUSD_ADDRESS,
            // send 10 RUSD
            10 ether,
            // and suggest a fee of 1USD; the minimum fee accepted by the default solver is 0.01RUSD right now
            1 ether, 
            // we're sending it to AVAX
            Helpers.AVAX_CHAIN_ID,
            // I'm sending it to my own address, but you could also send it to the contract with address(this)
            msg.sender
        );
    }

    function hasFinishedExecuting() public view returns (bool) {
        IRouter.SwapRequestParameters memory params = onlyswapsRouter.getSwapRequestParameters(requestId);
        // this will be true once the solver has verified the swap here
        return params.executed;
    }
}

