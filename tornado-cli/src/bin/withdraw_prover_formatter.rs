use std::fs::File;
use std::io::{self, BufRead, Write};
use std::path::Path;
use std::time::{SystemTime, UNIX_EPOCH};

fn main() -> io::Result<()> {
    // Paths for input data
    let root_path = Path::new("../data/root.txt");
    let siblings_path = Path::new("../data/proof_siblings.txt");
    let indices_path = Path::new("../data/proof_path_indices.txt");

    let asset_path = Path::new("../data/deposit_asset.txt");
    let liquidity_path = Path::new("../data/deposit_liquidity.txt");
    let timestamp_path = Path::new("../data/deposit_timestamp.txt");

    let nulifier_path = Path::new("../data/nullifier.txt");
    let secret_path = Path::new("../data/secret.txt");

    // Paths for output Prover.toml files
    let withdraw_output_path = Path::new("../circuits/withdraw/Prover.toml");
    let deposit_output_path = Path::new("../circuits/deposit/Prover.toml");

    // Open the output files for writing
    let mut withdraw_file = File::create(&withdraw_output_path)?;
    // let mut deposit_file = File::create(&deposit_output_path)?;

    // Read data from files
    let current_timestamp = get_current_timestamp()?;
    let deposit_timestamp = read_first_line(&timestamp_path)?;
    let deposit_asset = read_first_line(&asset_path)?;
    let deposit_liquidity = read_first_line(&liquidity_path)?;

    let root_value = read_first_line(&root_path)?;
    let secret_value = read_first_line(&secret_path)?;
    let nulifier_value = read_first_line(&nulifier_path)?;
    let nullifier_hash = "0x2a09a9fd93c590c26b91effbb2499f07e8f7aa12e2b4940a3aed2411cb65e11c";

    // Common fields for both Prover.toml files
    let common_fields = |file: &mut File| -> io::Result<()> {
        writeln!(file, "current_timestamp = \"{}\"", current_timestamp)?;
        writeln!(file, "deposit_timestamp = \"{}\"", deposit_timestamp)?;
        writeln!(file, "asset = \"{}\"", deposit_asset)?;
        writeln!(file, "liquidity = \"{}\"", deposit_liquidity)?;
        writeln!(file, "root = \"{}\"", root_value)?;
        writeln!(file, "secret = \"{}\"", secret_value)?;
        writeln!(file, "nullifier = \"{}\"", nulifier_value)?;
        writeln!(file, "nullifier_hash = \"{}\"", nullifier_hash)?;
        writeln!(file, "proof_path_indices = [")?;
        for line in io::BufReader::new(File::open(&indices_path)?).lines() {
            let line = line?;
            writeln!(file, "    {},", line)?;
        }
        writeln!(file, "]")?;
        writeln!(file, "proof_siblings = [")?;
        for line in io::BufReader::new(File::open(&siblings_path)?).lines() {
            let line = line?;
            writeln!(file, "    \"{}\",", line)?;
        }
        writeln!(file, "]")?;

        Ok(())
    };

    // Write to withdraw Prover.toml
    common_fields(&mut withdraw_file)?;
    
    Ok(())
}

// Helper function to read the first line from a file
fn read_first_line(path: &Path) -> io::Result<String> {
    let file = File::open(path)?;
    let mut buf_reader = io::BufReader::new(file);
    let mut line = String::new();
    buf_reader.read_line(&mut line)?;
    Ok(line.trim_end().to_string())
}

// Helper function to get the current timestamp as a string
fn get_current_timestamp() -> io::Result<String> {
    let start = SystemTime::now();
    let since_the_epoch = start.duration_since(UNIX_EPOCH)
        .map_err(|e| io::Error::new(io::ErrorKind::Other, e))?;
    Ok(since_the_epoch.as_secs().to_string())
}
