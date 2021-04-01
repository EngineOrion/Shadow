# Setup script for a new Shadow Instance.
# Warning: Running this script will overwrite any existing secrets & reset the configuration.
# Only run this script for a new instance or if you know what you are doing.

echo "Warning: Running this script will delete any local member secrets."
echo "Only run this script for a fresh instance or if you know what you are doing."
echo "Do you want to proceed?"
read var

rm -rf .shadow/
mkdir .shadow/

# Base file
echo "Creating default base.shadow file"
echo "Time is an illusion. Lunchtime doubly so." >> .shadow/base.shadow

# Key generation
echo "Generating new keypair"
openssl genrsa -out .shadow/private.shadow 512
openssl rsa -in .shadow/private.shadow -pubout > .shadow/public.shadow

# Verification file
echo "Creating verification file"
openssl dgst -md5 -sign .shadow/private.shadow -out .shadow/verification.shadow .shadow/base.shadow

# Verify verfication process
echo "Confirming process validation"
openssl dgst -md5 -verify .shadow/public.shadow -signature .shadow/verification.shadow .shadow/base.shadow

# Temporary Shadow.Key
echo "Generating initial Shadow.Key"
openssl dgst -md5 .shadow/private.shadow | awk '{print $2}' >> .shadow/key.shadow
