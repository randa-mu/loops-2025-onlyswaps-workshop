# only swaps hacker house workshop

In this workshop, you're going to build a simple smart contract that will move an ERC20 token, RUSD, from Base Sepolia to AVAX fuji.  
It will use the [only swaps protocol](https://dcipher.network/only-swaps), built on top of the [dcipher network](https://x.com/dciphernetwork) to execute, fulfil and verify the swap.

## Setup
First, you will need to install the following packages:
- [foundry](https://getfoundry.sh/)

## Build the project
1. Clone the repository by running:  
   `git clone git@github.com:randa-mu/loops-2025-onlyswaps-workshop.git`

2. Enter the directory by running:  
   `cd loops-2025-onlyswaps-workshop`

3. Install the dependencies by running:  
   `forge soldeer install --recursive-deps`

4. Ensure the stub project builds by running `forge build`.  
   You can re-run this any time you make changes to ensure they work.

## Preparing your wallet
1. **(Optional but recommended) Create a new wallet**

   Create a new wallet by running:  
   `cast wallet new`  

   The output of the command should look something like this:
    ```
    Successfully created new keypair.
    Address:     0xf4e013c1672C74f80fBec6Eb8e94feD9bF43a868
    Private key: 0x9f72ad68e03668c3f1610b8d6888632e1641183f843ae73287716ed85e048ff5
    ```
   Don't clear your terminal as you'll need this output in the next step!
> [!NOTE]  
> You can also use an existing Base Sepolia private key/address if you have them

2. **Prepare your terminal environment**

   For convenience, we're going to export a bunch of variables to our shell so we don't have to copypasta them every time we want to use them.  
   First, copy the contents of [.env.local](./.env.local) to a new file called simply `.env`. This will make sure you don't accidentally commit your private key and leak it to the world.

> [!IMPORTANT]  
> If you skipped the last sentence and didn't copy .env.local to .env, you really might accidentally commit your private key and get pwned.  
> Even smart people make mistakes - don't get lazy!!

   Open the [.env](./.env) you just created and fill in PRIVATE_KEY and MY_ADDRESS using the values from step 1, e.g.  
   `PRIVATE_KEY=0x9f72ad68e03668c3f1610b8d6888632e1641183f843ae73287716ed85e048ff5`.

   We can then load the env vars in our environment by running:  
   `source .env`.  

   If you're on an exotic shell you might need to do something else - you chose this path!!

> [!NOTE]  
> You're going to re-use this information a few times, so if you open additional terminals you'll need to re-export it.

3. **Get some test ETH for Base Sepolia.**

   Send your wallet address in the Randamu channel in TG and we'll send you some! You're going to need it to deploy contracts and interact with them.


## Integrating only swaps
Okay great, you've completed all the setup!  
Next, we're going to make a really simple smart contract that requests a swap of the tokens we got from the faucet.

1. **Take a look around the sample contract**  

   There's a sample contract called [MyContract](./src/MyContract.sol) in the `src` directory.  
   You're going to fill in a few contract calls here during the workshop.  
   There are many possible ways to complete it successfully, so choose your own adventure!

2. **Approve the amount of funds you want to move**  

   As a security feature, ERC20s mandate that you approve funds movements between addresses so sneaky contracts can't unilaterally move your funds.  
   Typically, you'd want to do this in the frontend of an application. Users would be prompted by their wallet to sign an approval transaction before their RUSD funds are moved.  
   For UX purposes, you might approve a large amount to avoid needing repeated approvals and/or use [EIP-7702](https://eip7702.io/) to make this a single signature for your users.  

   For simplicity, the contract mints some RUSD tokens in its constructor, so you just need to approve the router contract to move them.

3. **Implement `executeSwap`**  

   Navigate to the comment labelled `1.`  
   Here you should call [`requestCrossChainSwap`](https://github.com/randa-mu/onlyswaps-solidity/blob/cf80cf7a1944954d2bb65fd33effad49207c9c09/src/interfaces/IRouter.sol#L105-L120) on the onlyswaps router to actually create an order for the amount required.  
   You will need to pass the amount + the fee as a value, or else it will revert!  

   This emits returns a `requestId` you can use to track the swap.  
   It also emits an event with the requestId for tracking offchain.  
   `requestId`s are deterministic based on the swap parameters, so you can pass all the parameters to the [`getSwapRequestId`](https://github.com/randa-mu/onlyswaps-solidity/blob/cf80cf7a1944954d2bb65fd33effad49207c9c09/src/interfaces/IRouter.sol#L163-L166) function to figure it out if you lose it.

4. **Implement `hasFinishedExecuting`**

   Navigate to the comment labelled `2.`
   There are legs of the transaction happening on each chain, so you have different functions to call depending on whether you're checking on the source or destination chain.  
   For this workshop, Base Sepolia going to be our source chain - it's the source of the original funds.  
   Avalanche Fuji is the destination chain, and it's where the user funds will end up.

   On the source chain, [`getSwapRequestParameters`](https://github.com/randa-mu/onlyswaps-solidity/blob/cf80cf7a1944954d2bb65fd33effad49207c9c09/src/interfaces/IRouter.sol#L196-L202) contains all the details related to the swap. Here, we can check the `executed` flag to determine whether a swap has been fulfilled and verified.
   If it's true, the swap has been fulfilled and verified successfully!

   On the destination chain, [`getSwapRequestReceipt`](https://github.com/randa-mu/onlyswaps-solidity/blob/cf80cf7a1944954d2bb65fd33effad49207c9c09/src/interfaces/IRouter.sol#L217-L241) contains details on the fufillment and check the `fulfilled` flag.  
   If it's true, the swap has been fulfilled by a solver. You can't tell whether the funds have been released to the solver on the source chain, because the destination chain doesn't know about the state of the source chain directly!.

   Use these calls to try and implement `hasFinishedExecuting` on the source chain, marked by the comment `2.`.  
   Use `cast` to check the status on the destination chain

> [!NOTE]
> Every router on every chain has both `getSwapRequestParameters` and `getSwapRequestReceipt`, because in some swaps they're the destination chain, and in some swaps they're the source chain.  
> This can be confusing, so make sure you're making the right call on the right chain or you could get the wrong status!

## Deploying and using your new contract

1. **Deploy the contracts to Base**  

   First, let's build the project again by running `forge build`.
   If we see the `Compiler run successful!` message, we're good to deploy.

   We can deploy the contract by running:  
   `forge create src/MyContract.sol:MyContract --rpc-url $BASE_RPC_URL --private-key $PRIVATE_KEY --broadcast --constructor-args $MY_ADDRESS`

> [!WARNING]
> You **must** put --constructor-args as the last argument, or `forge` will ignore all the other args.
> ... don't ask me who decided that

   If it's successful, you should see a message like:
```
   [⠊] Compiling...
No files changed, compilation skipped
Deployer: 0x9a6b5bA82942C89AB9BBf67B561Be922CB99eCF1
Deployed to: 0xD861E981dC0a2F46B2CD0Cc15A3b0A4e90101d82
Transaction hash: 0xb70982ff967374ae63218c1c8cd066b550dde3a9abff8d2a8594295d47e0496b
```

> [!NOTE]
> If you see a message like 
>`Error: server returned an error response: error code -32000: insufficient funds for gas * price + value: balance 0, tx cost 124444016751, overshot 124444016751`
> it means your wallet isn't funded! Go back to [step 3 of preparing your wallet](#preparing-your-wallet))

   Take the value from the `Deployed to: ` line, and export like so:  
   `export CONTRACT_ADDRESS=0xD861E981dC0a2F46B2CD0Cc15A3b0A4e90101d82` 

   Then check for its existence on-chain by running:  
   `cast code $CONTRACT_ADDRESS --rpc-url $BASE_RPC_URL`

   This command should output a big hex value. If it outputs just `0x`, then you've made a mistake somewhere.

2. **Call your contract code**  

   You can do this with the power of `cast` again. Run:  
   `cast send --rpc-url $BASE_RPC_URL --private-key $PRIVATE_KEY  $CONTRACT_ADDRESS "executeSwap()"`

   If you've changed the function signature, you will need to change `"executeSwap()"` to map your new parameters.  

3. **Check the contract's balance on the destination chain**  

   `cast call $RUSD_ADDRESS "balanceOf(address)" $CONTRACT_ADDRESS --rpc-url $AVAX_RPC_URL`

   The output will be hex, so you can add a `| cast to-dec` if you'd like to see the decimal value.

4. **Check the solver balance on the source chain**  

   Currently Randamu is running the only solver, and its address is `0xeBF1B841eFF6D50d87d4022372Bc1191E781aB68`, so you can run:  
   `cast call $RUSD_ADDRESS "balanceOf(address)" 0xeBF1B841eFF6D50d87d4022372Bc1191E781aB68 --rpc-url $BASE_RPC_URL`

   You can also check [basescan](https://sepolia.basescan.org) and see some of the transactions from other participants! 

5. **Try your contract's status code**  

   If you implemented `hasFinishedExecuting` correctly, you should also be able to see when a swap has been executed. Use the following cast call to check your most recent swap:  
   `cast call $CONTRACT_ADDRESS "hasFinishedExecuting()" --rpc-url $BASE_RPC_URL`  

   If you did it correctly, you should see `0x0000000000000000000000000000000000000000000000000000000000000001`.

## Spicier Extensions

If this was all too easy, you could try some of the following:

- Manage multiple request IDs in your contract  

   We discussed request IDs in brief earlier, but it's worth trying out managing and using them for yourself. You may need to import extra structs to use them effectively.

- Set the `recipientAddress` to a contract on the destination chain  

   If you implement the `fallback` function, you might be able to implement spicy logic on token transfers.  
   Honestly, I haven't even tried this so who knows what demons lurk in this! Let the Randamu team know if you do anything spicy with this.

- Run your own solver  

   Anyone can run a solver; Try spinning one up using the docker container or binary in the [solver repo](https://github.com/randa-mu/onlyswaps-solver). 
   See if you can steal some of the swaps from the Randamu solver ;)

## Answers
If you get really stuck, there is an answers branch you can check for one possible solution - run:  
`git checkout answers`.

## Final Thoughts
For frontend applications, you probably want to use [the javascript client](https://github.com/randa-mu/onlyswaps-js) instead. Its functionality is analogous to much of the functionality here, so your  new knowledge should cross over!

## Reminders to maintainer when versions update
- update the dependency revision in the [foundry.toml](./foundry.toml)
- update the remappings.txt with the new dependency revision
- change any import paths to the new version of onlyswaps-solidity
- add new address for:
    - RUSD and Router for each chain in [the helpers](./src/Helpers.sol)
    - the [.env.local](./.env.local) file
