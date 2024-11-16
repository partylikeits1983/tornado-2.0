use std::fs::File;
use std::io::{self, Read, Write};
use std::path::Path;

fn main() -> io::Result<()> {
    // Number of public inputs (including return values)
    let num_public_inputs = 6; // Change this value as needed
    let public_input_bytes = 32 * num_public_inputs;

    // Read the proof file
    let mut file = File::open("../circuits/withdraw/target/proof")?;
    let mut proof_data = Vec::new();
    file.read_to_end(&mut proof_data)?;

    if proof_data.len() < public_input_bytes {
        eprintln!("Error: Proof file is smaller than expected public input size.");
        std::process::exit(1);
    }

    // Set the path to the data directory relative to main_repo/proof_convert
    let data_dir = Path::new("../data");
    if !data_dir.exists() {
        std::fs::create_dir(data_dir)?;
    }

    // Extract public inputs
    let public_inputs_bytes = &proof_data[..public_input_bytes];

    // Split public inputs into 32-byte chunks
    let public_inputs: Vec<String> = public_inputs_bytes
        .chunks(32)
        .map(|chunk| format!("0x{}", hex::encode(chunk)))
        .collect();

    // Save each input to its respective file
    for (idx, input_hex) in public_inputs.iter().enumerate() {
        let filename = match idx {
            0 => "withdraw_recipient.txt",
            1 => "withdraw_current_timestamp.txt",
            2 => "withdraw_asset.txt",
            3 => "withdraw_liquidity.txt",
            4 => "withdraw_root.txt",
            5 => "withdraw_nullifier_hash.txt",
            _ => {
                eprintln!("Unexpected index {} for public inputs.", idx);
                std::process::exit(1);
            }
        };
        let file_path = data_dir.join(filename);
        let mut file = File::create(file_path)?;
        writeln!(file, "{}", input_hex)?;
    }

    // Extract proof (the rest of the file)
    let proof_bytes = &proof_data[public_input_bytes..];
    let proof_hex = format!("0x{}", hex::encode(proof_bytes));

    // Save the proof to proof.txt
    let proof_file_path = data_dir.join("withdraw_proof.txt");
    let mut proof_file = File::create(proof_file_path)?;
    writeln!(proof_file, "{}", proof_hex)?;

    println!("Public inputs:");
    for (idx, input_hex) in public_inputs.iter().enumerate() {
        println!("Input {}: {}", idx, input_hex);
    }

    println!("\nProof:");
    println!("{}", proof_hex);

    Ok(())
}
