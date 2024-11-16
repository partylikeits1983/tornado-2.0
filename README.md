# ZK-IMT



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

Generate Circuit Data:
```
forge test 
```

format Prover.toml file
```
cd format_imt_prover
cargo run
```

### Generate Solidity Verifier:

Prove an execution of the Noir program
```
cd circuits/imt
nargo execute
bb prove -b ./target/deposit.json -w ./target/deposit.gz -o ./target/proof
```


Verify the execution proof
```
bb write_vk -b ./target/deposit.json -o ./target/vk
```

Generate Solidity verifier:
```
bb contract
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