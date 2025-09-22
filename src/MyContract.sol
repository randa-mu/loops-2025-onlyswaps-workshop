pragma solidity ^0.8.30;

import {IRouter} from "../dependencies/onlyswaps-solidity-v0.1.0/src/interfaces/IRouter.sol";
import {Helpers} from "./Helpers.sol";

contract MyContract {
    IRouter internal onlyswapsRouter;

    constructor() {
        onlyswapsRouter = IRouter(Helpers.RUSD_ADDRESS);
    }
}
