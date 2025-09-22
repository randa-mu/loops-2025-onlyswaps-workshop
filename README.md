# ONLYswaps hacker house workshop

In this workshop, you're going to build a simple smart contract that will move an ERC20 token, RUSD, from Base Sepolia to AVAX fuji.
It will use the ONLYswaps protocol, built on top of the [dcipher network](https://x.com/dciphernetwork) to execute, fulfil and verify the swap.

## Setup
First, you will need to install the following packages:
- [foundry](https://getfoundry.sh/)

## Build the project
1. Install the dependencies by running:  
   `forge soldeer install --recursive-deps`

2. Ensure the stub project builds by running `forge build`.  
   You can re-run this any time you make changes to ensure they work.

## Preparing your wallet
1. **(Optional but recommended) Create a new wallet**

   Create a new wallet by running `cast wallet new`.  
   The output of the command should look something like this:
    ```
    Successfully created new keypair.
    Address:     0xf4e013c1672C74f80fBec6Eb8e94feD9bF43a868
    Private key: 0x9f72ad68e03668c3f1610b8d6888632e1641183f843ae73287716ed85e048ff5
    ```
> [!NOTE]  
> You can also use an existing Base Sepolia private key if you have one

2. **Prepare your terminal environment**

   For convenience, we're going to export a bunch of variables to our shell so we don't have to copypasta them every time we want to use them.  
   First, copy the [.env.local](./.env.local) to a new file called simply `.env`. This will make sure you don't accidentally commit your private key and leak it to the world.

> [!WARNING]  
> If you skipped the last sentence and didn't copy .env.local to .env, you really might accidentally commit your private key and get pwned.  
> Even smart people make mistakes - don't get lazy!!

   Open the [.env](./.env) you just created and fill in PRIVATE_KEY and MY_ADDRESS using the values from step 1, e.g.  
   `PRIVATE_KEY=0x9f72ad68e03668c3f1610b8d6888632e1641183f843ae73287716ed85e048ff5`.

   We can then load the env vars in our environment by running `source .env.local`.  
   If you're on an exotic shell you might need to do something else - you chose this path!!

> [!NOTE]  
> You're going to re-use this information a few times, so if you open additional terminals you'll need to re-export it.

3. **Get some test ETH for Base Sepolia.**

   Send your wallet address in the Randamu channel in TG and we'll send you some!

4. **Withdraw some test tokens**

   As we're using RUSD, a simulated USD stablecoin, for this workshop, you'll need to withdraw tokens from the faucet. You can do this once per address per 24 hours.

   Withdraw them by running:  
   `cast send $RUSD_ADDRESS "mint()" --private-key $PRIVATE_KEY --rpc-url $BASE_RPC_URL`

   You can check it worked by checking your balance with:  
   `cast call $RUSD_ADDRESS "balanceOf(address)" $MY_ADDRESS --rpc-url $BASE_RPC_URL`

## Integrating ONLYswaps
Okay great, you've completed all the setup! Next, we're going to make a really simple smart contract that requests a swap of the tokens we got from the faucet.

1. **Approve the amount of RUSD that you're going to swap**  
   For UX purposes, you might approve a large amount to avoid needing repeated approvals.

2. **Request a swap**

   Call `requestCrossChainSwap` on the onlyswaps router to actually create an order for the amount required.  
   You will need to pass the amount + the fee as a value, or else it will revert!  
   This emits returns a `requestId` you can use to track the swap.  
   It also emits an event with the requestId for tracking offchain.  
   `requestId`s are deterministic based on the swap parameters, so you can pass all the parameters to the `getSwapRequestId` function to figure it out if you lose it.

3. **Fetch status of the swap**

   There are legs of the transaction happening on each chain, so you have different functions to call depending on whether you're checking on the source or destination chain.  
   For this workshop, we consider Base Sepolia the source chain - it's the source of the original funds.  
   Avalanche Fuji is the destination chain, as it's where the user funds will end up.

   On the source chain, call `getSwapRequestParameters` and check the `executed` flag.  
   If it's true, the swap has been fulfilled and verified successfully!

   On the destination chain, call `getSwapRequestReceipt` and check the `fulfilled` flag.  
   If it's true, the swap has been fulfilled by a solver. You can't tell whether the funds have been released to the solver on the source chain yet.

4. **Check your balance on the destination chain**

   `cast call $RUSD_ADDRESS "balanceOf(address)" $MY_ADDRESS --rpc-url $AVAX_RPC_URL`

   The output will be hex, so you can add a `| cast to-dec` if you'd like to see the decimal value.

5. **Check the solver balance on the source chain**

   Currently Randamu is running the only solver, and its address is `0xeBF1B841eFF6D50d87d4022372Bc1191E781aB68`, so you can run:  
   `cast call $RUSD_ADDRESS "balanceOf(address)" 0xeBF1B841eFF6D50d87d4022372Bc1191E781aB68 --rpc-url $BASE_RPC_URL`

## Reminders to maintainer when versions update
- update the dependency revision in the [foundry.toml](./foundry.toml)
- add new address for:
    - RUSD and Router for each chain in [the helpers](./src/Helpers.sol)
    - the [.env.local](./.env.local) file