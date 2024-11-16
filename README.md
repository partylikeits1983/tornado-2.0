# TORNADO-CASH 2.0: Native EVM Privacy-Preserving Lending Platform
 

Setting up:

1) Install Noir
```
curl -L noirup.dev | bash
noirup
```

2) Install Proving Backend:
```
curl -L bbup.dev | bash
bbup
```

## Full Series of Commands

### 1) Create Deposit proof from /deposit/Prover.toml
```
cd circuits/deposit
nargo execute
bb prove -b ./target/deposit.json -w ./target/deposit.gz -o ./target/proof
bb write_vk -b ./target/deposit.json -o ./target/vk
cd ..
cd ..
cd tornado-cli 
cargo run --package tornado-cli --bin deposit_proof_convert 
cd ..
```

### 2) Compute nullifier hash
```
forge test --match-test test_write_nullifier
```

@DEV WAIT 10 seconds!!!!

### 3) Get IMT root, proof siblings, and path indicies, then format /withdraw/Prover.toml
```
forge test --match-test test_deposit_proof_vault_generate_data

cd tornado-cli
cargo run --package tornado-cli --bin withdraw_prover_formatter
cd ..
```

### 4) Create withdraw proof, convert to hex, run test
```
cd circuits/withdraw
nargo execute
bb prove -b ./target/withdraw.json -w ./target/withdraw.gz -o ./target/proof
bb write_vk -b ./target/withdraw.json -o ./target/vk
cd ..
cd ..

cd tornado-cli
cargo run --package tornado-cli --bin withdraw_proof_convert
cd ..

forge test --match-test test_withdraw_proof 
```



### RUNNING THE FRONTEND:
1) deploy contracts & run anvil
```
anvil --accounts 10 --timestamp $(date +%s) --block-time 5

```
2) in new terminal deploy the vault & verifier contracts:
```
forge script script/Deploy.s.sol --fork-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```