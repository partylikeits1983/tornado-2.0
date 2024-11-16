use dep::std::hash::poseidon;

fn main(secret: Field, nullifier: Field, asset: pub Field, liquidity: pub Field, timestamp: pub Field, leaf: pub Field) {
    let hash_0 = poseidon::bn254::hash_2([secret, nullifier]);
    let hash_1 = poseidon::bn254::hash_2([asset, liquidity]);
    let hash_2 = poseidon::bn254::hash_2([hash_0, hash_1]);
    let _leaf = poseidon::bn254::hash_2([hash_2, timestamp]);

    // assert proposed leaf matches certain constraints
    assert(_leaf == leaf);
}

#[test]
fn test_main() {
    let secret = 123;
    let nullifier = 123;
    let asset = 0;
    let liquidity = 10000000000000000;
    let timestamp = 1731732846; // Sat Nov 16 2024 04:54:06 GMT+0000

    let hash_0 = poseidon::bn254::hash_2([secret, nullifier]);
    let hash_1 = poseidon::bn254::hash_2([asset, liquidity]);
    let hash_2 = poseidon::bn254::hash_2([hash_0, hash_1]);
    let _leaf = poseidon::bn254::hash_2([hash_2, timestamp]);

    println(_leaf);
    
    main(secret, nullifier, asset, liquidity, timestamp, _leaf);
}
