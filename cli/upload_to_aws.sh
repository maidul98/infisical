#!/bin/bash

# Ensure AWS credentials are set
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "AWS credentials not set. Please set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY"
    exit 1
fi

cd dist

# Function to get architecture from filename
get_arch() {
    local filename="$1"
    if [[ $filename =~ _amd64\. ]]; then
        echo "amd64"
    elif [[ $filename =~ _arm64\. ]]; then
        echo "arm64"
    elif [[ $filename =~ _armv7\. ]]; then
        echo "armv7"
    elif [[ $filename =~ _armv6\. ]]; then
        echo "armv6"
    else
        echo "unknown"
    fi
}

# Function to extract version from filename
get_version() {
    local filename="$1"
    if [[ $filename =~ infisical[_-]([0-9]+\.[0-9]+\.[0-9]+[^_]*) ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo "unknown"
    fi
}

# Get version from first deb package
first_pkg=$(ls *.deb 2>/dev/null | head -n1)
if [ -z "$first_pkg" ]; then
    echo "No .deb packages found"
    exit 1
fi

VERSION=$(get_version "$first_pkg")
if [ "$VERSION" == "unknown" ]; then
    echo "Could not extract version from package files"
    exit 1
fi

echo "Detected version: $VERSION"

# Create repositories for both latest and versioned packages
for repo_type in "latest" "$VERSION"; do
    echo "Creating $repo_type repository..."
    
    # Create repository structure
    mkdir -p "apt-$repo_type/pool/main/i/infisical"
    cp *.deb "apt-$repo_type/pool/main/i/infisical/"
    
    # Create Packages files for each architecture
    cd "apt-$repo_type"
    for pkg in pool/main/i/infisical/*.deb; do
        arch=$(get_arch "$pkg")
        mkdir -p "dists/stable/main/binary-${arch}"
        dpkg-scanpackages --arch ${arch} pool/main/i/infisical > "dists/stable/main/binary-${arch}/Packages"
        gzip -k -f "dists/stable/main/binary-${arch}/Packages"
    done
    
    # Create Release file
    cat > dists/stable/Release << EOF
Origin: Infisical CLI Repository
Label: Infisical CLI
Suite: stable
Codename: stable
Components: main
Description: Infisical CLI Package Repository ($repo_type)
EOF
    
    # Add architecture list to Release file
    echo "Architectures: $(ls dists/stable/main/ | sed 's/binary-//g' | tr '\n' ' ')" >> dists/stable/Release
    
    # Upload to appropriate S3 path
    if [ "$repo_type" == "latest" ]; then
        aws s3 sync . s3://infisical-cli-apt-repo/ --acl public-read
    else
        aws s3 sync . "s3://infisical-cli-apt-repo/versions/$VERSION/" --acl public-read
    fi
    
    cd ..
    rm -rf "apt-$repo_type"
done

# Update versions list
echo "Updating versions list..."
aws s3 cp s3://infisical-cli-apt-repo/versions.txt versions.txt 2>/dev/null || touch versions.txt
echo "$VERSION" >> versions.txt
sort -u -V versions.txt -o versions.txt
aws s3 cp versions.txt s3://infisical-cli-apt-repo/versions.txt --acl public-read

echo "Upload completed successfully"
echo "Version $VERSION is now available in the APT repository"
echo
echo "To use the latest version:"
echo "1. Add the repository:"
echo "   echo \"deb https://infisical-cli-apt-repo.s3.amazonaws.com stable main\" | sudo tee /etc/apt/sources.list.d/infisical.list"
echo
echo "To use a specific version (e.g., $VERSION):"
echo "1. Add the versioned repository:"
echo "   echo \"deb https://infisical-cli-apt-repo.s3.amazonaws.com/versions/$VERSION stable main\" | sudo tee /etc/apt/sources.list.d/infisical-$VERSION.list"
echo
echo "Then:"
echo "2. Update package list:"
echo "   sudo apt-get update"
echo "3. Install Infisical:"
echo "   sudo apt-get install infisical              # latest version"
echo "   sudo apt-get install infisical=$VERSION     # specific version"
