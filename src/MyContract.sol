pragma solidity ^0.8.30;

import {Helpers} from "./Helpers.sol";
import {IRouter} from "../dependencies/onlyswaps-solidity-v0.1.0/src/interfaces/IRouter.sol";
import {ERC20FaucetToken} from "../dependencies/onlyswaps-solidity-v0.1.0/src/mocks/ERC20FaucetToken.sol";

contract MyContract {
    IRouter internal onlyswapsRouter;
    ERC20FaucetToken internal token;

    constructor() {
        onlyswapsRouter = IRouter(Helpers.RUSD_ADDRESS);
        token = ERC20FaucetToken(Helpers.RUSD_ADDRESS);
    }

    function execute() public {
        // you're going to fill in your code here
    }
}
