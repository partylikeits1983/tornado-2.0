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



Full deposit command:

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


Full Withdraw command:

```
bb write_vk -b ./target/withdraw.json -o ./target/vk


```