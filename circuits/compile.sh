# key=12
key=13
output='output'
secret='secret'
tmp='tmp'
inputs='inputs'

mkdir $output
mkdir $secret
mkdir $tmp
mkdir $inputs

###-------------------------- Sender

circuits=''
circuits="${circuits} HashSender"
circuits="${circuits} HashReceiver"
circuits="${circuits} HashApprover"
circuits="${circuits} NumericalData"
circuits="${circuits} TextData"
circuits="${circuits} TextExpiryData"
circuits="${circuits} AlphaNumericalData"
circuits="${circuits} HashPaymentSignature"
circuits="${circuits} Policy"

# Power of Tau
snarkjs powersoftau new bn128 $key $secret/pot${key}_0000.ptau -v
snarkjs powersoftau contribute $secret/pot${key}_0000.ptau $secret/pot${key}_0001.ptau --name="First contribution" -e="$(openssl rand -base64 20)"
snarkjs powersoftau prepare phase2 $secret/pot${key}_0001.ptau $secret/pot${key}_final.ptau
    
for circuit in ${circuits}; do
    echo 'Compiling ' ${circuit}
    # Compile
    circom $circuit.circom --r1cs --wasm --sym -o $output

    # Phase 2
    snarkjs groth16 setup $output/$circuit.r1cs $secret/pot${key}_final.ptau $secret/${circuit}_0000.zkey
    snarkjs zkey contribute $secret/${circuit}_0000.zkey $output/${circuit}_0001.zkey --name="1st Contributor Name" -e="$(openssl rand -base64 20)"
    snarkjs zkey export verificationkey $output/${circuit}_0001.zkey $output/${circuit}_verification_key.json

    # Generate Witness
    node $output/${circuit}_js/generate_witness.js $output/${circuit}_js/$circuit.wasm $inputs/${circuit}_input.json $output/${circuit}_witness.wtns

    # Generate Proof
    snarkjs groth16 prove $output/${circuit}_0001.zkey $output/${circuit}_witness.wtns $tmp/${circuit}_proof.json $tmp/${circuit}_public.json

    # Verify Proof
    snarkjs groth16 verify $output/${circuit}_verification_key.json $tmp/${circuit}_public.json $tmp/${circuit}_proof.json

    # Smart Contract
    snarkjs zkey export solidityverifier $output/${circuit}_0001.zkey ../contracts/circuits/${circuit}Verifier.sol
    # snarkjs generatecall

    # SnarkJS solidity template is very old, bump up the version manually
    sed -i -e 's/pragma solidity \^0.6.11/pragma solidity \^0.8.9/g' ../contracts/circuits/${circuit}Verifier.sol
    rm ../contracts/circuits/${circuit}Verifier.sol-e

    cp $output/${circuit}_0001.zkey ../../app/public/zkp/
    cp $output/${circuit}_js/$circuit.wasm ../../app/public/zkp/
    cp $output/${circuit}_verification_key.json ../../app/public/zkp/

    cp $output/${circuit}_0001.zkey ../../api-azure-functions/zkp/
    cp $output/${circuit}_js/$circuit.wasm ../../api-azure-functions/zkp/
    cp $output/${circuit}_verification_key.json ../../api-azure-functions/zkp/
done