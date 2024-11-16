use dep::std::hash::poseidon;

fn main(
    current_timestamp: pub Field,
    deposit_timestamp: Field,
    asset: pub Field,
    liquidity: pub Field,
    root: pub Field,
    secret: Field,
    nullifier: Field,
    nullifier_hash: pub Field,
    proof_siblings: [Field; 32],
    proof_path_indices: [Field; 32],
) {
    // check current_timestamp - 86400 > deposit_timestamp
    let one_day_ago = current_timestamp - 86400;
    let can_withdraw = deposit_timestamp.lt(one_day_ago);
    assert(can_withdraw);

    let hash_0 = poseidon::bn254::hash_2([secret, nullifier]);
    let hash_1 = poseidon::bn254::hash_2([asset, liquidity]);
    let hash_2 = poseidon::bn254::hash_2([hash_0, hash_1]);
    let leaf = poseidon::bn254::hash_2([hash_2, deposit_timestamp]);

    assert(nullifier_hash == poseidon::bn254::hash_1([nullifier]));

    let mut hash: Field = leaf;

    for i in 0..32 {
        if proof_path_indices[i] == 0 {
            let input: [Field; 2] = [hash, proof_siblings[i]];
            hash = poseidon::bn254::hash_2(input);
        } else {
            let input: [Field; 2] = [proof_siblings[i], hash];
            hash = poseidon::bn254::hash_2(input);
        }
    }
    assert(hash == root);
}

#[test]
fn test_main() {
    // Step 1: Set up inputs
    let current_timestamp = 1731728931; // Sat Nov 16 2024 03:48:51 GMT+0000
    let deposit_timestamp = 1731613683; // Thu Nov 14 2024 19:48:03 GMT+0000
    let asset = 0;
    let liquidity = 1000;
    let nullifier = 123456789;
    let secret = 987654321;

    // Step 2: Compute the leaf hash
    let hash_0 = poseidon::bn254::hash_2([secret, nullifier]);
    let hash_1 = poseidon::bn254::hash_2([asset, liquidity]);
    let hash_2 = poseidon::bn254::hash_2([hash_0, hash_1]);
    let leaf = poseidon::bn254::hash_2([hash_2, deposit_timestamp]);

    // Step 3: Compute the nullifier hash
    let nullifier_hash = poseidon::bn254::hash_1([nullifier]);

    // Step 4: Generate Merkle proof (all siblings are zeros)
    let proof_siblings: [Field; 32] = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0,
    ];
    let proof_path_indices: [Field; 32] = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0,
    ]; // All zeros (left child)
    // Step 5: Compute the root hash
    let mut hash = leaf;
    for i in 0..32 {
        if proof_path_indices[i] == 0 {
            // Current node is a left child
            hash = poseidon::bn254::hash_2([hash, proof_siblings[i]]);
        } else {
            // Current node is a right child
            hash = poseidon::bn254::hash_2([proof_siblings[i], hash]);
        }
    }
    let root = hash;

    println(root);
    println(nullifier_hash);
    println(nullifier);
    println(secret);
    println(proof_siblings);
    println(proof_path_indices);

    // Step 6: Invoke the main function
    main(
        current_timestamp,
        deposit_timestamp,
        asset,
        liquidity,
        root,
        nullifier_hash,
        nullifier,
        secret,
        proof_siblings,
        proof_path_indices,
    );
}
