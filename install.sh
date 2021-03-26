# Setup script for a new Shadow Instance.
# Warning: Running this script will overwrite any existing secrets & reset the configuration.
# Only run this script for a new instance or if you know what you are doing.

rm -rf resources/
mkdir resources/

# Base file
echo "Creating default base.txt file"
echo "Shadow Messaging Engine" >> resources/base.txt

# Key generation
echo "Generating new keypair"
openssl genrsa -out resources/private.pem 512
openssl rsa -in resources/private.pem -pubout > resources/public.pem

# Verification file
echo "Creating verification file"
openssl dgst -md5 -sign resources/private.pem -out resources/verification.txt resources/base.txt

# Verify verfication process
echo "Confirming process validation"
openssl dgst -md5 -verify resources/public.pem -signature resources/verification.txt resources/base.txt

# Temporary Shadow.Key
echo "Generating initial Shadow.Key"
openssl dgst -md5 resources/private.pem | awk '{print $2}' >> resources/key.txt
